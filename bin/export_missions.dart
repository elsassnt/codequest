import 'dart:convert';
import 'dart:io';

import 'package:codequest/data/mission_seed.dart';

/// Membuat missions.json dari mission_seed.dart untuk diunggah ke cloud.
/// Jalankan:  dart run bin/export_missions.dart
void main() {
  final data = {'missions': kMissions.map((m) => m.toJson()).toList()};
  File('missions.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  print('missions.json dibuat (${kMissions.length} misi)');
}
