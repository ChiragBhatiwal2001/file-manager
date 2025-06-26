import 'dart:io';
import 'package:flutter/material.dart';

Future<void> renameDialogBox({
  required BuildContext context,
  required String oldPath,
  required VoidCallback onSuccess,
}) async {
  final isDir = FileSystemEntity.isDirectorySync(oldPath);
  final oldName = oldPath.split("/").last;
  final renameTextController = TextEditingController(text: oldName);
  final focusNode = FocusNode();

  await showDialog(
    context: context,
    builder: (context) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        focusNode.requestFocus();
      });
      return AlertDialog(
        title: Text(isDir ? "Rename Folder" : "Rename File"),
        content: TextField(
          focusNode: focusNode,
          controller: renameTextController,
          decoration: InputDecoration(
            label: Text("Name"),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newName = renameTextController.text.trim();
              if (newName.isEmpty || newName == oldName) {
                if (context.mounted) Navigator.pop(context);
                return;
              }

              final parentDir = Directory(oldPath).parent.path;
              final newPath = "$parentDir/$newName";

              try {
                final entity = isDir ? Directory(oldPath) : File(oldPath);
                await entity.rename(newPath);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                onSuccess();
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Rename failed: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text("Confirm"),
          ),
        ],
      );
    },
  );
}
