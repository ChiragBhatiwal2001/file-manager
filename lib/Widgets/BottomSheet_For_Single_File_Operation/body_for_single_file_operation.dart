import 'package:file_manager/Helpers/action_handlers.dart';
import 'package:file_manager/Utils/file_operations_enum.dart';
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
  ConsumerState<BodyForSingleFileOperation> createState() =>
      _BodyForSingleFileOperationState();
}

class _BodyForSingleFileOperationState
    extends ConsumerState<BodyForSingleFileOperation> {
  final Map<IconData, String> gridList = {
    Icons.copy: FileAction.copy.label,
    Icons.cut: FileAction.move.label,
    Icons.drive_file_rename_outline: FileAction.rename.label,
    Icons.favorite: FileAction.favorite.label,
    Icons.delete: FileAction.delete.label,
    Icons.info_outline: FileAction.details.label,
  };
  List<String> paths = [];

  @override
  void initState() {
    super.initState();
    paths.add(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.path);

    final filteredEntries = widget.isChanged
        ? gridList.entries
              .map(
                (e) => MapEntry(
                  e.key,
                  e.value == FileAction.favorite.label
                      ? (isFavorite
                            ? FileAction.removeFavorite.label
                            : FileAction.markFavorite.label)
                      : e.value,
                ),
              )
              .toList()
        : gridList.entries
              .where(
                (e) =>
                    e.value != FileAction.copy.label &&
                    e.value != FileAction.move.label,
              )
              .toList();

    return GridView.builder(
      itemCount: filteredEntries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        final icon = filteredEntries[index].key;
        final action = filteredEntries[index].value;

        return InkWell(
          splashColor: Colors.blueGrey,
          onTap: () => handleAction(
            context: context,
            ref: ref,
            action: action,
            path: widget.path,
            isFavorite: isFavorite,
            loadAgain: widget.loadAgain,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(height: 8),
              Text(
                action,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}
