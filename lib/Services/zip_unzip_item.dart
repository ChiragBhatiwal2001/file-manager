import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

Future<void> zipFolderCorrectly(String sourcePath, String zipPath) async {
  final archive = Archive();

  final sourceDir = Directory(sourcePath);

  if (!await sourceDir.exists()) {
    print("❌ Source folder doesn't exist.");
    return;
  }

  for (final entity in sourceDir.listSync(recursive: true)) {
    if (entity is File) {
      final relativePath = entity.path.replaceFirst(sourcePath, '').replaceAll('\\', '/');

      final fileBytes = await entity.readAsBytes();

      final archiveFile = ArchiveFile(relativePath, fileBytes.length, fileBytes);
      archive.addFile(archiveFile);
    } else if (entity is Directory) {
      final relativePath = entity.path.replaceFirst(sourcePath, '').replaceAll('\\', '/');
      final archiveFile = ArchiveFile.noCompress('$relativePath/', 0, []);
      archive.addFile(archiveFile);
    }
  }

  final outputStream = OutputFileStream(zipPath);
  ZipEncoder().encode(archive, output: outputStream);
  await outputStream.close();

  print("✅ ZIP created at $zipPath");
}
