import 'dart:io';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Services/search_operation.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_filex/open_filex.dart';

class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet(this.internalStorage, {super.key});

  final String internalStorage;

  @override
  State<SearchBottomSheet> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool hasSearched = false;
  List<FileSystemEntity> filteredFiles = [];
  bool isLoading = false;
  int selectedCategory = 0;

  final List<String> categories = [
    'All',
    'Photos',
    'Videos',
    'Audio',
    'Documents',
    'APKs'
  ];

  @override
  void initState() {
    super.initState();
  }

  void onSearchChanged(String query) async {
    setState(() {
      hasSearched = query.isNotEmpty;
      filteredFiles = [];
      isLoading = true;
    });

    final resultPaths = await startSearchInIsolate(
      widget.internalStorage,
      query,
    );

    final entities = resultPaths.map((e) => File(e)).toList();

    setState(() {
      filteredFiles = entities;
      isLoading = false;
    });
  }

  Widget _highlightMatch(String fileName, String query) {
    if (query.isEmpty) return Text(fileName);

    final lowerFileName = fileName.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerFileName.indexOf(lowerQuery);

    if (matchIndex == -1) return Text(fileName);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: fileName.substring(0, matchIndex)),
          TextSpan(
            text: fileName.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: fileName.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  List<FileSystemEntity> filterByCategory(int categoryIndex) {
    if (categoryIndex == 0) return filteredFiles;

    final extList = [
      [],
      ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'],
      ['.mp4', '.mkv', '.avi', '.3gp', '.mov'],
      ['.mp3', '.wav', '.aac', '.m4a', '.ogg'],
      ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'],
      ['.apk']
    ];

    return filteredFiles.where((file) {
      final lower = file.path.toLowerCase();
      return extList[categoryIndex].any((ext) => lower.endsWith(ext));
    }).toList();
  }

  Widget buildListView(List<FileSystemEntity> files) {
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
          title: _highlightMatch(
            file.path.split('/').last,
            _searchController.text,
          ),
          subtitle: Text(file.path),
          onTap: () {
            if (FileSystemEntity.isDirectorySync(file.path)) {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FileExplorerScreen(initialPath: file.path),
                ),
              );
            } else {
              FocusScope.of(context).unfocus();
              OpenFilex.open(file.path);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      builder: (context, scrollController) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          onSearchChanged(query);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search files...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (hasSearched)
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ChoiceChip(
                          label: Text(categories[index]),
                          selected: selectedCategory == index,
                          onSelected: (_) {
                            setState(() {
                              selectedCategory = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (hasSearched)
                Expanded(
                  child: buildListView(filterByCategory(selectedCategory)),
                ),
            ],
          ),
        );
      },
    );
  }
}
