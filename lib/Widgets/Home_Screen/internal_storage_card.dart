import 'package:flutter/material.dart';

class InternalStorageCard extends StatelessWidget {
  final VoidCallback onTap;
  const InternalStorageCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        color: theme.colorScheme.primaryContainer,
        child: Container(
          width: double.infinity,
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Icon(Icons.sd_storage, size: 36, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              const Text(
                "Internal Storage",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}