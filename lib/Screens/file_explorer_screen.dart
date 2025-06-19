import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_appbar.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';

class FileExplorerScreen extends ConsumerStatefulWidget {
  const FileExplorerScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen>
    with RouteAware {
  late final providerInstance;

  @override
  void initState() {
    super.initState();
    providerInstance = fileExplorerProvider(
      widget.initialPath ?? Constant.internalPath,
    );
  }

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() {
      ref
          .read(fileExplorerProvider(widget.initialPath).notifier)
          .loadAllContentOfPath(widget.initialPath!);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorerState = ref.watch(providerInstance);
    final notifier = ref.watch(providerInstance.notifier);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
          return;
        }
        if (!didPop && explorerState.currentPath != Constant.internalPath) {
          if (!mounted) return;
          await notifier.goBack(explorerState.currentPath, context);
        } else if (!didPop && explorerState.currentPath == Constant.internalPath) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(104.0),
          child: FileExplorerAppBar(initialPath: widget.initialPath),
        ),
        body: explorerState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : FileExplorerBody(providerInstance: providerInstance),
      ),
    );
  }
}
