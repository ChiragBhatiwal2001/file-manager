import 'dart:io';
import 'package:media_scanner/media_scanner.dart';
import 'package:file_manager/Services/recycler_bin.dart';

class FileOperations {
  Set<String> selectedPath = {};

  Future<void> pasteFileToDestination(
    bool isCopy,
    String destination,
    String source,
  ) async {
    final name = source.split("/").last;
    final pathName = "$destination/$name";

    final type = FileSystemEntity.typeSync(source);

    if (isCopy) {
      if (type == FileSystemEntityType.file) {
        await File(source).copy(pathName);
      } else {
        await _copyFolder(Directory(source), Directory(pathName));
      }
    } else {
      if (type == FileSystemEntityType.file) {
        await File(source).rename(pathName);
      } else if (type == FileSystemEntityType.directory) {
        try {
          await Directory(source).rename(pathName);
        } catch (e) {
          // Fallback for different storage volumes
          await _copyFolder(Directory(source), Directory(pathName));
          await Directory(source).delete(recursive: true);
        }
      }
    }
  }

  Future<void> _copyFolder(Directory source, Directory destination) async {
    await destination.create();
    await for (var entity in source.list(recursive: false)) {
      final name = entity.path.split("/").last;
      final pathName = "${destination.path}/$name";

      if (entity is Directory) {
        await _copyFolder(entity, Directory(pathName));
      } else if (entity is File) {
        await File(pathName).writeAsBytes(await entity.readAsBytes());
      }
    }
  }

  Future<void> deleteOperation(String filePath) async {
    await RecentlyDeletedManager().deleteToTrash(filePath);
  }
}
