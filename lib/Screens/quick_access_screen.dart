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
  bool _isSelectionMode = false;
  late ValueNotifier<Set<String>> selectedPaths;
  String currentSortValue = "name-asc";

  @override
  void initState() {
    super.initState();
    selectedPaths = ValueNotifier<Set<String>>({});
    _initSortValue();
  }

  @override
  void dispose() {
    selectedPaths.dispose();
    super.dispose();
  }

  void _initSortValue() async {
    final prefs = SharedPrefsService.instance;
    await prefs.init();
    final savedSort = prefs.getString("sort-preference");
    currentSortValue = savedSort ?? "name-asc";
    _getDataForDisplay();
  }

  void onSortChanged(String sortValue) async {
    currentSortValue = sortValue;
    await SharedPrefsService.instance.setString("sort-preference", sortValue);
    _getDataForDisplay();
  }

  Future<void> _getDataForDisplay([String? path]) async {
    setState(() => _isLoading = true);
    try {
      final categorized = await MediaScanner.scanAllMedia();
      List<MediaFile> files = categorized[widget.category] ?? [];
      final sorting = SortingOperation(
        filterItem: currentSortValue,
        folderData: [],
        fileData: files.map((e) => File(e.path)).toList(),
      );
      sorting.sortFileAndFolder();
      final sortedFiles = sorting.fileData
          .map((e) => files.firstWhere((f) => f.path == e.path))
          .toList();
      setState(() {
        data = sortedFiles;
        _isLoading = false;
        _isSelectionMode = false;
        selectedPaths.value = {};
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onLongPress(String path) {
    setState(() {
      _isSelectionMode = true;
    });
    selectedPaths.value = {...selectedPaths.value, path};
  }

  void _onTap(String path) async {
    if (_isSelectionMode) {
      final newSet = Set<String>.from(selectedPaths.value);
      if (newSet.contains(path)) {
        newSet.remove(path);
        if (newSet.isEmpty) {
          setState(() => _isSelectionMode = false);
        }
      } else {
        newSet.add(path);
      }
      selectedPaths.value = newSet;
    } else {
      await OpenFilex.open(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.category.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => SearchScreen(widget.storagePath),
              );
            },
            icon: const Icon(Icons.search),
          ),
          PopupMenuWidget(
            popupList: const ["Sorting"],
            currentSortValue: currentSortValue,
            onSortChanged: onSortChanged,
          ),
          if (_isSelectionMode)
            TextButton(
              onPressed: () {
                setState(() => _isSelectionMode = false);
                selectedPaths.value = {};
              },
              child: const Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: _isLoading || data.isEmpty
            ? null
            : PreferredSize(
          preferredSize: const Size.fromHeight(34.0),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "${data.length} items in total",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
          ? Center(
        child: Text(
          "No ${widget.category.name} found",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      )
          : ValueListenableBuilder<Set<String>>(
        valueListenable: selectedPaths,
        builder: (context, selected, _) {
          return ListView.separated(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final file = data[index];
              final fileName = file.path.split("/").last;
              final isSelected = selected.contains(file.path);
              return ListTile(
                key: ValueKey(file.path),
                leading: Icon(_getIconForMedia(file.type)),
                title: Text(fileName),
                trailing: _isSelectionMode
                    ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _onTap(file.path),
                )
                    : IconButton(
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
                  icon: const Icon(Icons.more_vert),
                ),
                subtitle: Text(
                  file.path,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _onTap(file.path),
                onLongPress: () => _onLongPress(file.path),
                selected: isSelected,
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
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