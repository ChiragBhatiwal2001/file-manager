import 'dart:io';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:flutter/material.dart';

class HeaderForSingleFileOperation extends StatelessWidget {
  const HeaderForSingleFileOperation({super.key,required this.path, required this.fileData});

  final Map<String, dynamic> fileData;
  final String path;

  @override
  Widget build(BuildContext context) {
    final isFolder = FileSystemEntity.isDirectorySync(path);
    final iconData = isFolder
        ? Icons.folder
        : MediaUtils.getIconForMedia(MediaUtils.getMediaTypeFromExtension(path));
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
