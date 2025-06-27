import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FolderListWidget extends StatelessWidget {
  final List<FileSystemEntity> folders;
  final void Function(String path) onTap;
  final Set<String> selectedPaths;

  const FolderListWidget({
    super.key,
    required this.folders,
    required this.onTap,
    required this.selectedPaths,
  });

  bool isRestricted(String path) {
    return path.contains("/Android/data") || path.contains("/Android/obb");
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final folder = folders[index];
        final path = folder.path;
        final name = p.basename(path);
        final isSelected = selectedPaths.contains(path);
        final isRestrictedFolder = isRestricted(path);
        final isDisabled = isSelected || isRestrictedFolder;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isDisabled ? Colors.grey.shade300 : null,
            child: Icon(Icons.folder, color: isDisabled ? Colors.brown : null),
          ),
          title: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: isDisabled ? Colors.brown : null),
          ),
          onTap: isDisabled ? null : () => onTap(path),
          enabled: !isDisabled, // also dims and disables ripple
        );
      }, childCount: folders.length),
    );
  }
}
