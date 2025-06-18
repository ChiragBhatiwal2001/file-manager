import 'dart:io';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class QuickAccessScreen extends ConsumerStatefulWidget {
  const QuickAccessScreen({
    super.key,
    required this.category,
    required this.storagePath,
  });

  final String storagePath;
  final MediaType category;

  @override
  ConsumerState<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends ConsumerState<QuickAccessScreen> {
  List<MediaFile> data = [];
  bool _isLoading = false;
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
        print(data);
        _isLoading = false;
        selectedPaths.value = {};
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          widget.category.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: selectionState.isSelectionMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final names = selectionState.selectedPaths
                        .map((e) => p.basename(e))
                        .toList();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Do you really want to delete?'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: names.map((name) => Text(name)).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Yes'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      for (final path in selectionState.selectedPaths) {
                        await FileOperations().deleteOperation(path);
                      }
                      selectionNotifier.clearSelection();
                      _getDataForDisplay();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.copy),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (context) => BottomSheetForPasteOperation(
                        selectedPaths: Set<String>.from(
                          selectionState.selectedPaths,
                        ),
                        isCopy: true,
                      ),
                    ).then((_) {
                      selectionNotifier.clearSelection();
                      _getDataForDisplay();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.drive_file_move),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (context) => BottomSheetForPasteOperation(
                        selectedPaths: Set<String>.from(
                          selectionState.selectedPaths,
                        ),
                        isCopy: false,
                      ),
                    ).then((_) {
                      selectionNotifier.clearSelection();
                      _getDataForDisplay();
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: selectionNotifier.clearSelection,
                ),
              ]
            : [
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (context) => SearchScreen(Constant.internalPath),
                    );
                  },
                  icon: Icon(Icons.search),
                ),
                PopupMenuWidget(
                  popupList: const ["Sorting"],
                  currentSortValue: currentSortValue,
                  onSortChanged: onSortChanged,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
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
                    return ListTile(
                      key: ValueKey(file.path),
                      leading: CircleAvatar(
                        child: Icon(_getIconForMedia(file.type)),
                      ),
                      title: Text(fileName),
                      trailing: Consumer(
                        builder: (context, ref, _) {
                          final selectionState = ref.watch(selectionProvider);
                          final selectionNotifier = ref.read(
                            selectionProvider.notifier,
                          );
                          return selectionState.isSelectionMode
                              ? Checkbox(
                                  value: selectionState.selectedPaths.contains(
                                    file.path,
                                  ),
                                  onChanged: (_) => selectionNotifier
                                      .toggleSelection(file.path),
                                )
                              : IconButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) =>
                                          BottomSheetForSingleFileOperation(
                                            path: file.path,
                                            loadAgain: AsyncValue.data,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.more_vert),
                                );
                        },
                      ),
                      onTap: () {
                        final isSelectionMode = selectionState.isSelectionMode;
                        if (isSelectionMode) {
                          selectionNotifier.toggleSelection(file.path);
                        } else {
                          OpenFilex.open(file.path);
                        }
                      },
                      onLongPress: () {
                        selectionNotifier.toggleSelection(file.path);
                      },
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
