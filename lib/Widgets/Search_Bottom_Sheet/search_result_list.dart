import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'highlight_text.dart';

class SearchResultList extends StatelessWidget {
  final List<FileSystemEntity> files;
  final String query;
  final bool isLoading;

  const SearchResultList({
    super.key,
    required this.files,
    required this.query,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (files.isEmpty) {
      return const Center(
        child: Text(
          'No files found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final filename = file.path.split('/').last;

        return ListTile(
          leading: FutureBuilder<Uint8List?>(
            future: ThumbnailService.getThumbnail(file.path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData &&
                  snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    snapshot.data!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                return CircleAvatar(
                  child: Icon(
                    MediaUtils.getIconForMedia(
                      MediaUtils.getMediaTypeFromExtension(file.path),
                    ),
                  ),
                );
              }
            },
          ),
          title: HighlightText(text: filename, query: query),
          onTap: () {
            FocusScope.of(context).unfocus();
            if (FileSystemEntity.isDirectorySync(file.path)) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FileExplorerScreen(initialPath: file.path),
                ),
              );
            } else {
              OpenFilex.open(file.path);
            }
          },
        );
      },
    );
  }
}
