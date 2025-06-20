import 'dart:developer';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Utils/constant.dart';

class MediaFile {
  final String path;
  final MediaType type;

  MediaFile({required this.path, required this.type});
}

class MediaScanner {
  static Future<List<MediaFile>> scanDirectory(Directory dir) async {
    List<MediaFile> mediaFiles = [];

    if (!await dir.exists()) return mediaFiles;

    final restrictedFolders = [
      '${Constant.internalPath}/Android/data',
      '${Constant.internalPath}/Android/obb',
      '${Constant.internalPath}/.file_manager_trash',
    ].map(p.normalize).toList();

    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        final path = p.normalize(entity.path);

        // Skip restricted folders
        final isRestricted = restrictedFolders.any((r) =>
        p.equals(r, path) || p.isWithin(r, path)
        );
        if (isRestricted) continue;

        if (entity is Directory) {
          mediaFiles.addAll(await scanDirectory(entity));
        } else if (entity is File) {
          final type = MediaUtils.getMediaTypeFromExtension(path);
          if (type != MediaType.other) {
            mediaFiles.add(MediaFile(path: path, type: type));
          }
        }
      }
    } catch (e, stackTrace) {
      log('Error scanning directory ${dir.path}: $e', stackTrace: stackTrace);
    }

    return mediaFiles;
  }

  static Future<Map<MediaType, List<MediaFile>>> scanAllMedia() async {
    final rootDir = Directory(Constant.internalPath!);

    Map<MediaType, List<MediaFile>> categorized = {
      MediaType.image: [],
      MediaType.video: [],
      MediaType.audio: [],
      MediaType.document: [],
      MediaType.apk: [],
      MediaType.other: [],
    };

    if (await rootDir.exists()) {
      final files = await scanDirectory(rootDir);
      for (var file in files) {
        categorized[file.type]!.add(file);
      }
    }

    return categorized;
  }
}
