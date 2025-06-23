import 'package:flutter/material.dart';

class PasteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PasteButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          onPressed: onPressed,
          child: const Text("Paste Here", style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}
