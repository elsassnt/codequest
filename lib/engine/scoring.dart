/// Skor = 50 (selesai) + 30 (baris <= optimal) + 20 (tanpa hint) - penalti hint.
const _hintPenalty = [0, 5, 15, 30];

int calcScore({required int lines, required int optimal, required int hints}) {
  var s = 50;
  if (lines <= optimal) s += 30;
  if (hints == 0) s += 20;
  s -= _hintPenalty[hints > 3 ? 3 : (hints < 0 ? 0 : hints)];
  return s;
}

int starsFor(int score) => score >= 80 ? 3 : (score >= 60 ? 2 : (score >= 50 ? 1 : 0));
