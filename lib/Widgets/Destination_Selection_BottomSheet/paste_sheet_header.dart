import 'package:flutter/material.dart';

class PasteSheetHeader extends StatelessWidget {
  final String currentPath;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  const PasteSheetHeader({
    super.key,
    required this.currentPath,
    required this.onBack,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final currentName = currentPath.split("/").last == "0" ? "All Files" : currentPath.split("/").last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          TextButton(onPressed: onBack, child: const Text("Back")),
          const Spacer(),
          Text(currentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(onPressed: onCreate, child: const Text("Create")),
        ],
      ),
    );
  }
}
