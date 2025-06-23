import 'dart:io';
import 'package:file_manager/Services/recycler_bin.dart';

class FileOperations {
  Future<void> pasteFileToDestination(
    bool isCopy,
    String destination,
    String source, {
    void Function(double progress)? onProgress,
  }) async {
    final name = source.split("/").last;
    final pathName = "$destination/$name";
    final type = FileSystemEntity.typeSync(source);

    if (isCopy) {
      if (type == FileSystemEntityType.file) {
        await _copyFileWithProgress(File(source), File(pathName), onProgress);
      } else {
        final totalSize = await _getTotalSize(Directory(source));
        double copied = 0;
        await _copyFolder(Directory(source), Directory(pathName), (inc) {
          copied += inc;
          onProgress?.call(
            (totalSize == 0) ? 1.0 : (copied / totalSize).clamp(0, 1),
          );
        });
      }
    } else {
      if (type == FileSystemEntityType.file) {
        await File(source).rename(pathName);
        onProgress?.call(1.0);
      } else if (type == FileSystemEntityType.directory) {
        try {
          await Directory(source).rename(pathName);
          onProgress?.call(1.0);
        } catch (e) {
          final totalSize = await _getTotalSize(Directory(source));
          double copied = 0;
          await _copyFolder(Directory(source), Directory(pathName), (inc) {
            copied += inc;
            onProgress?.call(
              (totalSize == 0) ? 1.0 : (copied / totalSize).clamp(0, 1),
            );
          });
          await Directory(source).delete(recursive: true);
        }
      }
    }
    onProgress?.call(1.0);
  }

  Future<int> getEntitySize(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      return await File(path).length();
    } else if (type == FileSystemEntityType.directory) {
      int size = 0;
      await for (var entity in Directory(
        path,
      ).list(recursive: true, followLinks: false)) {
        if (entity is File) size += await entity.length();
      }
      return size;
    }
    return 0;
  }

  Future<void> _copyFileWithProgress(
    File source,
    File dest,
    void Function(double progress)? onProgress,
  ) async {
    final srcLength = await source.length();
    final srcStream = source.openRead();
    final destSink = dest.openWrite();
    int copied = 0;

    await for (final data in srcStream) {
      destSink.add(data);
      copied += data.length;
      onProgress?.call(
        (srcLength == 0) ? 1.0 : (copied / srcLength).clamp(0, 1),
      );
    }
    await destSink.close();
    onProgress?.call(1.0);
  }

  Future<void> _copyFolder(
    Directory source,
    Directory destination,
    void Function(int bytesCopied)? onBytesCopied,
  ) async {
    await destination.create();
    await for (var entity in source.list(recursive: false)) {
      final name = entity.path.split("/").last;
      final pathName = "${destination.path}/$name";
      if (entity is Directory) {
        await _copyFolder(entity, Directory(pathName), onBytesCopied);
      } else if (entity is File) {
        final srcLength = await entity.length();
        await _copyFileWithProgress(entity, File(pathName), (progress) {
          if (progress == 1.0) onBytesCopied?.call(srcLength);
        });
      }
    }
  }

  Future<int> _getTotalSize(Directory dir) async {
    int size = 0;
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  Future<void> deleteOperation(String filePath) async {
    await RecentlyDeletedManager().deleteToTrash(filePath);
  }

  Future<void> deleteMultiple(
      List<String> paths, {
        void Function(double progress)? onProgress,
      }) async {
    final total = paths.length;
    int deleted = 0;
    for (final path in paths) {
      await deleteOperation(path);
      deleted++;
      onProgress?.call(deleted / total);
    }
    onProgress?.call(1.0);
  }

  Future<void> deleteMultiplePermanently(
      List<String> paths, {
        void Function(double progress)? onProgress,
      }) async {
    final total = paths.length;
    int deleted = 0;
    for (final path in paths) {
      await RecentlyDeletedManager().deleteOriginalPath(path);
      deleted++;
      onProgress?.call(deleted / total);
    }
    onProgress?.call(1.0);
  }
}
