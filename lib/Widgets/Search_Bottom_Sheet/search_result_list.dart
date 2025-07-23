import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'highlight_text.dart';

class SearchResultList extends StatefulWidget {
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
  State<SearchResultList> createState() => _SearchResultListState();
}

class _SearchResultListState extends State<SearchResultList> {
  final Map<String, Uint8List?> _thumbnailCache = {};

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.files.isEmpty) {
      return const Center(
        child: Text(
          'No files found',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        final filePath = file.path;
        final filename = filePath.split('/').last;

        return ListTile(
          leading: _buildThumbnail(file),
          title: HighlightText(text: filename, query: widget.query),
          onTap: () {
            FocusScope.of(context).unfocus();
            if (FileSystemEntity.isDirectorySync(filePath)) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FileExplorerScreen(initialPath: filePath),
                ),
              );
            } else {
              OpenFilex.open(filePath);
            }
          },
        );
      },
    );
  }

  Widget _buildThumbnail(FileSystemEntity file) {
    final filePath = file.path;

    if (_thumbnailCache.containsKey(filePath)) {
      final data = _thumbnailCache[filePath];
      if (data != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(data, width: 40, height: 40, fit: BoxFit.cover),
        );
      }
    }

    if (FileSystemEntity.isDirectorySync(filePath)) {
      return const CircleAvatar(child: Icon(Icons.folder));
    } else {
      final mediaType = MediaUtils.getMediaTypeFromExtension(filePath);
      _fetchThumbnail(filePath);
      return CircleAvatar(child: Icon(MediaUtils.getIconForMedia(mediaType)));
    }
  }

  void _fetchThumbnail(String filePath) async {
    final data = await ThumbnailService.getThumbnail(filePath);
    if (mounted) {
      setState(() {
        _thumbnailCache[filePath] = data;
      });
    }
  }
}
