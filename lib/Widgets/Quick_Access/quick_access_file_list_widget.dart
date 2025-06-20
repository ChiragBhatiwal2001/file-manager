import 'package:file_manager/Widgets/Quick_Access/quick_access_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';

class QuickAccessFileList extends StatelessWidget {
  final List<MediaFile> data;
  final bool isLoading;
  final ValueNotifier<Set<String>> selectedPaths;
  final Function(String? path) getDataForDisplay;
  final dynamic selectionState;
  final dynamic selectionNotifier;


  const QuickAccessFileList({
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
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedPaths,
      builder: (context, selected, _) {
        return ListView.separated(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final file = data[index];
            return QuickAccessListItem(
              file: file,
              selectionState: selectionState,
              selectionNotifier: selectionNotifier,
              getDataForDisplay: getDataForDisplay,
            );
          },
          separatorBuilder: (context, index) => const Divider(),
        );
      },
    );
  }
}
