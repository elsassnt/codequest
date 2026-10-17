import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/scoring.dart';
import '../models/mission.dart';
import 'mission_repository.dart';

enum MissionStatus { locked, open, done }

class MissionResult {
  final int score, stars;
  const MissionResult(this.score, this.stars);
}

/// State global: daftar misi (cloud + cadangan data/mission_seed.dart) + progres pemain (SharedPreferences).
class GameProvider extends ChangeNotifier {
  List<Mission> missions = [];
  final Map<int, MissionResult> results = {};
  final Map<String, int> hintUsed = {};
  int currentLevel = 1;
  bool onboarded = false;
  bool loaded = false;
  SharedPreferences? _p;
  final _repo = MissionRepository();

  int get totalScore => results.values.fold(0, (a, r) => a + r.score);
  int get totalStars => results.values.fold(0, (a, r) => a + r.stars);
  int get completedCount => results.length;

  Future<void> load() async {
    final p = _p = await SharedPreferences.getInstance();
    missions = await _repo.loadLocal(); // cache cloud, atau misi bawaan
    currentLevel = p.getInt('current_level') ?? 1;
    onboarded = p.getBool('onboarded') ?? false;
    final raw = p.getString('mission_scores');
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        results[int.parse(k)] = MissionResult(v['score'] as int, v['stars'] as int);
      });
    }
    final hu = p.getString('hint_used');
    if (hu != null) {
      (jsonDecode(hu) as Map<String, dynamic>).forEach((k, v) => hintUsed[k] = v as int);
    }
    loaded = true;
    notifyListeners();
    _refreshCloud(); // di latar belakang, tidak menghambat app dibuka
  }

  /// Cek misi baru di cloud. Gagal / offline = diam saja.
  Future<void> _refreshCloud() async {
    final fresh = await _repo.fetchCloud();
    if (fresh == null) return;
    String sig(List<Mission> l) => jsonEncode(l.map((m) => m.toJson()).toList());
    if (sig(fresh) == sig(missions)) return;
    missions = fresh;
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    onboarded = true;
    await _p?.setBool('onboarded', true);
  }

  MissionStatus statusOf(Mission m) {
    if (m.id > currentLevel) return MissionStatus.locked;
    return results.containsKey(m.id) ? MissionStatus.done : MissionStatus.open;
  }

  Mission? nextOf(Mission m) {
    for (final x in missions) {
      if (x.id == m.id + 1) return x;
    }
    return null;
  }

  /// Hitung skor, simpan skor terbaik, buka misi berikutnya.
  Future<MissionResult> completeMission(Mission m, int lines, int hints) async {
    final score = calcScore(lines: lines, optimal: m.optimalLines, hints: hints);
    final r = MissionResult(score, starsFor(score));
    final old = results[m.id];
    if (old == null || r.score > old.score) results[m.id] = r;
    if (m.id == currentLevel && m.id < missions.length) currentLevel = m.id + 1;
    hintUsed[m.id.toString()] = hints;
    await _save();
    notifyListeners();
    return r;
  }

  Future<void> _save() async {
    final p = _p;
    if (p == null) return;
    await p.setInt('total_score', totalScore);
    await p.setInt('total_stars', totalStars);
    await p.setInt('current_level', currentLevel);
    await p.setString('completed_missions', jsonEncode(results.keys.toList()..sort()));
    await p.setString('hint_used', jsonEncode(hintUsed));
    await p.setString(
      'mission_scores',
      jsonEncode(results.map((k, v) => MapEntry(k.toString(), {'score': v.score, 'stars': v.stars}))),
    );
  }
}