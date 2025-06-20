import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_added_tile.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/search_bottom_sheet.dart';
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
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Text(
            widget.categoryName.toUpperCase(),
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
                        _refreshData();
                        widget.onOperationDone?.call();
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
                        _refreshData();
                        widget.onOperationDone?.call();
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
                  IconButton(
                    icon: Icon(isGrid ? Icons.list : Icons.grid_view),
                    onPressed: () => setState(() => isGrid = !isGrid),
                  ),
                ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : isGrid
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16
                ),
                itemBuilder: (context, index) => RecentAddedTile(
                  file: data[index],
                  isGrid: true,
                  onRefresh: _refreshData,
                  onOperationDone: widget.onOperationDone,
                ),
              )
            : ListView.separated(
                itemCount: data.length,
                itemBuilder: (context, index) => RecentAddedTile(
                  file: data[index],
                  onRefresh: _refreshData,
                  isGrid: false,
                  onOperationDone: widget.onOperationDone,
                ),
                separatorBuilder: (_, __) => const Divider(),
              ),
      ),
    );
  }
}
