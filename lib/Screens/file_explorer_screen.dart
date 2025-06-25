import 'dart:math';

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

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> with RouteAware {
  late String _startingPath;

  @override
  void initState() {
    super.initState();
    _startingPath = widget.initialPath ?? Constant.internalPath!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.microtask(() {
      ref.read(fileExplorerProvider(_startingPath).notifier).loadAllContentOfPath(_startingPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = ref.watch(currentPathProvider);
    final providerInstance = fileExplorerProvider(currentPath);
    final explorerState = ref.watch(providerInstance);
    final notifier = ref.read(providerInstance.notifier);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final viewMode = ref.watch(fileViewModeProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
          return;
        }

        if (!didPop && explorerState.currentPath != Constant.internalPath) {
          if (!mounted) return;
          await notifier.goBack(context, ref); // pass ref to notifier!
        } else if (!didPop && explorerState.currentPath == Constant.internalPath) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },

      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(104.0),
          child: FileExplorerAppBar(initialPath: currentPath),
        ),
        body: explorerState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewMode == "List View"
            ? FileExplorerBody(providerInstance: providerInstance)
            : FileExplorerGridBody(providerInstance: providerInstance),
      ),
    );
  }
}
