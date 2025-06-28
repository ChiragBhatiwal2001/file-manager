import 'dart:io';
import 'package:file_manager/Helpers/get_unique_name.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

Future<void> addFolderDialog({
  required BuildContext context,
  required String parentPath,
  required VoidCallback onSuccess,
}) async {
  final initialSuggestedPath = await getUniqueDestinationPath("$parentPath/New Folder");
  final suggestedName = p.basename(initialSuggestedPath);
  final controller = TextEditingController(text: suggestedName);

  await showDialog(
    context: context,
    builder: (context) {
      final focusNode = FocusNode();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
        focusNode.requestFocus();
      });

      return AlertDialog(
        title: const Text("Add New Folder"),
        content: TextField(
          focusNode: focusNode,
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => controller.clear(),
            ),
            label: const Text("Folder Name"),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String folderName = controller.text.trim().isEmpty
                  ? "New Folder"
                  : controller.text.trim();

              final originalPath = "$parentPath/$folderName";
              final uniquePath = await getUniqueDestinationPath(originalPath);

              await Directory(uniquePath).create(recursive: false);
              if (context.mounted) Navigator.pop(context);
              onSuccess();
            },
            child: const Text("Create"),
          ),
        ],
      );
    },
  );
}
