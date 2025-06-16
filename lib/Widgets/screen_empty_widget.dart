import 'package:flutter/material.dart';

class ScreenEmptyWidget extends StatelessWidget {
  const ScreenEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'This directory is empty',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}