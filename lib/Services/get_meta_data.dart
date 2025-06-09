import 'dart:io';
import 'dart:math' as Math;
import 'package:path/path.dart' as p;

Future<Map<String, dynamic>> getMetadata(String path) async {
  final entity = FileSystemEntity.typeSync(path);
  final stat = await FileStat.stat(path);
  final isFile = entity == FileSystemEntityType.file;

  // int size = 0;
  // if (isFile) {
  //   size = File(path).lengthSync();
  // } else if (entity == FileSystemEntityType.directory) {
  //   size = _getFolderSize(Directory(path));
  // }

  return {
    'Name': p.basename(path),
    'Path': path,
    'Type': isFile ? p.extension(path) : 'Folder',
    // 'Size': _formatSize(size),
    'Modified': "${stat.modified.day.toString().padLeft(2, '0')} ${_getMonthName(stat.modified.month)}",
    'Is Hidden': p.basename(path).startsWith('.'),
  };
}

String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

// String _formatSize(int bytes) {
//   if (bytes <= 0) return "0 B";
//   const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
//   int i = (bytes != 0) ? (Math.log(bytes) / Math.log(1024)).floor() : 0;
//   return '${(bytes / Math.pow(1024, i)).toStringAsFixed(2)} ${sizes[i]}';
// }

// int _getFolderSize(Directory dir) {
//   int size = 0;
//   try {
//     dir.listSync(recursive: true, followLinks: false).forEach((entity) {
//       if (entity is File) {
//         size += entity.lengthSync();
//       }
//     });
//   } catch (_) {}
//   return size;
// }
