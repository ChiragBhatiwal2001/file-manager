import 'dart:io';

import 'package:file_manager/Services/media_scanner.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class RecentAddedContentWidget extends StatefulWidget {
  const RecentAddedContentWidget({
    super.key,
    required this.categoryName,
    required this.categoryList,
  });

  final List<MediaFile> categoryList;
  final String categoryName;

  @override
  State<RecentAddedContentWidget> createState() {
    return _RecentAddedContentWidgetState();
  }
}

class _RecentAddedContentWidgetState extends State<RecentAddedContentWidget> {
  List<MediaFile> data = [];

  @override
  void initState() {
    super.initState();
    data = widget.categoryList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Text(
          widget.categoryName.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:  ListView.separated(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final file = data[index];
                final fileName = file.path.split("/").last;
                return ListTile(
                  leading: Icon(_getIconForMedia(file.type)),
                  title: Text(fileName),
                  subtitle: Text(
                    file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    OpenFilex.open(file.path);
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider();
              },
            ),
    );
  }

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
}
