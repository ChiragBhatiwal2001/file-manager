import 'package:flutter/material.dart';

Future<void> showAddFolderDialog({
  required BuildContext context,
  required TextEditingController controller,
  required VoidCallback onCreate,
}) async {
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
            onPressed: onCreate,
            child: Text("Create"),
          ),
        ],
      );
    },
  );
}