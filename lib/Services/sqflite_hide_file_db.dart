import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HiddenFileDb {
  static Database? _db;

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'hidden_items.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hidden_items (
            path TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  static Future<bool> hidePath(String path) async {
    try {
      final result = await _db?.insert(
        'hidden_items',
        {'path': path},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return result != null && result > 0;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> unhidePath(String path) async {
    try {
      final result = await _db?.delete(
        'hidden_items',
        where: 'path = ?',
        whereArgs: [path],
      );
      return result != null && result > 0;
    } catch (e) {
      return false;
    }
  }


  static Future<List<String>> getHiddenPaths() async {
    final result = await _db?.query('hidden_items');
    return result?.map((e) => e['path'] as String).toList() ?? [];
  }

  static Future<bool> isHidden(String path) async {
    final result = await _db?.query(
      'hidden_items',
      where: 'path = ?',
      whereArgs: [path],
    );
    return result != null && result.isNotEmpty;
  }
}
