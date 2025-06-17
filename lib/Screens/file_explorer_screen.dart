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

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> {
  late final providerInstance;

  @override
  void initState() {
    super.initState();
    providerInstance = fileExplorerProvider(
      widget.initialPath ?? Constant.internalPath,
    );
  }

  @override
  void dispose() {
    ref.invalidate(providerInstance);
    ref.invalidate(fileExplorerProvider(Constant.internalPath));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final explorerState = ref.watch(providerInstance);
    final notifier = ref.watch(providerInstance.notifier);

    return PopScope(
      canPop: explorerState.currentPath == Constant.internalPath,
      onPopInvoked: (didPop) async {
        if (!didPop && explorerState.currentPath != Constant.internalPath) {
          await notifier.goBack(explorerState.currentPath, context);
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
