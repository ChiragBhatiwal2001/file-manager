import 'package:file_manager/Helpers/action_handlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';

class BodyForSingleFileOperation extends ConsumerStatefulWidget {
  const BodyForSingleFileOperation({
    super.key,
    required this.path,
    required this.loadAgain,
    required this.isChanged,
  });

  final String path;
  final void Function(String path) loadAgain;
  final bool isChanged;

  @override
  ConsumerState<BodyForSingleFileOperation> createState() => _BodyForSingleFileOperationState();
}

class _BodyForSingleFileOperationState extends ConsumerState<BodyForSingleFileOperation> {
  final Map<IconData, String> gridList = {
    Icons.copy: "Copy",
    Icons.cut: "Move",
    Icons.drive_file_rename_outline: "Rename",
    Icons.favorite: "Favorite",
    Icons.delete: "Delete",
    Icons.info_outline: "Details",
  };

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.path);

    final filteredEntries = widget.isChanged
        ? gridList.entries
        .map(
          (e) => MapEntry(
        e.key,
        e.value == "Favorite"
            ? (isFavorite ? "Remove Favorite" : "Mark Favorite")
            : e.value,
      ),
    )
        .toList()
        : gridList.entries
        .where((e) => e.value != "Copy" && e.value != "Move")
        .toList();

    return GridView.builder(
      itemCount: filteredEntries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemBuilder: (context, index) {
        final icon = filteredEntries[index].key;
        final action = filteredEntries[index].value;

        return Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => handleAction(
              context: context,
              ref: ref,
              action: action,
              path: widget.path,
              isFavorite: isFavorite,
              loadAgain: widget.loadAgain,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    action,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
