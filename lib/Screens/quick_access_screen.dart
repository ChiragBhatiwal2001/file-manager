import 'dart:io';

import 'package:file_manager/Helpers/rename_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Services/sqflite_favorites.dart';
import 'package:file_manager/Utils/shared_preference.dart';
import 'package:file_manager/Widgets/bottom_bar_widget.dart';
import 'package:file_manager/Widgets/filter_popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key, required this.category});

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
  bool _haveFilter = false;

  @override
  void initState() {
    super.initState();
    _loadFilterPreference();
    _getDataForDisplay();
  }

  /// Loads media files of the selected category (image, video, etc.)
  Future<void> _getDataForDisplay() async {
    setState(() => _isLoading = true);

    try {
      // Get categorized media files
      final categorized = await MediaScanner.scanAllMedia();
      // Update UI
      setState(() {
        data = categorized[widget.category] ?? [];
        _haveFilter ? _sortFileAndFolder() : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRenameDialog() async {
    final oldPath = selectedPaths.first;
    print("yes ia m getting old path $oldPath");
    await renameDialogBox(
      context: context,
      oldPath: oldPath,
      onSuccess: () async {
        setState(() {
          selectedPaths.clear();
          _isSelected = false;
        });
        await _getDataForDisplay();
      },
    );
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isSelected = false;
    });
    for (var path in selectedPaths) {
      await FileOperations().deleteOperation(path);
    }
    selectedPaths.clear();
    await MediaScanner.scanAllMedia();
    await _getDataForDisplay();
    setState(() {});
  }

  Future<void> _handleFavorite() async {
    final path = selectedPaths.first;
    final db = FavoritesDB();
    final currentlyFavorite = await db.isFavorite(path);
    final isFolder = FileSystemEntity.isDirectorySync(path);

    if (currentlyFavorite) {
      await db.removeFavorite(path);
      isFavorite = false;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Removed From Favorites")));
    } else {
      await db.addFavorite(path, isFolder);
      isFavorite = true;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Added To Favorites")));
    }
    setState(() {
      _isSelected = false;
    });
  }

  Future<void> _loadFilterPreference() async {
    await SharedPrefsService.instance.init();
    final savedFilter = SharedPrefsService.instance.getString("sort_filter");
    if (savedFilter != null) {
      setState(() {
        filterItem = savedFilter;
        _haveFilter = true;
      });
    }
    // currentPath = widget.path;
    // _loadContent(currentPath);
  }

  void _sortFileAndFolder() {
    switch (filterItem) {
      case "name-asc":
        data.sort(
          (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
        );
        break;
      case "name-desc":
        data.sort(
          (a, b) => b.path.toLowerCase().compareTo(a.path.toLowerCase()),
        );
        break;
      case "size":
        data.sort((a, b) {
          final aSize = File(a.path).lengthSync();
          final bSize = File(b.path).lengthSync();
          return bSize.compareTo(aSize); // Largest file first
        });
        break;
    }
  }

  void _filterChanged(String value) async {
    setState(() {
      filterItem = value;
      _sortFileAndFolder();
    });
    await SharedPrefsService.instance.setString("sort_filter", value);
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
            : PreferredSize(
                preferredSize: Size.fromHeight(34.0),
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
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterPopupMenuWidget(
                        filterValue: filterItem,
                        onChanged: _filterChanged,
                      ),
                    ),
                  ],
                ),
              ),
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
                final isChecked = selectedPaths.contains(file.path);
                return ListTile(
                  leading: Icon(_getIconForMedia(file.type)),
                  title: Text(fileName),
                  trailing: _isSelected
                      ? Checkbox(
                          value: isChecked,
                          onChanged: (value) {
                            setState(() {
                              value == true
                                  ? selectedPaths.add(file.path)
                                  : selectedPaths.remove(file.path);
                            });
                          },
                        )
                      : null,
                  subtitle: Text(
                    file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    final result = await OpenFilex.open(file.path);
                    print(
                      "OpenFliex result : ${result.type}, message: ${result.message}",
                    );
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
      bottomNavigationBar: _isSelected
          ? BottomBarWidget(
              isRenameEnabled: selectedPaths.length <= 1,
              onRename: _showRenameDialog,
              onDelete: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Do You Really Want To Delete?"),
                    duration: Duration(seconds: 5),
                    action: SnackBarAction(
                      label: "Yes",
                      onPressed: _handleDelete, // No async here
                    ),
                  ),
                );
              },
              isFavorite: selectedPaths.length == 1 ? isFavorite : null,
              onFavoriteClicked: selectedPaths.length == 1
                  ? _handleFavorite
                  : null,
            )
          : null,
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
