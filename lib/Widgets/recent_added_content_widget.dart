import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
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
                            SearchScreen(Constant.internalPath),
                      );
                    },
                    icon: Icon(Icons.search),
                  ),
                ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final file = data[index];
                  final fileName = file.path.split("/").last;
                  return ListTile(
                    leading: FutureBuilder<Uint8List?>(
                      future: ThumbnailService.getSmartThumbnail(file.path),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData &&
                            snapshot.data != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              snapshot.data!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return CircleAvatar(
                            child: Icon(MediaUtils.getIconForMedia(file.type)),
                          );
                        }
                      },
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
                                  ).then((_) {
                                    _refreshData();
                                    widget.onOperationDone?.call();
                                  });
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
                separatorBuilder: (BuildContext context, int index) {
                  return Divider();
                },
              ),
      ),
    );
  }
}
