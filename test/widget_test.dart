// Menguji engine & skor untuk 5 misi (menggantikan widget_test.dart bawaan Flutter).
import 'package:codequest/data/mission_seed.dart';
import 'package:codequest/engine/interpreter.dart';
import 'package:codequest/engine/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const solutions = {
    1: 'langkah = 5\npy.gerak_kanan(langkah)',
    2: 'py.gerak_kanan(2 * 2)\npy.gerak_bawah(6 - 3)',
    3: 'energi = 7\nif energi > 5:\n    py.gerak_atas()\n    py.gerak_kanan(4)\n    py.gerak_bawah()\nelse:\n    py.gerak_kanan(4)',
    4: 'for i in range(4):\n    py.gerak_kanan()\n    py.gerak_bawah()',
    5: 'def tangga():\n    py.gerak_kanan()\n    py.gerak_atas()\n\nfor i in range(4):\n    tangga()',
  };

  solutions.forEach((id, code) {
    test('misi $id bisa diselesaikan', () {
      final m = kMissions.firstWhere((x) => x.id == id);
      final r = Interpreter(m).run(code);
      expect(r.error, isNull);
      expect([r.finalX, r.finalY], [m.finishX, m.finishY]);
      expect(RegExp(m.requiredPattern, multiLine: true).hasMatch(stripComments(code)), isTrue);
    });
  });

  test('loop tak berhingga dihentikan', () {
    final r = Interpreter(kMissions.first).run('while 1 == 1:\n    x = 1');
    expect(r.error, isNotNull);
  });

  test('Py tidak menembus rintangan', () {
    final m = kMissions.firstWhere((x) => x.id == 3);
    final r = Interpreter(m).run('py.gerak_kanan(4)');
    expect([r.finalX, r.finalY], [0, 1]);
  });

  test('skor dan bintang', () {
    expect(calcScore(lines: 2, optimal: 2, hints: 0), 100);
    expect(calcScore(lines: 2, optimal: 2, hints: 1), 75);
    expect(calcScore(lines: 5, optimal: 2, hints: 0), 70);
    expect(calcScore(lines: 2, optimal: 2, hints: 3), 50);
    expect(starsFor(100), 3);
    expect(starsFor(75), 2);
    expect(starsFor(50), 1);
    expect(starsFor(45), 0);
  });
}
