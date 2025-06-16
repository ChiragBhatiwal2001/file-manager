import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_filex/open_filex.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen(this.internalStorage, {super.key});

  final String internalStorage;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool hasSearched = false;

  List<FileSystemEntity> filteredFiles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  void onSearchChanged(String query) async {
    setState(() {
      hasSearched = query.isNotEmpty;
      filteredFiles = [];
      isLoading = false;
    });
    if (query.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await searchFilesAsync(widget.internalStorage, query);

    setState(() {
      filteredFiles = result;
      isLoading = false;
    });
  }

  Future<List<FileSystemEntity>> searchFilesAsync(
    String rootPath,
    String query,
  ) async {
    final restrictedPaths = ['$rootPath/Android/data', '$rootPath/Android/obb'];
    List<FileSystemEntity> matchedFiles = [];

    Future<void> traverseDirectory(Directory dir) async {
      try {
        await for (var entity in dir.list(
          recursive: false,
          followLinks: false,
        )) {
          final path = entity.path;

          // Skip restricted folders
          if (restrictedPaths.any((r) => path.startsWith(r))) continue;

          if (entity is Directory) {
            await traverseDirectory(entity); // Recursive call
          } else if (entity is File) {
            final name = path.split('/').last.toLowerCase();
            if (name.contains(query.toLowerCase())) {
              matchedFiles.add(entity);
            }
          }
        }
      } catch (e) {
        debugPrint('Skipping ${dir.path}: $e');
      }
    }

    await traverseDirectory(Directory(rootPath));
    return matchedFiles;
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

  List<FileSystemEntity> filterByExtension(List<String> extensions) {
    return filteredFiles.where((file) {
      final lower = file.path.toLowerCase();
      return extensions.any((ext) => lower.endsWith(ext));
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
          leading: Icon(
            file is Directory ? Icons.folder : Icons.insert_drive_file,
          ),
          title: _highlightMatch(
            file.path.split('/').last,
            _searchController.text,
          ),
          subtitle: Text(file.path),
          onTap: (){
            FocusScope.of(context).unfocus();
            OpenFilex.open(file.path);
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
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (query) {
                        // debounce can be added for performance
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
            // if (!hasSearched || _searchController.text.isEmpty)
            //   Expanded(
            //     child: Center(
            //       child: Text(
            //         'Start searching...',
            //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //   ),

            if (hasSearched)
              TabBar(
                controller: _tabController,
                indicatorPadding: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Photos'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Audio'),
                  Tab(text: 'Documents'),
                  Tab(text: 'APKs'),
                ],
              ),
            if (hasSearched)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    buildListView(filteredFiles), // All
                    buildListView(
                      filterByExtension([
                        '.jpg',
                        '.jpeg',
                        '.png',
                        '.gif',
                        '.bmp',
                        '.webp',
                      ]),
                    ),
                    buildListView(
                      filterByExtension([
                        '.mp4',
                        '.mkv',
                        '.avi',
                        '.3gp',
                        '.mov',
                      ]),
                    ),
                    buildListView(
                      filterByExtension([
                        '.mp3',
                        '.wav',
                        '.aac',
                        '.m4a',
                        '.ogg',
                      ]),
                    ),
                    buildListView(
                      filterByExtension([
                        '.pdf',
                        '.doc',
                        '.docx',
                        '.xls',
                        '.xlsx',
                        '.ppt',
                        '.pptx',
                        '.txt',
                      ]),
                    ),
                    buildListView(filterByExtension(['.apk'])),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
