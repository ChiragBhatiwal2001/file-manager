import 'package:file_manager/Widgets/Quick_Access/quick_access_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';

class QuickAccessFileGrid extends StatelessWidget {
  final List<MediaFile> data;
  final bool isLoading;
  final ValueNotifier<Set<String>> selectedPaths;
  final Function(String? path) getDataForDisplay;
  final dynamic selectionState;
  final dynamic selectionNotifier;

  const QuickAccessFileGrid({
    super.key,
    required this.data,
    required this.isLoading,
    required this.selectedPaths,
    required this.getDataForDisplay,
    required this.selectionState,
    required this.selectionNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "No files found",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final file = data[index];
        return QuickAccessGridItem(
          file: file,
          getDataForDisplay: getDataForDisplay,
        );
      },
    );
  }
}