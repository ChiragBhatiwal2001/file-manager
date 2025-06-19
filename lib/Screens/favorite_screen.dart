import 'dart:io';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text("Favorites", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          if (favorites.isNotEmpty)
            TextButton(
              onPressed: () async {
                await ref.read(favoritesProvider.notifier).clearFavorites();
              },
              child: Text("Clear All"),
            ),
        ],
      ),
      body: favorites.isNotEmpty
          ? ReorderableListView.builder(
        itemCount: favorites.length,
        onReorder: (oldIndex, newIndex) async {
          await ref
              .read(favoritesProvider.notifier)
              .reorderFavorites(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final path = favorites[index];
          final name = path.split("/").last;
          final isDir = FileSystemEntity.isDirectorySync(path);
          return ListTile(
            key: ValueKey(path),
            title: Text(name),
            subtitle: Text(path, maxLines: 2),
            leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
            onTap: () {
              if (isDir) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FileExplorerScreen(initialPath: path),
                  ),
                );
              } else {
                OpenFilex.open(path);
              }
            },
            trailing: IconButton(
              icon: Icon(Icons.favorite, color: Colors.red),
              onPressed: () async {
                await ref
                    .read(favoritesProvider.notifier)
                    .toggleFavorite(path, isDir);
              },
            ),
          );
        },
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 100),
          const SizedBox(height: 20),
          Text(
            'No Favorites Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Mark files or folders as favorite to see them here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}