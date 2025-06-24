// detail_helpers.dart (updated)

import 'package:flutter/material.dart';
import 'package:file_manager/Services/get_meta_data.dart';

Widget detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

Future<void> showErrorDialog(BuildContext context, String message) async {
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Operation Failed"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

Future<void> showDetailsDialog(BuildContext context, String path) async {
  final data = await getMetadata(path);
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Properties"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          detailRow("Name", data["Name"] ?? ""),
          detailRow("Path", data["Path"] ?? ""),
          detailRow("Type", data["Type"] ?? ""),
          detailRow("Last Modified", data["Modified"] ?? ""),
          detailRow("Size", data["Size"] ?? ""),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Okay"),
        ),
      ],
    ),
  );
}
