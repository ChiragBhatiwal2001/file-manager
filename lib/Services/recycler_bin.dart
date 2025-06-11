// recently_deleted_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// A singleton class that manages recently deleted files and folders.
/// It moves them to a hidden trash directory, tracks their metadata,
/// supports restore functionality, and automatically deletes items after 30 days.
class RecentlyDeletedManager {
  static final RecentlyDeletedManager _instance = RecentlyDeletedManager._internal();
  factory RecentlyDeletedManager() => _instance;
  RecentlyDeletedManager._internal();

  // Directory used to store trashed items.
  final Directory trashDir = Directory("/storage/emulated/0/.file_manager_trash");
  // JSON file that tracks metadata of deleted items.
  final File metadataFile = File("/storage/emulated/0/.file_manager_trash/trash_index.json");

  /// Initializes the trash directory and metadata file if they don't exist.
  Future<void> init() async {
    if (!trashDir.existsSync()) trashDir.createSync(recursive: true);
    if (!metadataFile.existsSync()) metadataFile.writeAsStringSync(jsonEncode([]));
  }

  /// Reads the metadata from the index file.
  Future<List<Map<String, dynamic>>> _readMetadata() async {
    final contents = await metadataFile.readAsString();
    return List<Map<String, dynamic>>.from(jsonDecode(contents));
  }

  /// Writes the given metadata to the index file.
  Future<void> _writeMetadata(List<Map<String, dynamic>> data) async {
    await metadataFile.writeAsString(jsonEncode(data));
  }

  /// Moves a file/folder to the trash and records its metadata.
  Future<void> deleteToTrash(String originalPath) async {
    final entity = FileSystemEntity.typeSync(originalPath) == FileSystemEntityType.directory
        ? Directory(originalPath)
        : File(originalPath);

    if (!entity.existsSync()) return;

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

  /// Restores a file/folder from the trash using its saved metadata.
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

  /// Permanently deletes a trashed file/folder and removes its metadata.
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

  /// Automatically deletes files/folders from trash if they are older than 30 days.
  Future<void> autoCleanTrash() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = 30 * 24 * 60 * 60 * 1000; // 30 days in ms

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

  /// Permanently deletes **all** items currently in the trash folder
  /// and clears the metadata index file.
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

    // Clear metadata
    await _writeMetadata([]);
  }

  /// Returns a list of all items currently in the trash.
  Future<List<Map<String, dynamic>>> getDeletedItems() async {
    return await _readMetadata();
  }
}