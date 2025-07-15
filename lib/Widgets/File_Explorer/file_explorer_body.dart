import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/scroll_position_provider.dart';
import 'package:file_manager/Utils/drag_ordering_enum_file_explorer.dart';
import 'package:file_manager/Widgets/File_Explorer/manual_order_list.dart';
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
  late ScrollController _scrollController;
  late String _currentPath;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _currentPath = ref.read(currentPathProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = ref.read(scrollPositionProvider.notifier).getScrollOffset(_currentPath) ?? 0.0;

      if (_scrollController.hasClients && offset > 0.0) {
        _scrollController.jumpTo(offset);
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.hasClients &&
          !(ref.read(manualDragModeProvider) &&
              ref.read(fileExplorerProvider).sortValue == "drag")) {
        ref.read(scrollPositionProvider.notifier).saveScrollOffset(
          _currentPath,
          _scrollController.offset,
        );
      }
    });
  }

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

    _reorderedItems = buildItemList(visibleFolders, visibleFiles);

    return ManualReorderListView(
      key: ValueKey(_reorderedItems.map((e) => e.path).join(",")),
      initialItems: _reorderedItems,
      scrollController: _scrollController,
      isReorderMode: isInDragMode && isManualSort,
    );
  }
}
