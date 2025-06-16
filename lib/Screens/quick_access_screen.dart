import 'dart:io';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({
    super.key,
    required this.category,
    required this.storagePath,
  });

  final String storagePath;
  final MediaType category;

  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> {
  List<MediaFile> data = [];
  bool _isLoading = false;
  bool _isSelected = false;
  Set<String> selectedPaths = {};
  bool isFavorite = false;
  String filterItem = '';
  String currentSortValue = "name-asc";

  @override
  void initState() {
    super.initState();
    _initSortValue();
    _getDataForDisplay();
  }

  void _initSortValue() async {
    final prefs = SharedPrefsService.instance;
    await prefs.init();
    final savedSort = prefs.getString("sort-preference");
    setState(() {
      currentSortValue = savedSort ?? "name-asc";
    });
    _getDataForDisplay();
  }

  void onSortChanged(String sortValue) async {
    setState(() {
      currentSortValue = sortValue;
    });
    await SharedPrefsService.instance.setString("sort-preference", sortValue);
    _getDataForDisplay();
  }

  Future<void> _getDataForDisplay([String? path]) async {
    setState(() => _isLoading = true);

    try {
      final categorized = await MediaScanner.scanAllMedia();
      List<MediaFile> files = categorized[widget.category] ?? [];

      // Sort files using SortingOperation
      final sorting = SortingOperation(
        filterItem: currentSortValue,
        folderData: [],
        fileData: files.map((e) => File(e.path)).toList(),
      );
      sorting.sortFileAndFolder();

      // Map back to MediaFile after sorting
      final sortedFiles = sorting.fileData
          .map((e) => files.firstWhere((f) => f.path == e.path))
          .toList();

      setState(() {
        data = sortedFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.category.name.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => SearchScreen(widget.storagePath),
              );
            },
            icon: Icon(Icons.search),
          ),
          PopupMenuWidget(
            popupList: ["Sorting"],
            currentSortValue: currentSortValue,
            onSortChanged: onSortChanged,
          ),
          if (_isSelected)
            TextButton(
              onPressed: () {
                setState(() {
                  selectedPaths.clear();
                  _isSelected = false;
                });
              },
              child: Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: _isLoading
            ? null
            : data.isNotEmpty
            ? PreferredSize(
                preferredSize: Size.fromHeight(34.0),
                child: Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                        child: Text(
                          "${data.length.toString()} items in total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : data.isEmpty
          ? Center(
              child: Text(
                "No ${widget.category.name} found",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            )
          : ListView.separated(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final file = data[index];
                final fileName = file.path.split("/").last;
                return ListTile(
                  leading: Icon(_getIconForMedia(file.type)),
                  title: Text(fileName),
                  trailing: IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => BottomSheetForSingleFileOperation(
                          path: file.path,
                          loadAgain: _getDataForDisplay,
                          isChangeDirectory: false,
                        ),
                      );
                    },
                    icon: Icon(Icons.more_vert),
                  ),
                  subtitle: Text(
                    file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    await OpenFilex.open(file.path);
                  },
                  onLongPress: () {
                    setState(() {
                      _isSelected = true;
                      selectedPaths.add(file.path);
                    });
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return Divider();
              },
            ),
    );
  }

  /// Returns an icon based on media type
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