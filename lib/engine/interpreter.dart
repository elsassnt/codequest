import '../models/mission.dart';

/// Pseudo-interpreter Python sederhana (bukan Python asli).
/// Mendukung: komentar, assignment, + - * /, perbandingan, for-range, while,
/// if/else, def (tanpa parameter), print, dan perintah py.*.

enum StepType { move, blocked, coin }

class Step {
  final StepType type;
  final int x, y;
  const Step(this.type, this.x, this.y);
}

class ExecResult {
  final List<Step> steps;
  final List<String> logs;
  final String? error;
  final int finalX, finalY, coins;
  const ExecResult(this.steps, this.logs, this.error, this.finalX, this.finalY, this.coins);
}

/// Hapus komentar (#...) dari satu baris, aman terhadap # di dalam string.
String stripComment(String s) {
  String? q;
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (q != null) {
      if (c == q) q = null;
    } else if (c == '"' || c == "'") {
      q = c;
    } else if (c == '#') {
      return s.substring(0, i);
    }
  }
  return s;
}

String stripComments(String code) => code.split('\n').map(stripComment).join('\n');

class _ExecError implements Exception {
  final String msg;
  _ExecError(this.msg);
}

typedef _Ev = Object Function(_Env env);

class _Env {
  final Map<String, Object> vars = {};
  final Map<String, List<_Stmt>> funcs = {};
  final List<Step> steps = [];
  final List<String> logs = [];
  final Set<Pt> collected = {};
  int px, py;
  int ops = 0, depth = 0;
  _Env(this.px, this.py);
}

class _Stmt {
  final String kind;
  final int line;
  String name = '';
  _Ev? expr;
  List<_Ev> args = const [];
  List<_Stmt> body = const [];
  List<_Stmt> orelse = const [];
  _Stmt(this.kind, this.line);
}

class _Line {
  final int indent, no;
  final String text;
  _Line(this.indent, this.text, this.no);
}

class _P {
  int i = 0;
}

const _maxOps = 5000;
const _maxSteps = 150;
const _pyCmds = {'gerak_kanan', 'gerak_kiri', 'gerak_atas', 'gerak_bawah', 'ambil_koin'};

class Interpreter {
  final Mission mission;
  Interpreter(this.mission);

  ExecResult run(String code) {
    final env = _Env(mission.startX, mission.startY);
    String? error;
    try {
      final prog = _parse(code);
      _execBlock(prog, env);
    } on _ExecError catch (e) {
      error = e.msg;
    }
    return ExecResult(env.steps, env.logs, error, env.px, env.py, env.collected.length);
  }

  // ───────────── PARSER ─────────────

  List<_Stmt> _parse(String code) {
    final lines = <_Line>[];
    final raw = code.replaceAll('\t', '    ').split('\n');
    for (var i = 0; i < raw.length; i++) {
      final t = stripComment(raw[i]);
      if (t.trim().isEmpty) continue;
      lines.add(_Line(t.length - t.trimLeft().length, t.trim(), i + 1));
    }
    final p = _P();
    final out = _block(lines, p, lines.isEmpty ? 0 : lines.first.indent);
    if (p.i < lines.length) {
      throw _ExecError('Baris ${lines[p.i].no}: indentasi tidak sesuai.');
    }
    return out;
  }

  List<_Stmt> _block(List<_Line> ls, _P p, int indent) {
    final out = <_Stmt>[];
    while (p.i < ls.length) {
      final l = ls[p.i];
      if (l.indent < indent) break;
      if (l.indent > indent) {
        throw _ExecError('Baris ${l.no}: indentasi tidak sesuai.');
      }
      p.i++;
      final s = _stmt(l);
      if (l.text.endsWith(':')) {
        if (p.i >= ls.length || ls[p.i].indent <= indent) {
          throw _ExecError('Baris ${l.no}: setelah ":" harus ada baris yang menjorok (indentasi).');
        }
        s.body = _block(ls, p, ls[p.i].indent);
        if (s.kind == 'if' &&
            p.i < ls.length &&
            ls[p.i].indent == indent &&
            RegExp(r'^else\s*:$').hasMatch(ls[p.i].text)) {
          final el = ls[p.i];
          p.i++;
          if (p.i >= ls.length || ls[p.i].indent <= indent) {
            throw _ExecError('Baris ${el.no}: setelah "else:" harus ada baris yang menjorok.');
          }
          s.orelse = _block(ls, p, ls[p.i].indent);
        }
      }
      out.add(s);
    }
    return out;
  }

  _Stmt _stmt(_Line l) {
    final t = l.text;
    final no = l.no;

    var mt = RegExp(r'^for\s+([A-Za-z_]\w*)\s+in\s+range\((.*)\)\s*:$').firstMatch(t);
    if (mt != null) {
      return _Stmt('for', no)
        ..name = mt.group(1)!
        ..expr = _expr(mt.group(2)!, no);
    }
    mt = RegExp(r'^while\s+(.+):$').firstMatch(t);
    if (mt != null) return _Stmt('while', no)..expr = _expr(mt.group(1)!, no);

    mt = RegExp(r'^if\s+(.+):$').firstMatch(t);
    if (mt != null) return _Stmt('if', no)..expr = _expr(mt.group(1)!, no);

    if (RegExp(r'^else\s*:$').hasMatch(t)) {
      throw _ExecError('Baris $no: "else" harus tepat setelah blok if.');
    }
    mt = RegExp(r'^def\s+([A-Za-z_]\w*)\s*\(\s*\)\s*:$').firstMatch(t);
    if (mt != null) return _Stmt('def', no)..name = mt.group(1)!;

    mt = RegExp(r'^print\((.*)\)$').firstMatch(t);
    if (mt != null) return _Stmt('print', no)..args = _args(mt.group(1)!, no);

    mt = RegExp(r'^py\.([A-Za-z_]+)\((.*)\)$').firstMatch(t);
    if (mt != null) {
      final cmd = mt.group(1)!;
      if (!_pyCmds.contains(cmd)) {
        throw _ExecError('Baris $no: perintah py.$cmd() tidak dikenal.');
      }
      return _Stmt('py', no)
        ..name = cmd
        ..args = _args(mt.group(2)!, no);
    }
    mt = RegExp(r'^([A-Za-z_]\w*)\s*=(?!=)\s*(.+)$').firstMatch(t);
    if (mt != null) {
      return _Stmt('assign', no)
        ..name = mt.group(1)!
        ..expr = _expr(mt.group(2)!, no);
    }
    mt = RegExp(r'^([A-Za-z_]\w*)\(\s*\)$').firstMatch(t);
    if (mt != null) return _Stmt('call', no)..name = mt.group(1)!;

    throw _ExecError('Baris $no: perintah tidak dikenal → "$t"');
  }

  _Ev _expr(String s, int no) {
    final p = _Parser(_tokenize(s, no), no);
    final e = p.cmp();
    if (!p.done) throw _ExecError('Baris $no: ekspresi tidak valid dekat "${p.peek}".');
    return e;
  }

  List<_Ev> _args(String s, int no) {
    if (s.trim().isEmpty) return const [];
    final p = _Parser(_tokenize(s, no), no);
    final out = <_Ev>[p.cmp()];
    while (p.peek == ',') {
      p.i++;
      out.add(p.cmp());
    }
    if (!p.done) throw _ExecError('Baris $no: argumen tidak valid dekat "${p.peek}".');
    return out;
  }

  List<String> _tokenize(String s, int no) {
    final re = RegExp(
        r'''\s*(?:(\d+(?:\.\d+)?)|("[^"]*"|'[^']*')|([A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*)|(==|!=|<=|>=|[+\-*/()<>,]))''');
    final toks = <String>[];
    var pos = 0;
    while (pos < s.length) {
      if (s.substring(pos).trim().isEmpty) break;
      final mt = re.matchAsPrefix(s, pos);
      if (mt == null) {
        throw _ExecError('Baris $no: karakter tidak dikenal di "${s.substring(pos).trim()}".');
      }
      toks.add(mt.group(0)!.trim());
      pos = mt.end;
    }
    if (toks.isEmpty) throw _ExecError('Baris $no: ekspresi kosong.');
    return toks;
  }

  // ───────────── EKSEKUSI ─────────────

  void _execBlock(List<_Stmt> b, _Env e) {
    for (final s in b) {
      _exec(s, e);
    }
  }

  void _tick(_Env e, int line) {
    if (++e.ops > _maxOps) {
      throw _ExecError('Baris $line: program berjalan terlalu lama (mungkin loop tak berhingga).');
    }
  }

  void _exec(_Stmt s, _Env e) {
    _tick(e, s.line);
    switch (s.kind) {
      case 'assign':
        e.vars[s.name] = s.expr!(e);
        break;
      case 'print':
        e.logs.add(s.args.map((a) => _fmt(a(e))).join(' '));
        break;
      case 'for':
        final n = _int(s.expr!(e), s.line, 'range()');
        if (n > 1000) throw _ExecError('Baris ${s.line}: angka range() terlalu besar.');
        for (var i = 0; i < n; i++) {
          e.vars[s.name] = i;
          _execBlock(s.body, e);
        }
        break;
      case 'while':
        while (_truthy(s.expr!(e))) {
          _tick(e, s.line);
          _execBlock(s.body, e);
        }
        break;
      case 'if':
        _execBlock(_truthy(s.expr!(e)) ? s.body : s.orelse, e);
        break;
      case 'def':
        e.funcs[s.name] = s.body;
        break;
      case 'call':
        final f = e.funcs[s.name];
        if (f == null) {
          throw _ExecError('Baris ${s.line}: fungsi "${s.name}" belum dibuat dengan def.');
        }
        if (++e.depth > 30) throw _ExecError('Baris ${s.line}: pemanggilan fungsi terlalu dalam.');
        _execBlock(f, e);
        e.depth--;
        break;
      case 'py':
        _py(s, e);
        break;
    }
  }

  void _py(_Stmt s, _Env e) {
    // Koin otomatis terkumpul saat dilewati, jadi ambil_koin() hanya perintah valid tanpa efek.
    if (s.name == 'ambil_koin') return;
    if (s.args.length > 1) {
      throw _ExecError('Baris ${s.line}: py.${s.name}() hanya menerima satu angka.');
    }
    final n = s.args.isEmpty ? 1 : _int(s.args[0](e), s.line, 'jumlah langkah');
    if (n < 0 || n > 100) {
      throw _ExecError('Baris ${s.line}: jumlah langkah harus antara 0 dan 100.');
    }
    final dx = s.name == 'gerak_kanan' ? 1 : (s.name == 'gerak_kiri' ? -1 : 0);
    final dy = s.name == 'gerak_bawah' ? 1 : (s.name == 'gerak_atas' ? -1 : 0);
    for (var i = 0; i < n; i++) {
      final nx = e.px + dx, ny = e.py + dy;
      final p = Pt(nx, ny);
      final outside = nx < 0 || ny < 0 || nx >= mission.gridW || ny >= mission.gridH;
      if (outside || mission.obstacles.contains(p)) {
        e.steps.add(Step(StepType.blocked, e.px, e.py));
        throw _ExecError(outside
            ? 'Baris ${s.line}: Py keluar dari peta, program dihentikan.'
            : 'Baris ${s.line}: Py menabrak batu, program dihentikan.');
      }
      if (e.steps.length >= _maxSteps) {
        throw _ExecError(
            'Baris ${s.line}: Py bergerak terlalu banyak (maks $_maxSteps langkah). Cek lagi perulanganmu.');
      }
      e.px = nx;
      e.py = ny;
      e.steps.add(Step(StepType.move, nx, ny));
      if (mission.coins.contains(p) && e.collected.add(p)) {
        e.steps.add(Step(StepType.coin, nx, ny));
      }
    }
  }

  int _int(Object v, int no, String what) {
    if (v is num && v == v.truncate()) return v.toInt();
    throw _ExecError('Baris $no: $what harus berupa angka bulat.');
  }

  bool _truthy(Object v) => v is bool ? v : (v is num ? v != 0 : (v is String ? v.isNotEmpty : false));

  String _fmt(Object v) => v is bool ? (v ? 'True' : 'False') : '$v';
}

// ───────────── PARSER EKSPRESI ─────────────

class _Parser {
  final List<String> t;
  final int no;
  int i = 0;
  _Parser(this.t, this.no);

  bool get done => i >= t.length;
  String? get peek => done ? null : t[i];

  _Ev cmp() {
    var l = _add();
    while (peek != null && const ['==', '!=', '<', '>', '<=', '>='].contains(peek)) {
      final op = t[i++];
      final r = _add();
      final ll = l;
      l = (e) => _compare(op, ll(e), r(e));
    }
    return l;
  }

  _Ev _add() {
    var l = _mul();
    while (peek == '+' || peek == '-') {
      final op = t[i++];
      final r = _mul();
      final ll = l;
      l = (e) => _arith(op, ll(e), r(e));
    }
    return l;
  }

  _Ev _mul() {
    var l = _unary();
    while (peek == '*' || peek == '/') {
      final op = t[i++];
      final r = _unary();
      final ll = l;
      l = (e) => _arith(op, ll(e), r(e));
    }
    return l;
  }

  _Ev _unary() {
    if (peek == '-') {
      i++;
      final v = _unary();
      return (e) => _arith('-', 0, v(e));
    }
    return _primary();
  }

  _Ev _primary() {
    if (done) throw _ExecError('Baris $no: ekspresi belum lengkap.');
    final tok = t[i++];
    if (RegExp(r'^\d').hasMatch(tok)) {
      final Object v = tok.contains('.') ? double.parse(tok) : int.parse(tok);
      return (e) => v;
    }
    if (tok.startsWith('"') || tok.startsWith("'")) {
      final Object v = tok.substring(1, tok.length - 1);
      return (e) => v;
    }
    if (tok == '(') {
      final v = cmp();
      if (peek != ')') throw _ExecError('Baris $no: kurung ")" belum ditutup.');
      i++;
      return v;
    }
    if (RegExp(r'^[A-Za-z_]').hasMatch(tok)) {
      if (tok == 'True') return (e) => true;
      if (tok == 'False') return (e) => false;
      if (tok == 'py.x') return (e) => e.px;
      if (tok == 'py.y') return (e) => e.py;
      if (tok.contains('.')) throw _ExecError('Baris $no: "$tok" tidak dikenal.');
      return (e) {
        final v = e.vars[tok];
        if (v == null) throw _ExecError('Baris $no: variabel "$tok" belum dibuat.');
        return v;
      };
    }
    throw _ExecError('Baris $no: simbol "$tok" tidak valid di sini.');
  }

  Object _arith(String op, Object a, Object b) {
    if (op == '+' && a is String && b is String) return a + b;
    if (a is! num || b is! num) {
      throw _ExecError('Baris $no: operator "$op" hanya untuk angka.');
    }
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      default:
        if (b == 0) throw _ExecError('Baris $no: tidak bisa membagi dengan nol.');
        return a / b;
    }
  }

  Object _compare(String op, Object a, Object b) {
    if (op == '==') return a == b;
    if (op == '!=') return a != b;
    if (a is num && b is num) {
      switch (op) {
        case '<':
          return a < b;
        case '>':
          return a > b;
        case '<=':
          return a <= b;
        default:
          return a >= b;
      }
    }
    throw _ExecError('Baris $no: "$op" hanya bisa membandingkan angka.');
  }
}
