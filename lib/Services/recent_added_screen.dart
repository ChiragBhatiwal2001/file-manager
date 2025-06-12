import 'dart:io';

import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Widgets/recent_added_content_widget.dart';
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

  void _getAllCategory() async {
    setState(() {
      _isLoading = true;
    });
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(Duration(days: 7));

    final categorized = await MediaScanner.scanAllMedia();
    setState(() {
      categorizedRecent.clear();
      for (var type in categorized.keys) {
        final filtered = categorized[type]!.where((file) {
          final modified = File(file.path).lastModifiedSync();
          return modified.isAfter(sevenDaysAgo);
        }).toList();

        if (filtered.isNotEmpty) {
          categorizedRecent[type] = filtered;
        }
      }
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
        title: Text("Recently Added"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: categorizedRecent.length,
              itemBuilder: (context, index) {
                final category = categorizedRecent.keys.elementAt(index);
                final files = categorizedRecent[category]!;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecentAddedContentWidget(
                          categoryName: category.name,
                          categoryList: files,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(mediaTypes[category], size: 40),
                        SizedBox(height: 10),
                        Text(category.name.toUpperCase()),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
