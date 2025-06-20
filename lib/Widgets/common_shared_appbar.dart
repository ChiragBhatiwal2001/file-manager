import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/setting_popup_menu_widget.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';

class CommonFileExplorerAppBar extends ConsumerWidget {
  final String? initialPath;
  final Widget? leading;
  final List<Widget>? extraActions;
  final void Function()? onBack;
  final void Function()? onSearch;
  final void Function()? onCreateFolder;

  const CommonFileExplorerAppBar({
    super.key,
    this.initialPath,
    this.leading,
    this.extraActions,
    this.onBack,
    this.onSearch,
    this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(
      fileExplorerProvider(initialPath ?? Constant.internalPath),
    );
    final notifier = ref.read(
      fileExplorerProvider(initialPath ?? Constant.internalPath).notifier,
    );
    final selectionState = ref.watch(selectionProvider);

    final headingPath = currentState.currentPath == Constant.internalPath
        ? "All Files"
        : currentState.currentPath.split("/").last;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: leading ??
              IconButton(
                onPressed: onBack ??
                        () => notifier.goBack(currentState.currentPath, context),
                icon: const Icon(Icons.arrow_back),
              ),
          titleSpacing: 0,
          title: Text(
            headingPath,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 2,
          actions: [
            if (!selectionState.isSelectionMode) ...[
              IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.search),
              ),
              SettingPopupMenuWidget(
                popupList: ["Create Folder", "Sorting"],
                currentPath: currentState.currentPath,
                currentSortValue: ref
                    .watch(
                  fileExplorerProvider(currentState.currentPath),
                )
                    .sortValue,
                setSortValue: (sortValue, {forCurrentPath = false}) {
                  return ref
                      .read(
                    fileExplorerProvider(currentState.currentPath).notifier,
                  )
                      .setSortValue(sortValue, forCurrentPath: forCurrentPath);
                },
                showAddFolderDialog: onCreateFolder,
                showPathSpecificOption: true,
              ),
            ],
            if (selectionState.isSelectionMode && extraActions != null)
              ...extraActions!,
          ],
        ),
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: BreadcrumbWidget(
            path: currentState.currentPath,
            loadContent: notifier.loadAllContentOfPath,
          ),
        ),
      ],
    );
  }
}
