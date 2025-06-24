import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileListWidget extends StatelessWidget {
  final List<FileSystemEntity> files;
  final Set<String> selectedPaths;

  const FileListWidget({
    super.key,
    required this.files,
    required this.selectedPaths,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final file = files[index];
          final path = file.path;
          final name = p.basename(path);
          final isSelected = selectedPaths.contains(path);

          return ListTile(
            leading: Icon(
              Icons.insert_drive_file,
              color: isSelected ? Colors.grey : Colors.blueGrey,
            ),
            title: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.grey : null,
              ),
            ),

            enabled: !isSelected,
            onTap: isSelected
                ? null
                : () {
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
