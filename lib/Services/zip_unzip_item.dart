import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

Future<void> zipUsingArchive({
  required String inputPath,
  required String outputZipPath,
  void Function(double)? onProgress,
}) async {
  final archive = Archive();
  final inputType = FileSystemEntity.typeSync(inputPath);
  final baseName = p.basename(inputPath);
  int total = 0;
  int done = 0;

  if (inputType == FileSystemEntityType.file) {
    final file = File(inputPath);
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(baseName, bytes.length, bytes));
    done += bytes.length;
    onProgress?.call(1.0);
  } else if (inputType == FileSystemEntityType.directory) {
    final files = Directory(inputPath).listSync(recursive: true);
    total = files.whereType<File>().fold(0, (sum, f) => sum + f.lengthSync());

    for (final entity in files) {
      final relPath = p.relative(entity.path, from: inputPath).replaceAll('\\', '/');
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile('$baseName/$relPath', bytes.length, bytes));
        done += bytes.length;
        onProgress?.call((done / total).clamp(0.0, 1.0));
      } else if (entity is Directory) {
        archive.addFile(ArchiveFile('$baseName/$relPath/', 0, []));
      }
    }
  }

  final zipBytes = ZipEncoder().encode(archive);
  final outFile = File(outputZipPath);
  await outFile.create(recursive: true);
  await outFile.writeAsBytes(zipBytes!);
}

Future<void> unzipFileUsingArchive({
  required String zipPath,
  required String outputDirectory,
  void Function(double)? onProgress,
}) async {
  final zipBytes = await File(zipPath).readAsBytes();
  final archive = ZipDecoder().decodeBytes(zipBytes);

  int total = archive.length;
  int done = 0;

  for (final file in archive) {
    final filePath = p.join(outputDirectory, file.name);
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    } else {
      final dir = Directory(filePath);
      if (!await dir.exists()) await dir.create(recursive: true);
    }

    done++;
    onProgress?.call(done / total);
  }
}
