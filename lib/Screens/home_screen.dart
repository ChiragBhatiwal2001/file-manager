import 'dart:io';
import 'package:file_manager/Screens/file_explorer_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<FileSystemEntity> _externalStorageData = [];
  List<FileSystemEntity> _internalStorageData = [];
  bool _isExternalStoragePresent = false;

  @override
  void initState() {
    super.initState();
    _initStorageAccess();
  }

  Future<void> _initStorageAccess() async {
    await _requestStoragePermissions();
    await _getAllFilesAndFolders();
  }

  Future<void> _requestStoragePermissions() async {
    final status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      final result = await Permission.manageExternalStorage.request();
      if (!result.isGranted) {
        await openAppSettings();
      }
    }
  }

  Future<List<FileSystemEntity>> _getInternalStorage() async {
    try {
      final dir = Directory("/storage/emulated/0/");
      if (await dir.exists()) {
        return await dir.list().toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Internal Storage Error: $e")));
      }
    }
    return [];
  }

  Future<List<FileSystemEntity>> _getExternalStorage() async {
    try {
      final entries = Directory("/storage/").listSync();

      for (final entity in entries) {
        final name = entity.path.split("/").last;
        if (!["emulated", "self", "enc-emulated"].contains(name)) {
          final dir = Directory(entity.path);
          if (await dir.exists()) {
            _isExternalStoragePresent = true;
            return await dir.list().toList();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("External Storage Error: $e")));
      }
    }

    _isExternalStoragePresent = false;
    return [];
  }

  Future<void> _getAllFilesAndFolders() async {
    final internal = await _getInternalStorage();
    final external = await _getExternalStorage();

    if (mounted) {
      setState(() {
        _internalStorageData = internal;
        _externalStorageData = external;
      });
    }
  }

  Widget _buildFileList(List<FileSystemEntity> files, int tabIndex) {
    if (tabIndex == 1 && !_isExternalStoragePresent) {
      return Center(
        child: Text(
          "No External Storage Found.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    if (files.isEmpty) {
      return Center(
        child: Text(
          "Storage Is Empty",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = file.path.split("/").last;
        final isDir = FileSystemEntity.isDirectorySync(file.path);
        return ListTile(
          leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
          title: Text(fileName),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FileExplorerScreen()),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Files",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: "Internal"),
              Tab(text: "External"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FileExplorerScreen(path: "/storage/emulated/0/"),
            _buildFileList(_externalStorageData, 1),
          ],
        ),
      ),
    );
  }
}
