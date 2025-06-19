import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:file_manager/Screens/favorite_screen.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Screens/quick_access_screen.dart';
import 'package:file_manager/Screens/recent_added_screen.dart';
import 'package:file_manager/Screens/recently_deleted_screen.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Widgets/container_home_widget.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/services.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? internalStorage;

  @override
  void initState() {
    super.initState();
    RecentlyDeletedManager().init();
  }

  Future<bool> _requestAllMediaPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt < 29) {
      final status = await Permission.storage.request();
      return status.isGranted;
    } else {
      final permissions = [
        Permission.manageExternalStorage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];
      final statuses = await permissions.request();
      return statuses.values.every((status) => status.isGranted);
    }
  }

  Future<void> getStoragePath() async {
    final path = await ExternalPath.getExternalStorageDirectories();
    internalStorage = path![0];
    Constant.internalPath = internalStorage!;
  }

  void checkForPermissions() async {
    final isGranted = await _requestAllMediaPermissions();
    if (!isGranted && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please grant all permissions to continue.'),
        ),
      );
    }
  }

  final mediaTypes = {
    MediaType.image: Icons.image,
    MediaType.video: Icons.video_library,
    MediaType.audio: Icons.music_note,
    MediaType.document: Icons.insert_drive_file,
    MediaType.apk: Icons.android,
  };

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final topFavorites = favorites.take(4).toList();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "File-Manager",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () async {
              await getStoragePath();
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => SearchScreen(internalStorage!),
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Internal Storage Section
              GestureDetector(
                onTap: () async {
                  final isGranted = await _requestAllMediaPermissions();
                  if (!isGranted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please grant all permissions to continue.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  await getStoragePath();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FileExplorerScreen(
                        initialPath: Constant.internalPath,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  color: theme.colorScheme.primaryContainer,
                  child: Container(
                    width: double.infinity,
                    height: 90,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sd_storage,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Internal Storage",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Quick Access Section Header
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  "Quick Access",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
              // Media Categories Grid
              SizedBox(
                width: double.infinity,
                height: 220,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: mediaTypes.length,
                  itemBuilder: (context, index) {
                    final media = mediaTypes.entries.toList()[index];
                    return GestureDetector(
                      onTap: () async {
                        final isGranted = await _requestAllMediaPermissions();
                        if (!isGranted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please grant all permissions to continue.',
                              ),
                            ),
                          );
                          return;
                        }
                        await getStoragePath();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuickAccessScreen(
                              category: media.key,
                              storagePath: internalStorage!,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              media.value,
                              size: 36,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              media.key.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              // Utility Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    ContainerHomeScreen(
                      title: "Recent Files",
                      icon: Icons.file_download_sharp,
                      onTap: () async {
                        checkForPermissions();
                        await getStoragePath();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecentAddedScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    ContainerHomeScreen(
                      title: "RecyclerBin",
                      icon: Icons.delete,
                      onTap: () async {
                        checkForPermissions();
                        await getStoragePath();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecentlyDeletedScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
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
                      Consumer(
                        builder: (context, ref, _) {
                          final favorites = ref.watch(favoritesProvider);
                          final topFavorites = favorites.take(4).toList();
                          if (topFavorites.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Center(child: Text("No favorites yet.")),
                            );
                          }
                          return Row(
                            children: List.generate(4, (index) {
                              if (index >= topFavorites.length) {
                                return Expanded(child: SizedBox());
                              }
                              final path = topFavorites[index];
                              final name = path.split("/").last;
                              final isDir = FileSystemEntity.isDirectorySync(
                                path,
                              );
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final isGranted = await _requestAllMediaPermissions();
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
                                          builder: (context) =>
                                              FileExplorerScreen(
                                                initialPath:path,
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
                                            isDir
                                                ? Icons.folder
                                                : Icons.insert_drive_file,
                                            size: 28,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final isGranted = await _requestAllMediaPermissions();
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoriteScreen(),
                              ),
                            );
                          },
                          child: const Text("Show More"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
