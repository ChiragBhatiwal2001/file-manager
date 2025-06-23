import 'dart:io';
import 'dart:math' as Math;
import 'package:path/path.dart' as p;

Future<Map<String, dynamic>> getMetadata(String path) async {
  final entity = FileSystemEntity.typeSync(path);
  final stat = await FileStat.stat(path);
  final isFile = entity == FileSystemEntityType.file;

  int size = 0;
  if (isFile) {
    size = await File(path).length();
  } else if (entity == FileSystemEntityType.directory) {
    size = await _getFolderSizeAsync(Directory(path));
  }

  return {
    'Name': p.basename(path),
    'Path': path,
    'Type': isFile ? p.extension(path) : 'Folder',
    'Size': _formatSize(size),
    'Modified':
    "${stat.modified.day.toString().padLeft(2, '0')} ${_getMonthName(stat.modified.month)} ${stat.modified.year}",
    'Is Hidden': p.basename(path).startsWith('.'),
  };
}

Future<int> _getFolderSizeAsync(Directory dir) async {
  int size = 0;
  try {
    await for (FileSystemEntity entity
    in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
  } catch (_) {}
  return size;
}

String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[month - 1];
}

String _formatSize(int bytes) {
  if (bytes <= 0) return "0 B";
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = (bytes != 0) ? (Math.log(bytes) / Math.log(1024)).floor() : 0;
  return '${(bytes / Math.pow(1024, i)).toStringAsFixed(2)} ${sizes[i]}';
}
