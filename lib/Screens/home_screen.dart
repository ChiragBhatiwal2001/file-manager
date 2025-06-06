import 'package:external_path/external_path.dart';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
  }

  Future<bool> _requestPermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    if (await Permission.manageExternalStorage.isDenied) {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permission Required'),
            content: Text(
              'Please grant "All files access" in app settings to use the file manager.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        await openAppSettings();
        return false;
      }
      return false;
    }

    if (await Permission.storage.isDenied) {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Permission Required'),
            content: Text(
              'Please grant storage permission in app settings to use the file manager.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        await openAppSettings();
        return false;
      }
      return false;
    }

    return true;
  }

  Future<void> getStoragePath() async {
    final internalStoragePath =
        await ExternalPath.getExternalStorageDirectories();
    for (var storage in internalStoragePath!) {
      if (storage.contains("emulated")) {
        internalStorage = storage;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "File-Manager",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final isGranted = await _requestPermission();
                if (!isGranted) {
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
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Text("Internal Storage"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}