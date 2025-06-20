import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class FavoritesDB {
  static final FavoritesDB _instance = FavoritesDB._internal();

  factory FavoritesDB() => _instance;
  static Database? _database;

  FavoritesDB._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
    CREATE TABLE favorites (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT UNIQUE NOT NULL,
      isFolder INTEGER NOT NULL,
      orderIndex INTEGER NOT NULL
    )
  ''');
      },
    );
  }

  Future<void> addFavorite(String path, bool isFolder) async {
    final db = await database;

    final result = await db.rawQuery('SELECT MIN(orderIndex) as minOrder FROM favorites');
    final minOrder = result.first['minOrder'] as int? ?? 0;

    await db.insert('favorites', {
      'path': path,
      'isFolder': isFolder ? 1 : 0,
      'orderIndex': minOrder - 1, // Insert on top
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }


  Future<void> removeFavorite(String path) async {
    final db = await database;
    await db.delete('favorites', where: 'path = ?', whereArgs: [path]);
  }

  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await database;
    return await db.query('favorites');
  }

  Future<void> updateFavoritesOrder(List<String> orderedPaths) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < orderedPaths.length; i++) {
      batch.update(
        'favorites',
        {'orderIndex': i},
        where: 'path = ?',
        whereArgs: [orderedPaths[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getFavoritesOrdered() async {
    final db = await database;
    final result = await db.query('favorites', orderBy: 'orderIndex ASC');
    return result.map((row) => row['path'] as String).toList();
  }

  Future<bool> isFavorite(String path) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'path = ?',
      whereArgs: [path],
    );
    return result.isNotEmpty;
  }

  Future<void> clearFavorites() async {
    final db = await database;
    await db.delete('favorites');
  }
}
