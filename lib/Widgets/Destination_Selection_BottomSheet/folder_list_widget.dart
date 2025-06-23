import 'dart:io';
import 'package:flutter/material.dart';

class FolderListWidget extends StatelessWidget {
  final List<FileSystemEntity> folders;
  final void Function(String path) onTap;

  const FolderListWidget({
    super.key,
    required this.folders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final folder = folders[index];
          final name = folder.path.split(Platform.pathSeparator).last;

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.folder)),
            title: Text(name, overflow: TextOverflow.ellipsis),
            onTap: () => onTap(folder.path),
          );
        },
        childCount: folders.length,
      ),
    );
  }
}
