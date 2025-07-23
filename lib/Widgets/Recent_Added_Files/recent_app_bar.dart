import 'package:flutter/material.dart';

class RecentAddedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final int itemCount;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onBack;
  final VoidCallback onClearSelection;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onMove;
  final VoidCallback onSelectAll;
  final VoidCallback onSearch;
  final VoidCallback onToggleView;
  final String viewMode;

  const RecentAddedAppBar({
    required this.isLoading,
    required this.itemCount,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onBack,
    required this.onClearSelection,
    required this.onDelete,
    required this.onCopy,
    required this.onMove,
    required this.onSelectAll,
    required this.onSearch,
    required this.onToggleView,
    required this.viewMode,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 30);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: isSelectionMode ? onClearSelection : onBack,
        icon: Icon(isSelectionMode ? Icons.close : Icons.arrow_back),
      ),
      title: Text(
        isSelectionMode ? "$selectedCount selected" : "Recent Files",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      bottom: isLoading
          ? null
          : PreferredSize(
        preferredSize: const Size.fromHeight(34.0),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "$itemCount items in total",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      actions: isSelectionMode
          ? [
        IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        IconButton(icon: const Icon(Icons.copy), onPressed: onCopy),
        IconButton(icon: const Icon(Icons.drive_file_move), onPressed: onMove),
        IconButton(icon: const Icon(Icons.select_all), onPressed: onSelectAll),
      ]
          : [
        IconButton(icon: const Icon(Icons.search), onPressed: onSearch),
        IconButton(
          icon: Icon(viewMode == "Grid View" ? Icons.list : Icons.grid_view),
          onPressed: onToggleView,
        ),
      ],
    );
  }
}
