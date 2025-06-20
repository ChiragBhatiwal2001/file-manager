import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:open_filex/open_filex.dart';

class FavoritesSection extends ConsumerWidget {
  final Future<bool> Function() requestPermissions;
  final Future<void> Function() getStoragePath;
  final Future<void> Function() onShowMore; // <-- Fixed type

  const FavoritesSection({
    super.key,
    required this.requestPermissions,
    required this.getStoragePath,
    required this.onShowMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final topFavorites = favorites.take(4).toList();
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Favorites",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 10),
            if (topFavorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text("No favorites yet.")),
              )
            else
              Row(
                children: List.generate(4, (index) {
                  if (index >= topFavorites.length) {
                    return const Expanded(child: SizedBox());
                  }
                  final path = topFavorites[index];
                  final name = path.split("/").last;
                  final isDir = FileSystemEntity.isDirectorySync(path);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final isGranted = await requestPermissions();
                        if (!isGranted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please grant all permissions to continue.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        await getStoragePath();
                        if (isDir) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FileExplorerScreen(
                                initialPath: path,
                              ),
                            ),
                          );
                        } else {
                          OpenFilex.open(path);
                        }
                      },
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDir ? Icons.folder : Icons.insert_drive_file,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await onShowMore();
                },
                child: const Text("Show More"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}