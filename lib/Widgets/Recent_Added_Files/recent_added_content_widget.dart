import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/limit_setting_provider.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_added_tile.dart';
import 'package:file_manager/Widgets/Search_Bottom_Sheet/search_bottom_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecentAddedContentWidget extends ConsumerStatefulWidget {
  const RecentAddedContentWidget({
    super.key,
    required this.categoryName,
    required this.categoryList,
    this.onOperationDone,
  });

  final List<MediaFile> categoryList;
  final String categoryName;
  final VoidCallback? onOperationDone;

  @override
  ConsumerState<RecentAddedContentWidget> createState() {
    return _RecentAddedContentWidgetState();
  }
}

class _RecentAddedContentWidgetState
    extends ConsumerState<RecentAddedContentWidget> {
  List<MediaFile> data = [];
  bool _isLoading = false;
  bool isGrid = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData([String? list]) async {
    setState(() {
      _isLoading = true;
    });
    final allMedia = await MediaScanner.scanAllMedia();
    final updatedList = allMedia[widget.categoryList.first.type] ?? [];
    setState(() {
      data = updatedList;
      _isLoading = false;
    });
  }

  @override
  void didUpdateWidget(covariant RecentAddedContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.categoryList, widget.categoryList)) {
      setState(() {
        data = List<MediaFile>.from(widget.categoryList);
      });
    }
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
    final selectedCount = selectionState.selectedPaths.length;

    final limitedData = data.take(recentLimit).toList();

    final visibleLimitedData = limitedData.where((file) {
      return showHidden || !hiddenPaths.contains(file.path);
    }).toList();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (!didPop && selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (selectionState.isSelectionMode) {
                selectionNotifier.clearSelection();
              } else {
                Navigator.pop(context);
              }
            },
            icon: Icon(
              selectionState.isSelectionMode ? Icons.close : Icons.arrow_back,
            ),
          ),
          bottom: _isLoading
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(34.0),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${visibleLimitedData.length} items in total",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
          titleSpacing: 0,
          title: Text(
            selectedCount > 0
                ? "$selectedCount selected"
                : widget.categoryName.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold),
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
                        _refreshData();
                        widget.onOperationDone?.call();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        builder: (context) => BottomSheetForPasteOperation(
                          selectedPaths: Set<String>.from(
                            selectionState.selectedPaths,
                          ),
                          isCopy: true,
                        ),
                      ).then((result) {
                        if (result != null) {
                          selectionNotifier.clearSelection();
                          _refreshData();
                          widget.onOperationDone?.call();
                        }
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
                      ).then((result) {
                        if (result != null) {
                          selectionNotifier.clearSelection();
                          _refreshData();
                          widget.onOperationDone?.call();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.select_all),
                    onPressed: () {
                      selectionNotifier.selectAll(
                        visibleLimitedData.map((e) => e.path).toList(),
                      );
                    },
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
                  IconButton(
                    icon: Icon(
                      viewMode == "Grid View" ? Icons.list : Icons.grid_view,
                    ),
                    onPressed: () {
                      ref.read(fileViewModeProvider.notifier).toggleMode();
                    },
                  ),
                ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewMode == "Grid View"
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visibleLimitedData.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) => RecentAddedTile(
                  file: visibleLimitedData[index],
                  isGrid: true,
                  onRefresh: _refreshData,
                  onOperationDone: widget.onOperationDone,
                ),
              )
            : ListView.separated(
                itemCount: visibleLimitedData.length,
                itemBuilder: (context, index) => RecentAddedTile(
                  file: visibleLimitedData[index],
                  isGrid: false,
                  onRefresh: _refreshData,
                  onOperationDone: widget.onOperationDone,
                ),
                separatorBuilder: (_, __) => const Divider(),
              ),
      ),
    );
  }
}
