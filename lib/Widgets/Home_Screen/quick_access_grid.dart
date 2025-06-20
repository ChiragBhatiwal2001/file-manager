import 'package:flutter/material.dart';
import 'package:file_manager/Utils/MediaUtils.dart';

class QuickAccessGrid extends StatelessWidget {
  final Map<MediaType, IconData> mediaTypes;
  final Future<bool> Function() requestPermissions;
  final Future<void> Function() getStoragePath;
  final String? internalStorage;
  final Future<void> Function(MapEntry<MediaType, IconData> media, BuildContext context) onMediaTap;

  const QuickAccessGrid({
    super.key,
    required this.mediaTypes,
    required this.requestPermissions,
    required this.getStoragePath,
    required this.internalStorage,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Optionally, show a loading indicator if internalStorage is null
    if (internalStorage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: mediaTypes.length,
        itemBuilder: (context, index) {
          final media = mediaTypes.entries.toList()[index];
          return GestureDetector(
            onTap: () async => await onMediaTap(media, context),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    media.value,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    media.key.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}