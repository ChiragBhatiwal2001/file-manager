import 'dart:io';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_added_content_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class RecentAddedScreen extends StatefulWidget {
  const RecentAddedScreen({super.key});

  @override
  State<RecentAddedScreen> createState() => _RecentAddedScreenState();
}

class _RecentAddedScreenState extends State<RecentAddedScreen> {
  Map<MediaType, List<MediaFile>> categorizedRecent = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getAllCategory();
  }

  static Map<MediaType, List<MediaFile>> _filterRecentMedia(
      Map<MediaType, List<MediaFile>> categorized,
      ) {
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));
    final result = <MediaType, List<MediaFile>>{};

    for (final entry in categorized.entries) {
      final recentFiles = entry.value.where((file) {
        try {
          final f = File(file.path);
          if (!f.existsSync()) return false;
          final modified = f.lastModifiedSync();
          return modified.isAfter(fifteenDaysAgo);
        } catch (_) {
          return false;
        }
      }).toList();

      if (recentFiles.isNotEmpty) {
        result[entry.key] = recentFiles;
      }
    }

    return result;
  }

  void _getAllCategory() async {
    setState(() => _isLoading = true);
    final categorized = await MediaScanner.scanAllMedia();

    final filtered = await compute(_filterRecentMedia, categorized);

    setState(() {
      categorizedRecent = filtered;
      _isLoading = false;
    });
  }

  final mediaTypes = {
    MediaType.image: Icons.image,
    MediaType.video: Icons.video_library,
    MediaType.audio: Icons.music_note,
    MediaType.document: Icons.insert_drive_file,
    MediaType.apk: Icons.android,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recently Added", style: TextStyle(fontWeight: FontWeight.bold)),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : categorizedRecent.isNotEmpty
          ? GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: categorizedRecent.length,
        itemBuilder: (context, index) {
          final category = categorizedRecent.keys.elementAt(index);
          final files = categorizedRecent[category]!;
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecentAddedContentWidget(
                    categoryName: category.name,
                    categoryList: files,
                    onOperationDone: _getAllCategory,
                  ),
                ),
              );
              setState(() {});
            },
            child: Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mediaTypes[category], size: 40),
                  const SizedBox(height: 10),
                  Text(category.name.toUpperCase()),
                ],
              ),
            ),
          );
        },
      )
          : const Center(
        child: Text(
          "No Recent Files Found",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
