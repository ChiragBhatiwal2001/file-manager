import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final FocusNode focusNode;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 5.0),
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
