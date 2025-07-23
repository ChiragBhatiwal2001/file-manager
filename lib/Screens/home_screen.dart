import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_manager/Screens/favorite_screen.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:file_manager/Screens/quick_access_screen.dart';
import 'package:file_manager/Screens/setting_screen.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Widgets/Home_Screen/favorites_section.dart';
import 'package:file_manager/Widgets/Home_Screen/internal_storage_card.dart';
import 'package:file_manager/Widgets/Home_Screen/quick_access_grid.dart';
import 'package:file_manager/Widgets/Home_Screen/utility_section.dart';
import 'package:file_manager/Widgets/Search_Bottom_Sheet/search_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _initStoragePath();
  }

  void _initStoragePath() async {
    await getStoragePath();
    await RecentlyDeletedManager().init();
    if (mounted) setState(() {});
  }

  Future<bool> _requestAllMediaPermissions() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt < 23) {
      return true;
    }

    if (sdkInt < 29) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }

    if (sdkInt >= 29 && sdkInt < 33) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      await openAppSettings();
      return false;
    }

    if (sdkInt >= 33) {
      final permissions = [
        Permission.manageExternalStorage,
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];

      final statuses = await permissions.request();
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) await openAppSettings();

      if (allGranted) {
        await RecentlyDeletedManager().init();
      }
      return allGranted;
    }
    return false;
  }

  Future<void> getStoragePath() async {
    final path = await ExternalPath.getExternalStorageDirectories();
    internalStorage = path![0];
    Constant.internalPath = internalStorage!;
  }

  final mediaTypes = {
    MediaType.image: Icons.image,
    MediaType.video: Icons.video_library,
    MediaType.audio: Icons.music_note,
    MediaType.document: Icons.insert_drive_file,
    MediaType.apk: Icons.android,
  };

  void _showPermissionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please grant all permissions to continue.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
              if (!await _requestAllMediaPermissions()) {
                _showPermissionSnackBar(context);
                return;
              }
              await getStoragePath();
              showModalBottomSheet(
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                builder: (context) => SearchBottomSheet(internalStorage!),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen(),));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InternalStorageCard(
                onTap: () async {
                  if (!await _requestAllMediaPermissions()) {
                    _showPermissionSnackBar(context);
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
              ),
              const SizedBox(height: 18),
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
              QuickAccessGrid(
                mediaTypes: mediaTypes,
                requestPermissions: _requestAllMediaPermissions,
                getStoragePath: getStoragePath,
                internalStorage: internalStorage,
                onMediaTap: (media, context) async {
                  if (!await _requestAllMediaPermissions()) {
                    _showPermissionSnackBar(context);
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
              ),
              const SizedBox(height: 18),
              // Section For Recycler Bin and Recently Added Files.
              UtilitySections(
                requestPermissions: _requestAllMediaPermissions,
                getStoragePath: getStoragePath,
              ),
              FavoritesSection(
                requestPermissions: _requestAllMediaPermissions,
                getStoragePath: getStoragePath,
                onShowMore: () async {
                  if (!await _requestAllMediaPermissions()) {
                    _showPermissionSnackBar(context);
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
