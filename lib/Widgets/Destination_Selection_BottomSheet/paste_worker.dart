import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;

void pasteWorker(Map args) async {
  final List<String> paths = List<String>.from(args['paths']);
  final String destination = args['destination'];
  final bool isCopy = args['isCopy'];
  final SendPort sendPort = args['sendPort'];

  int total = 0;
  final fileSizes = <String, int>{};

  for (final path in paths) {
    final type = FileSystemEntity.typeSync(path);
    if (type == FileSystemEntityType.file) {
      int size = File(path).lengthSync();
      fileSizes[path] = size;
      total += size;
    } else if (type == FileSystemEntityType.directory) {
      total += _getFolderSizeSync(Directory(path));
    }
  }

  int copied = 0;

  for (final path in paths) {
    final name = p.basename(path);
    String dest = p.join(destination, name);
    dest = _getUniqueDestinationPathSync(dest);

    final type = FileSystemEntity.typeSync(path);

    if (type == FileSystemEntityType.directory) {
      await _copyFolderSync(Directory(path), Directory(dest), isCopy, (bytes) {
        copied += bytes;
        sendPort.send((copied / total).clamp(0.0, 1.0));
      });
    } else if (type == FileSystemEntityType.file) {
      final input = File(path).openRead();
      final output = File(dest).openWrite();
      await input.listen((chunk) {
        output.add(chunk);
        copied += chunk.length;
        sendPort.send((copied / total).clamp(0.0, 1.0));
      }).asFuture();
      await output.close();

      if (!isCopy) {
        await File(path).delete();
      }
    }
  }

  sendPort.send(1.0);
  sendPort.send('done');
}

Future<void> _copyFolderSync(
    Directory source,
    Directory destination,
    bool isCopy,
    void Function(int) onBytesCopied,
    ) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    final newPath = p.join(destination.path, p.basename(entity.path));
    final type = FileSystemEntity.typeSync(entity.path);

    if (type == FileSystemEntityType.directory) {
      await _copyFolderSync(Directory(entity.path), Directory(newPath), isCopy, onBytesCopied);
    } else if (type == FileSystemEntityType.file) {
      final srcFile = File(entity.path);
      final destFile = File(newPath);
      final input = srcFile.openRead();
      final output = destFile.openWrite();
      final total = srcFile.lengthSync();

      await input.listen((chunk) {
        output.add(chunk);
        onBytesCopied(chunk.length);
      }).asFuture();
      await output.close();

      if (!isCopy) await srcFile.delete();
    }
  }

  if (!isCopy) await source.delete(recursive: true);
}

int _getFolderSizeSync(Directory dir) {
  int size = 0;
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      size += entity.lengthSync();
    }
  }
  return size;
}

String _getUniqueDestinationPathSync(String originalPath) {
  final dir = p.dirname(originalPath);
  final base = p.basenameWithoutExtension(originalPath);
  final ext = p.extension(originalPath);

  String candidate = originalPath;
  int i = 1;

  while (File(candidate).existsSync() || Directory(candidate).existsSync()) {
    candidate = p.join(dir, '$base ($i)$ext');
    i++;
  }

  return candidate;
}
