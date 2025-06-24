import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:isolate';

void pasteWorker(Map args) async {
  final List<String> paths = List<String>.from(args['paths']);
  final String destination = args['destination'];
  final bool isCopy = args['isCopy'];
  final SendPort sendPort = args['sendPort'];

  int total = 0;
  final fileSizes = <String, int>{};
  for (final path in paths) {
    if (FileSystemEntity.isFileSync(path)) {
      int size = File(path).lengthSync();
      fileSizes[path] = size;
      total += size;
    }
  }

  int copied = 0;
  for (final path in paths) {
    final name = p.basename(path);
    final dest = p.join(destination, name);

    if (isCopy) {
      final input = File(path).openRead();
      final output = File(dest).openWrite();
      await input.listen((chunk) {
        output.add(chunk);
        copied += chunk.length;
        double progress = (copied / total).clamp(0, 1);
        sendPort.send(progress);
      }).asFuture();
      await output.close();
    } else {
      try {
        File(path).renameSync(dest);
      } catch (_) {
        await File(path).copy(dest);
        await File(path).delete();
      }
      copied += fileSizes[path] ?? 0;
      double progress = (copied / total).clamp(0, 1);
      sendPort.send(progress);
    }
  }

  sendPort.send(1.0);
  sendPort.send('done');
}
