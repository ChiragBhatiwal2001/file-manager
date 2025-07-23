import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Widgets/Recent_Added_Files/recent_added_tile.dart';
import 'package:flutter/material.dart';

class RecentAddedBody extends StatelessWidget {
  final List<MediaFile> files;
  final bool isLoading;
  final bool isGrid;
  final Future<void> Function([String?]) onRefresh;

  const RecentAddedBody({
    required this.files,
    required this.isLoading,
    required this.isGrid,
    required this.onRefresh,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return isGrid
        ? GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => RecentAddedTile(
        file: files[index],
        isGrid: true,
        onRefresh:  ([String? s]) => onRefresh(s),
      ),
    )
        : ListView.separated(
      itemCount: files.length,
      itemBuilder: (context, index) => RecentAddedTile(
        file: files[index],
        isGrid: false,
        onRefresh: ([String? s]) => onRefresh(s),
      ),
      separatorBuilder: (_, __) => const Divider(),
    );
  }
}
