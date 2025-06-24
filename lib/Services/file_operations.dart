import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:file_manager/Services/recycler_bin.dart';

class FileOperations {
  Future<void> pasteFileToDestination(
      bool isCopy,
      String destination,
      String source, {
        void Function(double progress)? onProgress,
      }) async {
    final name = p.basename(source);
    final targetPath = p.join(destination, name);
    final type = FileSystemEntity.typeSync(source);

    if (isCopy) {
      if (type == FileSystemEntityType.file) {
        final fileSize = await File(source).length();
        if (fileSize > 500 * 1024 * 1024) {
          await _copyFileInIsolate(source, targetPath, onProgress);

        } else {
          await _copyFileWithProgress(File(source), File(targetPath), onProgress);
        }
      } else if (type == FileSystemEntityType.directory) {
        final totalSize = await _getTotalSize(Directory(source));
        double copied = 0;
        await _copyFolder(
          Directory(source),
          Directory(targetPath),
              (inc) {
            copied += inc;
            onProgress?.call(totalSize == 0 ? 1.0 : (copied / totalSize).clamp(0, 1));
          },
        );
      }
    } else {
      try {
        if (type == FileSystemEntityType.directory) {
          await Directory(source).rename(targetPath);
        } else if (type == FileSystemEntityType.file) {
          await File(source).rename(targetPath);
        }
      } catch (_) {
        await pasteFileToDestination(true, destination, source, onProgress: onProgress);
        if (type == FileSystemEntityType.directory) {
          await Directory(source).delete(recursive: true);
        } else if (type == FileSystemEntityType.file) {
          await File(source).delete();
        }
      }
    }
    onProgress?.call(1.0);
  }

  /// Paste multiple files using isolate (for copy)
  Future<void> pasteMultipleFilesInBackground({
    required List<String> paths,
    required String destination,
    required bool isCopy,
    required void Function(double progress) onProgress,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(_pasteInIsolateEntry, {
      'paths': paths,
      'destination': destination,
      'isCopy': isCopy,
      'sendPort': receivePort.sendPort,
    });

    receivePort.listen((msg) {
      if (msg is double) {
        onProgress(msg);
      } else if (msg == 'done') {
        receivePort.close();
      }
    });
  }

  static void _pasteInIsolateEntry(Map<String, dynamic> args) async {
    final paths = List<String>.from(args['paths']);
    final destination = args['destination'];
    final isCopy = args['isCopy'];
    final sendPort = args['sendPort'] as SendPort;

    int totalBytes = 0;
    final pathSizes = <String, int>{};

    for (var path in paths) {
      final type = FileSystemEntity.typeSync(path);
      final size = type == FileSystemEntityType.file ? File(path).lengthSync() : 0;
      pathSizes[path] = size;
      totalBytes += size;
    }

    int copied = 0;

    for (var path in paths) {
      final name = p.basename(path);
      final target = p.join(destination, name);
      final type = FileSystemEntity.typeSync(path);

      if (isCopy) {
        if (type == FileSystemEntityType.file) {
          final input = File(path).openRead();
          final output = File(target).openWrite();
          await input.listen((chunk) {
            output.add(chunk);
            copied += chunk.length;
            if (totalBytes > 0) {
              sendPort.send((copied / totalBytes).clamp(0, 1));
            }
          }).asFuture();
          await output.close();
        } else if (type == FileSystemEntityType.directory) {
          Directory(target).createSync(recursive: true);
          // Optional: Add recursive folder copy if needed
        }
      } else {
        try {
          if (type == FileSystemEntityType.directory) {
            Directory(path).renameSync(target);
          } else if (type == FileSystemEntityType.file) {
            File(path).renameSync(target);
          }
        } catch (_) {
          final input = File(path).openRead();
          final output = File(target).openWrite();
          await input.pipe(output);
          await File(path).delete();
        }
      }
    }

    sendPort.send(1.0);
    sendPort.send('done');
  }

  Future<void> _copyFileInIsolate(
      String source,
      String destination,
      void Function(double progress)? onProgress,
      ) async {
    final receivePort = ReceivePort();
    await Isolate.spawn<_CopyParams>(
      _copyFileIsolateEntryWithProgress,
      _CopyParams(
        sourcePath: source,
        destinationPath: destination,
        sendPort: receivePort.sendPort,
      ),
    );

    await for (final msg in receivePort) {
      if (msg is double && onProgress != null) {
        onProgress(msg);
      } else if (msg == 'done') {
        receivePort.close();
        break;
      }
    }
  }

  static void _copyFileIsolateEntryWithProgress(_CopyParams params) async {
    final source = File(params.sourcePath);
    final dest = File(params.destinationPath);
    final totalSize = source.lengthSync();

    final input = source.openRead();
    final output = dest.openWrite();

    int copied = 0;

    await input.listen((chunk) {
      output.add(chunk);
      copied += chunk.length;
      params.sendPort.send((copied / totalSize).clamp(0.0, 1.0));
    }).asFuture();

    await output.close();
    params.sendPort.send('done');
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
      onProgress?.call((srcLength == 0) ? 1.0 : (copied / srcLength).clamp(0, 1));
    }

    await destSink.close();
  }

  Future<void> _copyFolder(
      Directory source,
      Directory destination,
      void Function(int bytesCopied)? onBytesCopied,
      ) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);

      if (entity is Directory) {
        await _copyFolder(entity, Directory(targetPath), onBytesCopied);
      } else if (entity is File) {
        final srcLength = await entity.length();
        await _copyFileWithProgress(entity, File(targetPath), (progress) {
          if (progress == 1.0) onBytesCopied?.call(srcLength);
        });
      }
    }
  }

  Future<int> _getTotalSize(Directory dir) async {
    int size = 0;
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) size += await entity.length();
    }
    return size;
  }

  Future<int> getEntitySize(String path) async {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      return await File(path).length();
    } else if (type == FileSystemEntityType.directory) {
      return await _getTotalSize(Directory(path));
    }
    return 0;
  }

  Future<void> deleteOperation(String filePath) async {
    await RecentlyDeletedManager().deleteToTrash(filePath);
  }

  Future<void> deleteMultiple(List<String> paths, {
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

  Future<void> deleteMultiplePermanently(List<String> paths, {
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

class _CopyParams {
  final String sourcePath;
  final String destinationPath;
  final SendPort sendPort;

  _CopyParams({
    required this.sourcePath,
    required this.destinationPath,
    required this.sendPort,
  });
}
