import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'file_grid_tile.dart';

class FileExplorerGridBody extends ConsumerWidget {
  final StateNotifierProvider<FileExplorerNotifier, FileExplorerState>
  providerInstance;

  const FileExplorerGridBody({super.key, required this.providerInstance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(providerInstance);
    final notifier = ref.read(providerInstance.notifier);

    final folders = currentState.folders;
    final files = currentState.files;

    if (folders.isEmpty && files.isEmpty) {
      return const ScreenEmptyWidget();
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (folders.isNotEmpty) ...[
          const _SectionHeader(title: 'Folders'),
          _buildGrid(folders, true, notifier),
        ],
        if (files.isNotEmpty) ...[
          const _SectionHeader(title: 'Files'),
          _buildGrid(files, false, notifier),
        ],
      ],
    );
  }

  Widget _buildGrid(List entities, bool isFolder, FileExplorerNotifier notifier) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: entities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) => FileGridTile(
        entity: entities[index],
        isFolder: isFolder,
        notifier: notifier,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.indigoAccent,
        ),
      ),
    );
  }
}