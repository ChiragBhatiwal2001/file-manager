import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SortPreferenceDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'sort_preferences.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE sort_preferences(path TEXT PRIMARY KEY, sort_value TEXT)',
        );
      },
      version: 1,
    );
  }

  static Future<void> setSortForPath(String path, String sortValue) async {
    final db = await database;
    await db.insert(
      'sort_preferences',
      {'path': path, 'sort_value': sortValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSortForPath(String path) async {
    final db = await database;
    final result = await db.query(
      'sort_preferences',
      where: 'path = ?',
      whereArgs: [path],
    );
    if (result.isNotEmpty) {
      return result.first['sort_value'] as String;
    }
    return null;
  }

  static Future<void> removeSortForPath(String path) async {
    final db = await database;
    await db.delete(
      'sort_preferences',
      where: 'path = ?',
      whereArgs: [path],
    );
  }
}