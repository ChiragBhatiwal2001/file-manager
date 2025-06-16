import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:flutter/material.dart';

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() {
    return _RecentlyDeletedScreenState();
  }
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  List<Map<String, dynamic>> deletedItems = [];

  @override
  void initState() {
    super.initState();
    _getDeletedData();
  }

  void _getDeletedData() async {
    List<Map<String, dynamic>> list = await RecentlyDeletedManager()
        .getDeletedItems();
    setState(() {
      deletedItems = list;
    });
  }

  void _deleteDataPermanently(String trashedPath) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Delete Permanently?"),
        action: SnackBarAction(
          label: "Yes",
          onPressed: () async {
            await RecentlyDeletedManager().permanentlyDelete(trashedPath);
            setState(() {});
            _getDeletedData();
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recycler Bin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        titleSpacing: 0,
        actions: [
          if (deletedItems.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Delete Permanently?"),
                    action: SnackBarAction(
                      label: "Yes",
                      onPressed: () async {
                        await RecentlyDeletedManager().deleteAll();
                        setState(() {});
                        _getDeletedData();
                      },
                    ),
                    duration: Duration(seconds: 5),
                  ),
                );
              },
              label: Text("Delete All"),
              icon: Icon(Icons.delete_forever_rounded),
            ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: deletedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Recycle Bin is empty',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: deletedItems.length,
              itemBuilder: (context, index) {
                final item = deletedItems[index];
                final trashedPath = item['trashedPath'];
                final originalPath = item['originalPath'];
                final isDir =
                    FileSystemEntity.typeSync(trashedPath) ==
                    FileSystemEntityType.directory;

                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                  title: Text(p.basename(originalPath)),
                  subtitle: Text(
                    "From: $originalPath",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.restore),
                        onPressed: () async {
                          await RecentlyDeletedManager().restoreFromTrash(
                            trashedPath,
                          );
                          setState(() {});
                          _getDeletedData(); // refresh list
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever),
                        onPressed: () {
                          _deleteDataPermanently(trashedPath);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}