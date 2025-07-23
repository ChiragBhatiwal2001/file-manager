import 'dart:io';

import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/limit_setting_provider.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_added_body.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_app_bar.dart';
import 'package:file_manager/Widgets/Search_Bottom_Sheet/search_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentAddedScreen extends ConsumerStatefulWidget {
  const RecentAddedScreen({super.key});

  @override
  ConsumerState<RecentAddedScreen> createState() => _RecentAddedScreenState();
}

class _RecentAddedScreenState extends ConsumerState<RecentAddedScreen> {
  List<MediaFile> data = [];
  Map<MediaType, List<MediaFile>> categorizedRecent = {};
  bool _isLoading = false;
  bool isGrid = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  static List<MediaFile> _filterRecentMedia(List<MediaFile> allFiles) {
    final now = DateTime.now();
    final fifteenDaysAgo = now.subtract(const Duration(days: 15));

    return allFiles.where((file) {
      try {
        final f = File(file.path);
        if (!f.existsSync()) return false;
        final modified = f.lastModifiedSync();
        return modified.isAfter(fifteenDaysAgo);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Future<void> _refreshData([String? list]) async {
    setState(() {
      _isLoading = true;
    });
    final allMedia = await MediaScanner.scanDirectory(
      Directory(Constant.internalPath!),
    );

    final filtered = await compute(_filterRecentMedia, allMedia);

    setState(() {
      data = filtered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final recentLimit = ref.watch(limitSettingsProvider).recentLimit;
    final viewMode = ref.watch(fileViewModeProvider);
    final hiddenState = ref.watch(hiddenPathsProvider);
    final showHidden = hiddenState.showHidden;
    final hiddenPaths = hiddenState.hiddenPaths;

    final limitedData = data.take(recentLimit).toList();
    final visibleLimitedData = limitedData
        .where((file) => showHidden || !hiddenPaths.contains(file.path))
        .toList();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop && selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
        }
      },
      child: Scaffold(
        appBar: RecentAddedAppBar(
          isLoading: _isLoading,
          itemCount: visibleLimitedData.length,
          isSelectionMode: selectionState.isSelectionMode,
          selectedCount: selectionState.selectedPaths.length,
          onBack: () => Navigator.pop(context),
          onClearSelection: selectionNotifier.clearSelection,
          onDelete: () async {
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
              _refreshData();
            }
          },
          onCopy: () async {
            await showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => BottomSheetForPasteOperation(
                selectedPaths: Set<String>.from(selectionState.selectedPaths),
                isCopy: true,
              ),
            ).then((result) {
              if (result != null) {
                selectionNotifier.clearSelection();
                _refreshData();
              }
            });
          },
          onMove: () async {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => BottomSheetForPasteOperation(
                selectedPaths: Set<String>.from(selectionState.selectedPaths),
                isCopy: false,
              ),
            ).then((result) {
              if (result != null) {
                selectionNotifier.clearSelection();
                _refreshData();
              }
            });
          },
          onSelectAll: () {
            selectionNotifier.selectAll(
              visibleLimitedData.map((e) => e.path).toList(),
            );
          },
          onSearch: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => SearchBottomSheet(Constant.internalPath!),
            );
          },
          onToggleView: () {
            ref.read(fileViewModeProvider.notifier).toggleMode();
          },
          viewMode: viewMode,
        ),
        body: RecentAddedBody(
          files: visibleLimitedData,
          isLoading: _isLoading,
          isGrid: viewMode == "Grid View",
          onRefresh: _refreshData,
        ),
      ),
    );
  }
}
