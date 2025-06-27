import 'dart:io';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';

class FavoriteScreen extends ConsumerWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final validFavorites = favorites.where((path) {
      return FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
    }).toList();

    final invalidPaths = favorites.toSet().difference(validFavorites.toSet());
    if (invalidPaths.isNotEmpty) {
      Future.microtask(() {
        ref
            .read(favoritesProvider.notifier)
            .removeFavorites(invalidPaths.toList());
      });
    }

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
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Are you Sure ?"),
                    content: Text("Removed All Content from Favorites."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("No"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(favoritesProvider.notifier)
                              .clearFavorites();
                          Navigator.pop(context);
                          Fluttertoast.showToast(msg: "All Favorites Removed");
                        },
                        child: Text("Yes"),
                      ),
                    ],
                  ),
                );
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
                      if (context.mounted) {
                        Fluttertoast.showToast(
                          msg: "${p.basename(path)} Remove from Favorites",
                        );
                      }
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
