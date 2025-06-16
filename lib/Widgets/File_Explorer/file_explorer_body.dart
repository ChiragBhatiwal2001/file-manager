import 'dart:io';
import 'dart:ui';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

class FileExplorerBody extends StatefulWidget {
  FileExplorerBody(
    this.folderData,
    this.fileData,
    this.loadDirectoryPath, {
    super.key,
  });

  List<FileSystemEntity> folderData;
  List<FileSystemEntity> fileData;
  void Function(String path) loadDirectoryPath;

  @override
  State<FileExplorerBody> createState() => _FileExplorerBodyState();
}

class _FileExplorerBodyState extends State<FileExplorerBody> {

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
    return widget.folderData.isEmpty && widget.fileData.isEmpty
        ? ScreenEmptyWidget()
        : ListView.builder(
            itemCount:
                (widget.folderData.isNotEmpty
                    ? widget.folderData.length + 1
                    : 0) +
                (widget.fileData.isNotEmpty ? widget.fileData.length + 1 : 0),
            itemBuilder: (context, index) {
              final folderHeaderIndex = 0;
              final fileHeaderIndex = widget.folderData.isNotEmpty
                  ? widget.folderData.length + 1
                  : 0;
              if (index == folderHeaderIndex && widget.folderData.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
                  child: Text(
                    "Folders",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigoAccent,
                    ),
                  ),
                );
              } else if (index > folderHeaderIndex && index < fileHeaderIndex) {
                final folderPath = widget.folderData[index - 1].path;
                final folderName = p.basename(folderPath);
                return ListTile(
                  title: Text(folderName),
                  leading: Icon(Icons.folder),
                  trailing: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) =>
                            BottomSheetForSingleFileOperation(path: folderPath,loadAgain: widget.loadDirectoryPath),
                      );
                    },
                    icon: Icon(Icons.more_vert),
                  ),
                  onTap: () {
                    widget.loadDirectoryPath(folderPath);
                  },
                );
              } else if (index == fileHeaderIndex &&
                  widget.fileData.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
                  child: Text(
                    "Files",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigoAccent,
                    ),
                  ),
                );
              } else {
                final filePath =
                    widget.fileData[index - fileHeaderIndex - 1].path;
                final fileName = p.basename(filePath);
                final iconData = _getIconForMedia(_getMediaTypeFromExtension(filePath));
                return ListTile(
                  title: Text(fileName),
                  leading: Icon(iconData),
                  trailing: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) =>
                            BottomSheetForSingleFileOperation(path: filePath,loadAgain: widget.loadDirectoryPath,),
                      );
                    },
                    icon: Icon(Icons.more_vert),
                  ),
                  onTap: () {
                    OpenFilex.open(filePath);
                  },
                );
              }
            },
          );
  }
}