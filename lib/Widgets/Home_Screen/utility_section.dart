import 'package:file_manager/Screens/recent_added_screen.dart';
import 'package:file_manager/Screens/recently_deleted_screen.dart';
import 'package:flutter/material.dart';

class UtilitySections extends StatelessWidget {
  const UtilitySections({
    super.key,
    required this.requestPermissions,
    required this.getStoragePath,
  });

  final Future<bool> Function() requestPermissions;
  final Future<void> Function() getStoragePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            final isGranted = await requestPermissions();
            if (!isGranted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please grant all permissions to continue.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            await getStoragePath();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecentAddedScreen()),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.history, size: 32),
                  SizedBox(width: 12),
                  Text(
                    "Recent Files",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),

        GestureDetector(
          onTap: () async {
            final isGranted = await requestPermissions();
            if (!isGranted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Please grant all permissions to continue.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            await getStoragePath();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecentlyDeletedScreen()),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: const [
                  Icon(Icons.delete, size: 32),
                  SizedBox(width: 12),
                  Text(
                    "Recycler Bin",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
