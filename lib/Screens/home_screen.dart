import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {

  List<FileSystemEntity> internalStorageData = [];
  List<FileSystemEntity> externalStorageData = [];
  bool _isExternalStorageFound = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchFilesAndDirectories();
  }

  void _fetchFilesAndDirectories() async {
    await Permission.manageExternalStorage.request();

    String internalStoragePath = "storage/emulated/0/";
    String? externalStoragePath;

    //For Internal Storage
    List<FileSystemEntity> internalList = Directory(internalStoragePath).listSync();

    //For External Storage like sd-card
    Directory root = Directory("/storage/");
    List<FileSystemEntity> entries = root.listSync();
    for (var entity in entries) {
      String name = entity.path.split("/").last;
      if (name.contains("-")) {
        externalStoragePath = entity.path;
        break;
      }
    }

    List<FileSystemEntity> externalList =
    externalStoragePath != null ? Directory(externalStoragePath).listSync() : [];

    setState(() {
      externalStoragePath == null ? _isExternalStorageFound = false : _isExternalStorageFound = true;
      internalStorageData = internalList;
      externalStorageData = externalList;
    });
  }

  Widget showingFiles(List<FileSystemEntity> files, int index){

    if(!_isExternalStorageFound && index == 1){
      return Center(child: Text("No External Storage Found",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),);
    }

    if(files.isEmpty) return Center(child: Text("No Files Found",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),),);

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
       final file = files[index];
       final fileName = file.path.split("/").last;
       final isDir = FileSystemEntity.isDirectorySync(file.path);
       return ListTile(
         leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
         title: Text(fileName),
       );
    },);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              "Files",
              style: const TextStyle(
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
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
            showingFiles(internalStorageData,0),
            showingFiles(externalStorageData,1),
          ],
        ),
      ),
    );
  }
}
