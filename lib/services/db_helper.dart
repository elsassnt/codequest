import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../data/mission_seed.dart';
import '../models/mission.dart';

/// SQLite menyimpan data misi (tabel `missions`).
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'codequest.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE missions (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            material TEXT NOT NULL,
            grid_width INTEGER NOT NULL,
            grid_height INTEGER NOT NULL,
            start_x INTEGER NOT NULL,
            start_y INTEGER NOT NULL,
            finish_x INTEGER NOT NULL,
            finish_y INTEGER NOT NULL,
            coins_json TEXT,
            obstacles_json TEXT,
            optimal_lines INTEGER NOT NULL,
            reward_score INTEGER NOT NULL,
            hint TEXT,
            starter_code TEXT,
            required_pattern TEXT,
            required_message TEXT
          )
        ''');
        for (final m in kMissions) {
          await d.insert('missions', m.toMap());
        }
      },
    );
  }

  Future<List<Mission>> getMissions() async {
    final d = await db;
    final rows = await d.query('missions', orderBy: 'id');
    return rows.map(Mission.fromMap).toList();
  }
}
