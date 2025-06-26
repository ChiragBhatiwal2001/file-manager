import 'dart:io';
import 'package:flutter/material.dart';

Future<void> addFolderDialog({
  required BuildContext context,
  required String parentPath,
  required VoidCallback onSuccess,
}) async {
  final controller = TextEditingController(text: "New Folder");

  await showDialog(
    context: context,
    builder: (context) {
      final focusNode = FocusNode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        focusNode.requestFocus();
      });
      return AlertDialog(
        title: Text("Add New Folder"),
        content: TextField(
          focusNode: focusNode,
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
              },
            ),
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
