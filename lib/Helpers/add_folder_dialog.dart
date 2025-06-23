import 'dart:io';
import 'package:flutter/material.dart';

Future<void> addFolderDialog({
  required BuildContext context,
  required String parentPath,
  required VoidCallback onSuccess,
}) async {
  final controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add New Folder"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            label: Text("Folder Name"),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final folderName = controller.text.trim();
              final newPath = "$parentPath/$folderName";
              if (Directory(newPath).existsSync()) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Folder with this name already exist"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Okay"),
                      ),
                    ],
                  ),
                );
              } else {
                await Directory(newPath).create(recursive: false);
                if (context.mounted) Navigator.pop(context);
                onSuccess();
              }
            },
            child: Text("Create"),
          ),
        ],
      );
    },
  );
}
