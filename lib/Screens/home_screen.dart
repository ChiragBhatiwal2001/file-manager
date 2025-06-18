import 'package:file_manager/Screens/favorite_screen.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Screens/quick_access_screen.dart';
import 'package:file_manager/Screens/recent_added_screen.dart';
import 'package:file_manager/Screens/recently_deleted_screen.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Widgets/container_home_widget.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? internalStorage;
  static const _channel = MethodChannel('com.example.file_manager/storage');

  @override
  void initState() {
    super.initState();
    RecentlyDeletedManager().init();
  }

  Future<bool> _requestAllMediaPermissions() async {
    final permissions = [
      Permission.manageExternalStorage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ];
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> getStoragePath() async {
    final path = await _channel.invokeMethod<String>('getInternalStoragePath');
    internalStorage = path;
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
                      title: "Favorites",
                      icon: Icons.favorite,
                      onTap: () async {
                        checkForPermissions();
                        await getStoragePath();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, color: Colors.grey),
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
            ],
          ),
        ),
      ),
    );
  }
}
