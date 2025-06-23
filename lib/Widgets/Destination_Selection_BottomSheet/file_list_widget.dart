import 'dart:io';
import 'package:flutter/material.dart';

class FileListWidget extends StatelessWidget {
  final List<FileSystemEntity> files;

  const FileListWidget({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final file = files[index];
          final name = file.path.split(Platform.pathSeparator).last;

          return ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.blueGrey),
            title: Text(name, overflow: TextOverflow.ellipsis),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text("Invalid Operation"),
                  content: Text("You are in selection mode."),
                ),
              );
            },
          );
        },
        childCount: files.length,
      ),
    );
  }
}
