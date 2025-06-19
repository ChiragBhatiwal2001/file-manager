import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/selction_notifier.dart';

class QuickAccessGridItem extends ConsumerWidget {
  final MediaFile file;
  final Function(String? path) getDataForDisplay;

  const QuickAccessGridItem({
    super.key,
    required this.file,
    required this.getDataForDisplay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final isSelected = selectionState.selectedPaths.contains(file.path);
    final isSelectionMode = selectionState.isSelectionMode;
    final fileName = p.basename(file.path);

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          selectionNotifier.toggleSelection(file.path);
        } else {
          OpenFilex.open(file.path);
        }
      },
      onLongPress: () {
        selectionNotifier.toggleSelection(file.path);
      },
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FutureBuilder<Uint8List?>(
                  future: ThumbnailService.getSmartThumbnail(file.path),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      );
                    } else {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          MediaUtils.getIconForMedia(file.type),
                          size: 48,
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fileName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  isSelectionMode
                      ? Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: isSelected,
                    onChanged: (_) =>
                        selectionNotifier.toggleSelection(file.path),
                  )
                      : IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) =>
                            BottomSheetForSingleFileOperation(
                              path: file.path,
                              loadAgain: getDataForDisplay,
                            ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
