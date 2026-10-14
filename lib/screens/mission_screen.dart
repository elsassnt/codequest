import 'dart:math';
 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
 
import '../engine/interpreter.dart';
import '../models/mission.dart';
import '../services/game_provider.dart';
import '../theme.dart';
import '../widgets/code_controller.dart';
import '../widgets/code_keyboard.dart';
import '../widgets/common.dart';
import 'result_screen.dart';
 
class MissionScreen extends StatefulWidget {
  final Mission mission;
  const MissionScreen({super.key, required this.mission});
 
  @override
  State<MissionScreen> createState() => _MissionScreenState();
}
 
class _MissionScreenState extends State<MissionScreen> {
  late final CodeController _code;
  final _focus = FocusNode();
  late int _px, _py;
  Set<Pt> _collected = {};
  bool _running = false, _sysKb = false, _showKb = true, _cancel = false;
  int _hints = 0;
  List<String> _logs = [];
 
  Mission get m => widget.mission;
 
  @override
  void initState() {
    super.initState();
    _code = CodeController(text: m.starterCode);
    _code.selection = TextSelection.collapsed(offset: _code.text.length);
    _code.addListener(() => setState(() {}));
    _px = m.startX;
    _py = m.startY;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showMaterial();
    });
  }
 
  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }
 
  void _reset() {
    setState(() {
      _px = m.startX;
      _py = m.startY;
      _collected = {};
      _logs = [];
    });
  }
 
  // ───────── dialog ─────────
 
  Future<void> _showMaterial() {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Misi ${m.id}: ${m.title}'),
        content: SingleChildScrollView(
          child: Text(m.material, style: const TextStyle(height: 1.4)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
 
  Future<void> _msg(String title, String body, {String button = 'COBA LAGI'}) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(button))],
      ),
    );
  }
 
  Future<void> _hint() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pakai hint?'),
        content: const Text('Hint akan mengurangi skor misi ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('BATAL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YA')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (_hints < 3) setState(() => _hints++);
    final idx = min(_hints, m.hints.length) - 1;
    await _msg('Hint $_hints', m.hints[idx], button: 'OK');
  }
 
  // ───────── menjalankan kode ─────────
 
  Future<void> _run() async {
    if (_running) return;
    final gm = context.read<GameProvider>();
    _reset();  
    _cancel = false;
    setState(() => _running = true);
    final res = Interpreter(m).run(_code.text);
 
    for (final s in res.steps) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        if (s.type == StepType.move) {
          _px = s.x;
          _py = s.y;
        } else if (s.type == StepType.coin) {
          _collected = {..._collected, Pt(s.x, s.y)};
        }
      });
      if (_cancel) break;
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _logs = res.logs;
    });
    if (_cancel) {
      _cancel = false;
      _reset();
      setState(() => _running = false);
      return;
    }
    if (res.error != null) {
      await _msg('Ada yang salah', res.error!);
      return;
    }
    if (res.finalX != m.finishX || res.finalY != m.finishY) {
      await _msg('Belum sampai', 'Py berhenti di (${res.finalX}, ${res.finalY}). Bawa Py ke bendera finish ya!');
      return;
    }
    final clean = stripComments(_code.text);
    if (m.requiredPattern.isNotEmpty && !RegExp(m.requiredPattern, multiLine: true).hasMatch(clean)) {
      await _msg('Hampir!', m.requiredMessage);
      return;
    }
    final lines = clean.split('\n').where((l) => l.trim().isNotEmpty).length;
    final r = await gm.completeMission(m, lines, _hints);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        mission: m,
        result: r,
        lines: lines,
        hints: _hints,
        next: gm.nextOf(m),
      ),
    ));
  }
 void _stop() => setState(() => _cancel = true);
  // ───────── operasi editor ─────────
 
  TextSelection get _sel => _code.selection.isValid
      ? _code.selection
      : TextSelection.collapsed(offset: _code.text.length);
 
  void _insert(String s) {
    final sel = _sel;
    final text = _code.text.replaceRange(sel.start, sel.end, s);
    _code.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: sel.start + s.length));
  }
 
  void _backspace() {
    final sel = _sel;
    final t = _code.text;
    if (!sel.isCollapsed) {
      _code.value = TextEditingValue(
          text: t.replaceRange(sel.start, sel.end, ''), selection: TextSelection.collapsed(offset: sel.start));
    } else if (sel.start > 0) {
      _code.value = TextEditingValue(
          text: t.replaceRange(sel.start - 1, sel.start, ''),
          selection: TextSelection.collapsed(offset: sel.start - 1));
    }
  }
 
  String _lineBeforeCursor() {
    final start = _sel.start;
    final t = _code.text;
    final ls = start == 0 ? -1 : t.lastIndexOf('\n', start - 1);
    return t.substring(ls + 1, start);
  }
 
  void _enter() {
    final line = _lineBeforeCursor();
    final indent = RegExp(r'^ *').stringMatch(line) ?? '';
    final extra = stripComment(line).trimRight().endsWith(':') ? '    ' : '';
    _insert('\n$indent$extra');
  }
 
  void _template(String tpl) {
    final line = _lineBeforeCursor();
    final indent = RegExp(r'^ *').stringMatch(line) ?? '';
    final body = tpl.split('\n').join('\n$indent');
    _insert(line.trim().isEmpty ? body : '\n$indent$body');
  }
 
  String _token() {
    final sel = _code.selection;
    if (!sel.isValid || !sel.isCollapsed) return '';
    return RegExp(r'[A-Za-z_.]+$').stringMatch(_code.text.substring(0, sel.start)) ?? '';
  }
 
  List<Sug> _suggestions() {
    final t = _token().toLowerCase();
    if (t.isEmpty) return const [];
    return kSuggestions
        .where((s) => s.label.toLowerCase().startsWith(t) && s.label.toLowerCase() != t)
        .take(8)
        .toList();
  }
 
  void _applySuggestion(Sug s) {
    final sel = _sel;
    final tok = _token();
    final start = sel.start - tok.length;
    _code.value = TextEditingValue(
      text: _code.text.replaceRange(start, sel.start, s.insert),
      selection: TextSelection.collapsed(offset: start + s.insert.length),
    );
  }
 
  void _toggleSystemKeyboard() {
    setState(() => _sysKb = !_sysKb);
    _focus.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _focus.requestFocus();
    });
  }
 
  // ───────── UI ─────────
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text('Misi ${m.id}: ${m.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(tooltip: 'Materi', icon: const Icon(Icons.menu_book_rounded), onPressed: _showMaterial),
          IconButton(tooltip: 'Hint', icon: const Icon(Icons.lightbulb_rounded), onPressed: _hint),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(m.description,
                style: const TextStyle(fontSize: 13, color: Colors.white70), textAlign: TextAlign.center),
          ),
          Expanded(flex: 4, child: _grid()),
          Expanded(flex: 4, child: _editor()),
          if (_logs.isNotEmpty)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 54),
              color: Colors.black26,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: SingleChildScrollView(
                child: Text(_logs.map((l) => '> $l').join('\n'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF9DC25A))),
              ),
            ),
          if (_showKb) ...[
            _runBar(),
            // SafeArea: supaya baris keyboard paling bawah tidak tertutup tombol navigasi Android
            Container(
              color: const Color(0xFF070D2E),
              child: SafeArea(
                top: false,
                child: CodeKeyboard(
                  onInsert: _insert,
                  onBackspace: _backspace,
                  onEnter: _enter,
                  onTemplate: _template,
                  suggestions: _suggestions(),
                  onSuggestion: _applySuggestion,
                ),
              ),
            ),
          ] else
            SafeArea(top: false, child: _runBar()),
        ],
      ),
    );
  }
 
  Widget _runBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Reset Py',
            onPressed: _running ? null : _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: _showKb ? 'Sembunyikan keyboard coding' : 'Tampilkan keyboard coding',
            onPressed: () => setState(() => _showKb = !_showKb),
            icon: Icon(_showKb ? Icons.keyboard_hide_rounded : Icons.code_rounded),
          ),
          IconButton(
            tooltip: 'Keyboard bawaan',
            onPressed: _toggleSystemKeyboard,
            icon: Icon(Icons.keyboard_alt_outlined, color: _sysKb ? AppColors.accent : null),
          ),
          const SizedBox(width: 6),
          Expanded(child: GradientButton(label: _running ? (_cancel ? 'MENGHENTIKAN...' : '■  STOP') : '▶  RUN',onTap: _running ? (_cancel ? null : _stop) : _run,)),
        ],
      ),
    );
  }
 
  Widget _editor() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: _code,
        focusNode: _focus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: _sysKb ? TextInputType.multiline : TextInputType.none,
        autocorrect: false,
        enableSuggestions: false,
        cursorColor: AppColors.accent,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14, height: 1.4, color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
          hintText: '# tulis kode Python di sini',
          hintStyle: TextStyle(color: Colors.white24),
        ),
      ),
    );
  }
 
  Widget _grid() {
    return LayoutBuilder(builder: (context, c) {
      final cell = min(c.maxWidth / m.gridW, c.maxHeight / m.gridH);
      return Center(
        child: SizedBox(
          width: cell * m.gridW,
          height: cell * m.gridH,
          child: Stack(
            children: [
              for (var y = 0; y < m.gridH; y++)
                for (var x = 0; x < m.gridW; x++)
                  Positioned(left: x * cell, top: y * cell, width: cell, height: cell, child: _cell(x, y, cell)),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                left: _px * cell,
                top: _py * cell,
                width: cell,
                height: cell,
                child: Padding(
                  padding: EdgeInsets.all(cell * 0.04),
                  child: Image.asset(kMascot, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
 
  Widget _cell(int x, int y, double cell) {
    final p = Pt(x, y);
    Widget? icon;
    if (m.obstacles.contains(p)) {
      icon = Icon(Icons.landscape_rounded, color: const Color(0xFF7A7F99), size: cell * 0.7);
    } else if (x == m.finishX && y == m.finishY) {
      icon = Icon(Icons.flag_rounded, color: const Color(0xFF4ADE80), size: cell * 0.7);
    } else if (m.coins.contains(p) && !_collected.contains(p)) {
      icon = Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: cell * 0.55);
    }
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: (x + y).isEven ? const Color(0xFF111B52) : const Color(0xFF0B1238),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(child: icon),
    );
  }
}
 
