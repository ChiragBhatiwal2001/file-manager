import 'dart:io';
import 'package:path/path.dart' as p;

Future<String> getUniqueDestinationPath(String originalPath) async {
  final dir = FileSystemEntity.isDirectorySync(originalPath)
      ? Directory(p.dirname(originalPath))
      : Directory(p.dirname(originalPath));
  final baseName = p.basenameWithoutExtension(originalPath);
  final ext = p.extension(originalPath);
  String candidate = originalPath;
  int i = 1;

  while (await File(candidate).exists() ||
      await Directory(candidate).exists()) {
    candidate = p.join(dir.path, '$baseName ($i)$ext');
    i++;
  }

  return candidate;
}
