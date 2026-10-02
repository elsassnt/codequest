import 'package:flutter/material.dart';

import '../theme.dart';

class Sug {
  final String label, insert;
  const Sug(this.label, [String? insert]) : insert = insert ?? label;
}

const kSuggestions = <Sug>[
  Sug('py.gerak_kanan()'),
  Sug('py.gerak_kiri()'),
  Sug('py.gerak_atas()'),
  Sug('py.gerak_bawah()'),
  Sug('py.ambil_koin()'),
  Sug('py.x'),
  Sug('py.y'),
  Sug('for i in range(3):'),
  Sug('while '),
  Sug('if '),
  Sug('else:'),
  Sug('def nama():'),
  Sug('print()'),
];

const kTemplates = <String, String>{
  'Loop': 'for i in range(3):\n    py.gerak_kanan()',
  'If-Else': 'if py.x < 3:\n    py.gerak_kanan()\nelse:\n    py.gerak_bawah()',
  'Fungsi': 'def langkah():\n    py.gerak_kanan()\n\nlangkah()',
};

/// Keyboard coding khusus: saran auto-complete, tombol cepat, template, QWERTY, simbol.
class CodeKeyboard extends StatefulWidget {
  final void Function(String) onInsert;
  final VoidCallback onBackspace, onEnter;
  final void Function(String) onTemplate;
  final List<Sug> suggestions;
  final void Function(Sug) onSuggestion;

  const CodeKeyboard({
    super.key,
    required this.onInsert,
    required this.onBackspace,
    required this.onEnter,
    required this.onTemplate,
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  State<CodeKeyboard> createState() => _CodeKeyboardState();
}

class _CodeKeyboardState extends State<CodeKeyboard> {
  bool _sym = false, _shift = false;

  Widget _key(String label, VoidCallback onTap, {int flex = 2, Color? color, IconData? icon}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: color ?? AppColors.key,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: SizedBox(
              height: 38,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 20, color: Colors.white)
                    : Text(label,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _chars(String chars) => chars.split('').map((c) {
        final out = _shift ? c.toUpperCase() : c;
        return _key(out, () {
          widget.onInsert(out);
          if (_shift) setState(() => _shift = false);
        });
      }).toList();

  Widget _chip(String label, VoidCallback onTap, {Color color = AppColors.key}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const quick = {'py.': 'py.', 'for': 'for ', 'if': 'if ', 'def': 'def ', 'print': 'print('};
    final rows = <Widget>[
      // Saran auto-complete
      SizedBox(
        height: 32,
        child: widget.suggestions.isEmpty
            ? const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('Saran kode muncul di sini',
                      style: TextStyle(fontSize: 12, color: Colors.white38)),
                ),
              )
            : ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in widget.suggestions)
                    _chip(s.label, () => widget.onSuggestion(s), color: const Color(0xFF3B2E7A)),
                ],
              ),
      ),
      const SizedBox(height: 4),
      // Tombol cepat + template
      SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final e in quick.entries) _chip(e.key, () => widget.onInsert(e.value)),
            for (final k in kTemplates.keys)
              _chip(k, () => widget.onTemplate(kTemplates[k]!), color: const Color(0xFF0B6E8C)),
          ],
        ),
      ),
      const SizedBox(height: 4),
    ];

    if (!_sym) {
      rows.addAll([
        Row(children: _chars('qwertyuiop')),
        Row(children: [const Spacer(), ..._chars('asdfghjkl'), const Spacer()]),
        Row(children: [
          _key('', () => setState(() => _shift = !_shift),
              flex: 3, icon: Icons.arrow_upward_rounded, color: _shift ? const Color(0xFF3B2E7A) : null),
          ..._chars('zxcvbnm'),
          _key('', widget.onBackspace, flex: 3, icon: Icons.backspace_outlined),
        ]),
      ]);
    } else {
      List<Widget> syms(List<String> l) =>
          l.map((c) => _key(c, () => widget.onInsert(c))).toList();
      rows.addAll([
        Row(children: syms('1234567890'.split(''))),
        Row(children: syms(['(', ')', ':', '.', ',', '=', '"', "'", '#'])),
        Row(children: [
          ...syms(['+', '-', '*', '/', '<', '>', '!', '_']),
          _key('', widget.onBackspace, flex: 3, icon: Icons.backspace_outlined),
        ]),
      ]);
    }

    rows.add(Row(children: [
      _key(_sym ? 'ABC' : '123', () => setState(() => _sym = !_sym), flex: 3),
      _key('Tab', () => widget.onInsert('    '), flex: 3),
      _key('spasi', () => widget.onInsert(' '), flex: 8),
      _key('', widget.onEnter, flex: 3, icon: Icons.keyboard_return_rounded),
    ]));

    return Container(
      color: const Color(0xFF070D2E),
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}
