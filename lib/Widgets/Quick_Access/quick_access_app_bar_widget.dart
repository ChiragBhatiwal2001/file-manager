import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickAccessAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool isLoading;
  final int itemCount;
  final List<Widget> actions;
  final VoidCallback onBack;

  const QuickAccessAppBar({
    super.key,
    required this.title,
    required this.isLoading,
    required this.itemCount,
    required this.actions,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectedCount = selectionState.selectedPaths.length;

    return AppBar(
      titleSpacing: 0,
      title: Text(
        selectedCount > 0 ? "$selectedCount selected" : title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: actions,
      leading: IconButton(
        icon: Icon(
          selectionState.isSelectionMode ? Icons.close : Icons.arrow_back,
        ),
        onPressed: onBack,
      ),
      bottom: isLoading || itemCount == 0
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 34.0);
}
