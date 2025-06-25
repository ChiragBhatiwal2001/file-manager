import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_appbar.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_body.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_grid_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';

class FileExplorerScreen extends ConsumerStatefulWidget {
  const FileExplorerScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> {
  @override
  void initState() {
    super.initState();
    final initPath = widget.initialPath ?? Constant.internalPath!;
    Future.microtask(() {
      ref.read(currentPathProvider.notifier).state = initPath;
      ref.read(fileExplorerProvider.notifier).loadAllContentOfPath(initPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = ref.watch(currentPathProvider);
    final explorerState = ref.watch(fileExplorerProvider);
    final notifier = ref.read(fileExplorerProvider.notifier);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final viewMode = ref.watch(fileViewModeProvider);
    final isInDragMode = ref.watch(manualDragModeProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
          return;
        }
        if (!didPop && explorerState.currentPath != Constant.internalPath) {
          if (!mounted) return;
          await notifier.goBack(context);
        } else if (!didPop &&
            explorerState.currentPath == Constant.internalPath) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(104.0),
          child: FileExplorerAppBar(
            providerInstance: fileExplorerProvider,
            currentPath: currentPath,
          ),
        ),
        body: explorerState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewMode == "List View"
            ? FileExplorerBody(providerInstance: fileExplorerProvider)
            : FileExplorerGridBody(providerInstance: fileExplorerProvider),
        floatingActionButton: isInDragMode
            ? FloatingActionButton(
                onPressed: () async {
                  ref.read(manualDragModeProvider.notifier).state = false;
                  await ref.read(fileExplorerProvider.notifier).loadAllContentOfPath(
                    ref.read(currentPathProvider),
                  );

                },
                child: Icon(Icons.clear),
              )
            : null,
      ),
    );
  }
}
