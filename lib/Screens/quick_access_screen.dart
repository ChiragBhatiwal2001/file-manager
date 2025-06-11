import 'package:file_manager/Helpers/rename_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Widgets/bottom_bar_widget.dart';
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

  @override
  void initState() {
    super.initState();
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
                preferredSize: Size.fromHeight(24.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                      child: Text(
                        "${data.length.toString()} items in total",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Spacer(),
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
                  trailing: _isSelected ? Checkbox(value: isChecked, onChanged: (value){
                    setState(() {
                      value == true ?
                      selectedPaths.add(file.path) : selectedPaths.remove(file.path);
                    });
                  }) : null,
                  subtitle: Text(
                    file.path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    OpenFilex.open(file.path);
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
