import 'package:file_manager/Services/get_meta_data.dart';
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

class QuickAccessGridItem extends ConsumerStatefulWidget {
  final MediaFile file;
  final Function(String? path) getDataForDisplay;

  const QuickAccessGridItem({
    super.key,
    required this.file,
    required this.getDataForDisplay,
  });

  @override
  ConsumerState<QuickAccessGridItem> createState() =>
      _QuickAccessGridItemState();
}

class _QuickAccessGridItemState extends ConsumerState<QuickAccessGridItem> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() async {
    final result = await ThumbnailService.getThumbnail(widget.file.path);
    if (mounted) {
      setState(() {
        _thumbnail = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final isSelected = selectionState.selectedPaths.contains(widget.file.path);
    final isSelectionMode = selectionState.isSelectionMode;
    final fileName = p.basename(widget.file.path);

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          selectionNotifier.toggleSelection(widget.file.path);
        } else {
          OpenFilex.open(widget.file.path);
        }
      },
      onLongPress: () {
        selectionNotifier.toggleSelection(widget.file.path);
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _thumbnail != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _thumbnail!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    MediaUtils.getIconForMedia(widget.file.type),
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
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
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  isSelectionMode
                      ? Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: isSelected,
                    onChanged: (_) => selectionNotifier
                        .toggleSelection(widget.file.path),
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
                              path: widget.file.path,
                              loadAgain: widget.getDataForDisplay,
                            ),
                      );
                    },
                  ),
                ],
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: getMetadata(widget.file.path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...", style: TextStyle(fontSize: 12));
                  } else if (snapshot.hasData) {
                    final size = snapshot.data!['Size'];
                    final modified = snapshot.data!['Modified'];
                    return Text(
                      '$size | $modified',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              )

            ],
          ),
        ),
      ),
    );
  }
}
