import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/search_operation.dart';
import 'search_bar.dart';
import 'category_selector.dart';
import 'search_result_list.dart';

class SearchBottomSheet extends StatefulWidget {
  final String internalStorage;
  const SearchBottomSheet(this.internalStorage, {super.key});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool hasSearched = false;
  List<FileSystemEntity> allResults = [];
  bool isLoading = false;
  int selectedCategory = 0;

  final List<String> categories = ['All', 'Photos', 'Videos', 'Audio', 'Documents', 'APKs'];

  void onSearchChanged(String query) async {
    setState(() {
      hasSearched = query.isNotEmpty;
      allResults = [];
      isLoading = true;
    });

    final resultPaths = await startSearchInIsolate(widget.internalStorage, query);
    final entities = resultPaths.map((e) => File(e)).toList();

    setState(() {
      allResults = entities;
      isLoading = false;
    });
  }

  List<FileSystemEntity> filterByCategory(int index) {
    if (index == 0) return allResults;

    final extensions = [
      [],
      ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'],
      ['.mp4', '.mkv', '.avi', '.3gp', '.mov'],
      ['.mp3', '.wav', '.aac', '.m4a', '.ogg'],
      ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt'],
      ['.apk'],
    ];

    return allResults.where((file) {
      final lower = file.path.toLowerCase();
      return extensions[index].any((ext) => lower.endsWith(ext));
    }).toList();
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
              SearchBarWidget(
                controller: _searchController,
                onChanged: onSearchChanged,
              ),
              if (hasSearched)
                CategorySelector(
                  categories: categories,
                  selectedIndex: selectedCategory,
                  onCategorySelected: (index) => setState(() => selectedCategory = index),
                ),
              if (hasSearched)
                Expanded(
                  child: SearchResultList(
                    files: filterByCategory(selectedCategory),
                    query: _searchController.text,
                    isLoading: isLoading,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
