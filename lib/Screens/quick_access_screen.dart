import 'dart:io';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Common_Appbar/common_appbar_actions.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_app_bar_widget.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_file_grid_widget.dart';
import 'package:file_manager/Widgets/Quick_Access/quick_access_file_list_widget.dart';
import 'package:file_manager/Widgets/Search_Bottom_Sheet/search_bottom_sheet.dart';
import 'package:file_manager/Widgets/setting_popup_menu_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    final fileViewMode = ref.watch(fileViewModeProvider);
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
              ? [SelectionActionsWidget(onPostAction: _getDataForDisplay,enableShare: true,)]
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
                      fileViewMode == "List View" ? "Grid View" : "List View",
                    ],
                    currentSortValue: currentSortValue,
                    onSortChanged: onSortChanged,
                    onViewModeChanged: (mode) {
                      ref.read(fileViewModeProvider.notifier).setMode(mode);
                    },
                  ),
                ],
          onBack: () => Navigator.pop(context),
        ),
        body: fileViewMode == "List View"
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
