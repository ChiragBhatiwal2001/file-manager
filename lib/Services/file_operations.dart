import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:file_manager/Services/recycler_bin.dart';

class FileOperations {
  Future<void> pasteMultipleFilesInBackground({
    required List<String> paths,
    required String destination,
    List<String>? resolvedPaths,
    required bool isCopy,
    required void Function(double progress) onProgress,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_multiFileOperationIsolate, {
      'paths': paths,
      'destination': destination,
      'isCopy': isCopy,
      'sendPort': receivePort.sendPort,
      'resolvedPaths': resolvedPaths,
    });

    await for (var msg in receivePort) {
      if (msg is double) {
        onProgress(msg);
      } else if (msg == 'done') {
        receivePort.close();
        break;
      }
    }
  }

  static void _multiFileOperationIsolate(Map<String, dynamic> args) async {
    final paths = List<String>.from(args['paths']);
    final destination = args['destination'] as String;
    final isCopy = args['isCopy'] as bool;
    final sendPort = args['sendPort'] as SendPort;
    final resolvedPaths = args['resolvedPaths'] != null
        ? List<String>.from(args['resolvedPaths'])
        : null;

    int totalBytes = 0;
    final sizes = <String, int>{};
    for (var path in paths) {
      final type = FileSystemEntity.typeSync(path);
      final size = type == FileSystemEntityType.file ? File(path).lengthSync() : 0;
      sizes[path] = size;
      totalBytes += size;
    }

    int copied = 0;
    for (int i = 0; i < paths.length; i++) {
      final source = paths[i];
      final target = resolvedPaths != null
          ? resolvedPaths[i]
          : p.join(destination, p.basename(source));

      await _processEntity(
        source,
        target,
        isCopy,
        SendPortWrapper((bytes) {
          copied += bytes;
          if (totalBytes > 0) {
            sendPort.send((copied / totalBytes).clamp(0.0, 1.0));
          }
        }),
      );
    }

    sendPort.send(1.0);
    sendPort.send('done');
  }

  static Future<void> _processEntity(
      String source,
      String target,
      bool isCopy,
      dynamic sendPort,
      ) async {
    final type = FileSystemEntity.typeSync(source);

    if (type == FileSystemEntityType.file) {
      if (isCopy) {
        final input = File(source).openRead();
        final output = File(target).openWrite();
        final totalSize = File(source).lengthSync();
        int copied = 0;

        await input.listen((chunk) {
          output.add(chunk);
          copied += chunk.length;
          if (sendPort is SendPortWrapper) {
            sendPort.callback(chunk.length);
          } else {
            sendPort.send((copied / totalSize).clamp(0.0, 1.0));
          }
        }).asFuture();
        await output.close();
      } else {
        File(source).renameSync(target);
      }
    } else if (type == FileSystemEntityType.directory) {
      if (isCopy) {
        await Directory(target).create(recursive: true);
        final children = Directory(source).listSync();
        for (final child in children) {
          final name = p.basename(child.path);
          final childTarget = p.join(target, name);
          await _processEntity(child.path, childTarget, isCopy, sendPort);
        }
      } else {
        Directory(source).renameSync(target);
      }
    }
  }

  Future<void> deleteOperation(String filePath) async {
    await RecentlyDeletedManager().deleteToTrash(filePath);
  }

  Future<void> deleteMultiple(List<String> paths, {
    void Function(double progress)? onProgress,
  }) async {
    await _deleteMany(paths, deleteOperation, onProgress);
  }

  Future<void> deleteMultiplePermanently(List<String> paths, {
    void Function(double progress)? onProgress,
  }) async {
    await _deleteMany(paths, RecentlyDeletedManager().deleteOriginalPath, onProgress);
  }

  Future<void> _deleteMany(
      List<String> paths,
      Future<void> Function(String path) deleteFn,
      void Function(double progress)? onProgress,
      ) async {
    final total = paths.length;
    int deleted = 0;

    for (final path in paths) {
      await deleteFn(path);
      deleted++;
      onProgress?.call(deleted / total);
    }

    onProgress?.call(1.0);
  }
}

class SendPortWrapper {
  final void Function(int) callback;
  SendPortWrapper(this.callback);
}
