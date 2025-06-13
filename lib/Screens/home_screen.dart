import 'package:external_path/external_path.dart';
import 'package:file_manager/Screens/favorite_screen.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Screens/quick_access_screen.dart';
import 'package:file_manager/Screens/recently_deleted_screen.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/recent_added_screen.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Widgets/container_home_widget.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String? internalStorage;

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
    if(Platform.)
    final internalStoragePath =
        await ExternalPath.getExternalStorageDirectories();
    for (var storage in internalStoragePath!) {
      if (storage.contains("emulated")) {
        internalStorage = storage;
        Constant.internalPath = internalStorage!;
        break;
      }
    }
  }

  void checkForPermissions() async {
    final isGranted = await _requestAllMediaPermissions();
    if (!isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please grant all permissions to continue.')),
        );
      }

      return;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "File-Manager",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
            icon: Icon(Icons.search),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final isGranted = await _requestAllMediaPermissions();
                if (!isGranted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
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
                    builder: (context) =>
                        FileExplorerScreen(path: internalStorage!),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.only(left: 8.0, top: 5.0),
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Text(
                    "Internal Storage",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 250,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: mediaTypes.length,
                itemBuilder: (context, index) {
                  final media = mediaTypes.entries.toList()[index];
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: GestureDetector(
                      onTap: () async {
                        final isGranted = await _requestAllMediaPermissions();
                        if (!isGranted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(media.value, size: 40),
                            SizedBox(height: 10),
                            Text(media.key.name.toUpperCase()),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8.0),
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
                    Divider(height: 1, color: Colors.grey),
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
                    Divider(height: 1, color: Colors.grey),
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
            ),
          ],
        ),
      ),
    );
  }
}
