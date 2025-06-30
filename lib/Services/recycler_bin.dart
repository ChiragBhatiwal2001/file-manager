import 'dart:convert';
import 'dart:io';
import 'package:file_manager/Utils/constant.dart';
import 'package:path/path.dart' as p;

class RecentlyDeletedManager {
  static final RecentlyDeletedManager _instance = RecentlyDeletedManager._internal();
  factory RecentlyDeletedManager() => _instance;
  RecentlyDeletedManager._internal();

  Directory get trashDir {
    final path = Constant.internalPath;
    if (path == null) throw Exception("Constant.internalPath is not set!");
    return Directory("$path/.file_manager_trash");
  }

  File get metadataFile {
    final path = Constant.internalPath;
    if (path == null) throw Exception("Constant.internalPath is not set!");
    return File("$path/.file_manager_trash/trash_index.json");
  }

  Future<void> init() async {
    if (!trashDir.existsSync()) trashDir.createSync(recursive: true);
    if (!metadataFile.existsSync()) metadataFile.writeAsStringSync(jsonEncode([]));
  }
  Future<List<Map<String, dynamic>>> _readMetadata() async {
    final contents = await metadataFile.readAsString();
    return List<Map<String, dynamic>>.from(jsonDecode(contents));
  }

  Future<void> _writeMetadata(List<Map<String, dynamic>> data) async {
    await metadataFile.writeAsString(jsonEncode(data));
  }

  Future<void> deleteToTrash(String originalPath) async {
    final entity = FileSystemEntity.typeSync(originalPath) == FileSystemEntityType.directory
        ? Directory(originalPath)
        : File(originalPath);

    if (!entity.existsSync()) return;
    print(trashDir.path.toString());
    final fileName = p.basename(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final trashedPath = p.join(trashDir.path, "${timestamp}_$fileName");

    await entity.rename(trashedPath);

    final metadata = await _readMetadata();
    metadata.add({
      'originalPath': originalPath,
      'trashedPath': trashedPath,
      'deletedAt': timestamp
    });
    await _writeMetadata(metadata);
  }

  Future<void> restoreFromTrash(String trashedPath) async {
    final metadata = await _readMetadata();
    final index = metadata.indexWhere((e) => e['trashedPath'] == trashedPath);

    if (index == -1) return;

    final entry = metadata[index];
    final file = FileSystemEntity.typeSync(trashedPath) == FileSystemEntityType.directory
        ? Directory(trashedPath)
        : File(trashedPath);
    await file.rename(entry['originalPath']);
    metadata.removeAt(index);
    await _writeMetadata(metadata);
  }

  Future<void> permanentlyDelete(String trashedPath) async {
    final metadata = await _readMetadata();
    final index = metadata.indexWhere((e) => e['trashedPath'] == trashedPath);
    if (index == -1) return;

    final file = FileSystemEntity.typeSync(trashedPath) == FileSystemEntityType.directory
        ? Directory(trashedPath)
        : File(trashedPath);

    if (file.existsSync()) await file.delete(recursive: true);
    metadata.removeAt(index);
    await _writeMetadata(metadata);
  }

  Future<void> deleteOriginalPath(String path) async {
    final type = FileSystemEntity.typeSync(path);

    try {
      if (type == FileSystemEntityType.directory) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      } else if (type == FileSystemEntityType.file) {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      } else {
        return;
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<void> autoCleanTrash() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = 30 * 24 * 60 * 60 * 1000;

    final metadata = await _readMetadata();
    final toRemove = metadata.where((e) => now - e['deletedAt'] > threshold).toList();

    for (final item in toRemove) {
      final file = FileSystemEntity.typeSync(item['trashedPath']) == FileSystemEntityType.directory
          ? Directory(item['trashedPath'])
          : File(item['trashedPath']);
      if (file.existsSync()) await file.delete(recursive: true);
      metadata.remove(item);
    }

    await _writeMetadata(metadata);
  }
  Future<void> deleteAll() async {
    final metadata = await _readMetadata();

    for (final item in metadata) {
      final trashedPath = item['trashedPath'];
      final fileType = FileSystemEntity.typeSync(trashedPath);

      if (fileType == FileSystemEntityType.directory) {
        final dir = Directory(trashedPath);
        if (dir.existsSync()) await dir.delete(recursive: true);
      } else if (fileType == FileSystemEntityType.file) {
        final file = File(trashedPath);
        if (file.existsSync()) await file.delete();
      }
    }

    // Clear metadata --> fresh file.
    await _writeMetadata([]);
  }

  Future<List<Map<String, dynamic>>> getDeletedItems() async {
    return await _readMetadata();
  }
}