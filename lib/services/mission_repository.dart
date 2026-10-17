import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mission_seed.dart';
import '../models/mission.dart';

/// Satu-satunya pintu pengambilan misi.
/// Urutan: misi dari cloud (tersimpan di HP) -> kalau belum ada, misi bawaan
/// di data/mission_seed.dart. App tetap jalan tanpa internet.
class MissionRepository {
  /// Isi dengan alamat Firebase Realtime Database + "missions.json"
  /// (lihat PANDUAN_CLOUD.md). Dikosongkan = mode offline murni.
  static const cloudUrl = 'https://codequest-byels-default-rtdb.firebaseio.com/missions.json';

  static const _cacheKey = 'cloud_missions';

  bool get cloudEnabled => cloudUrl.startsWith('https://');

  /// Cepat dan tanpa internet: cache cloud terakhir, atau misi bawaan.
  Future<List<Mission>> loadLocal() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_cacheKey);
      if (raw != null) {
        final list = _parse(jsonDecode(raw));
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return kMissions;
  }

  /// Ambil dari cloud. Hasil null = tidak ada internet / data tidak valid,
  /// jadi data yang rusak tidak akan pernah menggantikan misi yang sudah ada.
  Future<List<Mission>?> fetchCloud() async {
    if (!cloudEnabled) return null;
    try {
      final res = await http
          .get(Uri.parse(cloudUrl))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = _parse(data);
      if (list.isEmpty) return null;
      final p = await SharedPreferences.getInstance();
      await p.setString(_cacheKey, jsonEncode(data));
      return list;
    } catch (_) {
      return null;
    }
  }

  List<Mission> _parse(dynamic data) {
    final out = <Mission>[];
    for (final e in asList(data)) {
      if (e is Map) out.add(Mission.fromJson(Map<String, dynamic>.from(e)));
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }
}