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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchFilesAndDirectories();
  }

  void _fetchFilesAndDirectories() async {
    await Permission.manageExternalStorage.request();

    String internalStoragePath = "storage/emulated/0/";

    List<FileSystemEntity> internalList = Directory(internalStoragePath).listSync();

    setState(() {
      internalStorageData = internalList;
    });
  }

  Widget showingFiles(List<FileSystemEntity> files){

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
            showingFiles(internalStorageData),
            Center(child: Text("Internal Storage")),
          ],
        ),
      ),
    );
  }
}
