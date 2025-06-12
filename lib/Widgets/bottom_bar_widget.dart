import 'package:flutter/material.dart';

class BottomBarWidget extends StatelessWidget {
  final bool isRenameEnabled;
  final VoidCallback onRename;
  final VoidCallback? onCopy;
  final VoidCallback? onMove;
  final VoidCallback onDelete;
  final bool? isFavorite;
  final VoidCallback? onFavoriteClicked;

  const BottomBarWidget({
    super.key,
    required this.isRenameEnabled,
    required this.onRename,
    this.onCopy,
    this.onMove,
    required this.onDelete,
    this.isFavorite,
    this.onFavoriteClicked,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isRenameEnabled)
            IconButton(
              onPressed: onRename,
              icon: Icon(Icons.drive_file_rename_outline),
            ),
          IconButton(onPressed: onCopy, icon: Icon(Icons.copy)),
          SizedBox(width: 10),
          IconButton(onPressed: onMove, icon: Icon(Icons.drive_file_move)),
          IconButton(onPressed: onDelete, icon: Icon(Icons.delete)),
          if (isFavorite != null)
            IconButton(
              onPressed: onFavoriteClicked,
              icon: isFavorite!
                  ? Icon(Icons.star)
                  : Icon(Icons.star_border_outlined),
            ),
        ],
      ),
    );
  }
}
