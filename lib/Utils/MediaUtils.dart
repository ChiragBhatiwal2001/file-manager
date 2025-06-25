import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

enum MediaType { image, video, audio, document, apk,archive, other }

class MediaUtils {
  static const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  static const videoExts = ['.mp4', '.mkv', '.avi', '.3gp', '.mov'];
  static const audioExts = ['.mp3', '.wav', '.aac', '.m4a', '.ogg'];
  static const documentExts = [
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'
  ];
  static const apkExts = ['.apk'];
  static const archiveExts = ['.zip', '.rar', '.7z', '.tar', '.gz'];

  static MediaType getMediaTypeFromExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (imageExts.contains(ext)) return MediaType.image;
    if (videoExts.contains(ext)) return MediaType.video;
    if (audioExts.contains(ext)) return MediaType.audio;
    if (documentExts.contains(ext)) return MediaType.document;
    if (apkExts.contains(ext)) return MediaType.apk;
    if (archiveExts.contains(ext)) return MediaType.archive;
    return MediaType.other;
  }

  static IconData getIconForMedia(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.video_library;
      case MediaType.audio:
        return Icons.music_note;
      case MediaType.document:
        return Icons.insert_drive_file;
      case MediaType.apk:
        return Icons.android;
      case MediaType.archive:
        return Icons.archive;
      default:
        return Icons.folder;
    }
  }
}