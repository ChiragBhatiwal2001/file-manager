import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Utils/drag_ordering_enum_file_explorer.dart';
import 'package:file_manager/Widgets/File_Explorer/manual_order_list.dart';
import 'package:file_manager/Widgets/File_Explorer/normal_list.dart';
import 'package:file_manager/Widgets/File_Explorer/order_list.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileExplorerBody extends ConsumerStatefulWidget {
  const FileExplorerBody({super.key});

  @override
  ConsumerState<FileExplorerBody> createState() => _FileExplorerBodyState();
}

class _FileExplorerBodyState extends ConsumerState<FileExplorerBody> {
  List<ExplorerItem> _reorderedItems = [];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileExplorerProvider);
    final sortValue = state.sortValue;
    final isInDragMode = ref.watch(manualDragModeProvider);
    final isManualSort = sortValue == "drag";

    final hiddenState = ref.watch(hiddenPathsProvider);
    final showHidden = hiddenState.showHidden;
    final hiddenPaths = hiddenState.hiddenPaths;

    final visibleFolders = state.folders
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();
    final visibleFiles = state.files
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();

    if (visibleFolders.isEmpty && visibleFiles.isEmpty) {
      return const ScreenEmptyWidget();
    }

    if (_reorderedItems.isEmpty) {
      _reorderedItems = buildItemList(visibleFolders, visibleFiles);
    }

    if (isManualSort && isInDragMode) {
      return ManualReorderListView(initialItems: _reorderedItems);
    }

    return NormalExplorerListView(folders: visibleFolders, files: visibleFiles);
  }
}
