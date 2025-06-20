import 'dart:io';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_app_bar_widget.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_file_grid_widget.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_file_list_widget.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/search_bottom_sheet.dart';
import 'package:file_manager/Widgets/setting_popup_menu_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String _viewMode = "List View";

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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
          return;
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: QuickAccessAppBar(
          title: widget.category.name.toUpperCase(),
          isLoading: _isLoading,
          itemCount: data.length,
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
                              children: names
                                  .map((name) => Text(name))
                                  .toList(),
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
                        builder: (context) =>
                            SearchBottomSheet(Constant.internalPath!),
                      );
                    },
                    icon: Icon(Icons.search),
                  ),
                  SettingPopupMenuWidget(
                    popupList: [
                      "Sorting",
                      _viewMode == "List View" ? "Grid View" : "List View",
                    ],
                    currentSortValue: currentSortValue,
                    onSortChanged: onSortChanged,
                    onViewModeChanged: (mode) {
                      setState(() {
                        _viewMode = mode;
                      });
                    },
                  ),
                ],
          onBack: () => Navigator.pop(context),
        ),
        body: _viewMode == "List View"
            ? QuickAccessFileList(
                data: data,
                isLoading: _isLoading,
                selectedPaths: selectedPaths,
                getDataForDisplay: _getDataForDisplay,
                selectionState: selectionState,
                selectionNotifier: selectionNotifier,
              )
            : QuickAccessFileGrid(
                data: data,
                isLoading: _isLoading,
                selectedPaths: selectedPaths,
                getDataForDisplay: _getDataForDisplay,
                selectionState: selectionState,
                selectionNotifier: selectionNotifier,
              ),
      ),
    );
  }
}
