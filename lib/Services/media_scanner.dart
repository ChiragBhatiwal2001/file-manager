import 'dart:io';
import 'package:path/path.dart' as p;

/// Supported media types
enum MediaType { image, video, audio, document, apk, other }

/// Media file model with type and path
class MediaFile {
  final String path;
  final MediaType type;

  MediaFile({required this.path, required this.type});
}

/// Media scanner that scans internal and external storage for files by type
class MediaScanner {
  /// Common file extensions by category
  static const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  static const videoExts = ['.mp4', '.mkv', '.avi', '.3gp', '.mov'];
  static const audioExts = ['.mp3', '.wav', '.aac', '.m4a', '.ogg'];
  static const documentExts = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
  ];
  static const apkExts = ['.apk'];

  /// Scans a given directory recursively for media files
  static Future<List<MediaFile>> scanDirectory(Directory dir) async {
    List<MediaFile> mediaFiles = [];

    if (!await dir.exists()) return mediaFiles;

    final restrictedFolders = [
      '/storage/emulated/0/Android/data',
      '/storage/emulated/0/Android/obb',
    ];

    try {
      await for (var entity in dir.list(recursive: false, followLinks: false)) {
        final path = entity.path;

        // Skip restricted folders
        if (entity is Directory &&
            restrictedFolders.any((r) => path.startsWith(r))) {
          print("Skipped restricted folder: $path");
          continue;
        }

        if (entity is Directory) {
          // Recursively scan safe subdirectories
          mediaFiles.addAll(await scanDirectory(entity));
        } else if (entity is File) {
          final ext = p.extension(path).toLowerCase();
          if (imageExts.contains(ext)) {
            mediaFiles.add(MediaFile(path: path, type: MediaType.image));
          } else if (videoExts.contains(ext)) {
            mediaFiles.add(MediaFile(path: path, type: MediaType.video));
          } else if (audioExts.contains(ext)) {
            mediaFiles.add(MediaFile(path: path, type: MediaType.audio));
          } else if (documentExts.contains(ext)) {
            mediaFiles.add(MediaFile(path: path, type: MediaType.document));
          } else if (apkExts.contains(ext)) {
            mediaFiles.add(MediaFile(path: path, type: MediaType.apk));
          }
        }
      }
    } catch (e) {
      print("Skipped ${dir.path} — $e");
    }

    return mediaFiles;
  }

  /// Scans both internal and external storage directories
  static Future<Map<MediaType, List<MediaFile>>> scanAllMedia() async {
    final rootDir = Directory("/storage/emulated/0");// TODO - Have to change this static path

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
        categorized[file.type]?.add(file);
      }
    }

    return categorized;
  }
}
