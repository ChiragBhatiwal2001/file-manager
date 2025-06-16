import 'dart:io';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class HeaderForSingleFileOperation extends StatelessWidget {
  const HeaderForSingleFileOperation({super.key,required this.path, required this.fileData});

  final Map<String, dynamic> fileData;
  final String path;

  IconData _getIconForMedia(MediaType type) {
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
      default:
        return Icons.folder;
    }
  }

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

  MediaType _getMediaTypeFromExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (imageExts.contains(ext)) return MediaType.image;
    if (videoExts.contains(ext)) return MediaType.video;
    if (audioExts.contains(ext)) return MediaType.audio;
    if (documentExts.contains(ext)) return MediaType.document;
    if (apkExts.contains(ext)) return MediaType.apk;
    return MediaType.other;
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = FileSystemEntity.isDirectorySync(path);
    final iconData = isFolder
        ? Icons.folder
        : _getIconForMedia(_getMediaTypeFromExtension(path));
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(radius: 28, child: Icon(iconData, size: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileData['Name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileData['Size']?.toString() ?? '',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ) // Drag handle
    ;
  }
}
