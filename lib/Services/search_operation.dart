import 'dart:io';
import 'dart:isolate';

Future<List<String>> startSearchInIsolate(String rootPath, String query) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_searchEntryPoint, [
    receivePort.sendPort,
    rootPath,
    query,
  ]);
  return await receivePort.first as List<String>;
}

void _searchEntryPoint(List args) async {
  final SendPort sendPort = args[0];
  final String rootPath = args[1];
  final String query = args[2];

  final restrictedPaths = [
    '$rootPath/Android/data',
    '$rootPath/Android/obb',
    '$rootPath/.file_manager_trash',
  ];

  List<String> matchedPaths = [];

  Future<void> traverse(Directory dir) async {
    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        final path = entity.path;
        if (restrictedPaths.any((r) => path.startsWith(r))) continue;

        if (entity is Directory) {
          await traverse(entity);
        }
        final name = path.split('/').last.toLowerCase();
        if (name.contains(query.toLowerCase())) {
          matchedPaths.add(path);
        }
      }
    } catch (_) {}
  }

  await traverse(Directory(rootPath));
  sendPort.send(matchedPaths);
}
