import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/header_for_single_file_operations.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/body_for_single_file_operation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class BottomSheetForSingleFileOperation extends ConsumerStatefulWidget {
  const BottomSheetForSingleFileOperation({
    super.key,
    required this.path,
    required this.loadAgain,
    this.isChangeDirectory = true,
  });

  final String path;
  final void Function(String path) loadAgain;
  final bool isChangeDirectory;

  @override
  ConsumerState<BottomSheetForSingleFileOperation> createState() =>
      _BottomSheetForSingleFileOperationState();
}

class _BottomSheetForSingleFileOperationState
    extends ConsumerState<BottomSheetForSingleFileOperation> {
  Map<String, dynamic> fileData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getFileDetails();
  }

  Future<void> _getFileDetails() async {
    setState(() => isLoading = true);
    final data = await getMetadata(widget.path);
    if (!mounted) return;
    setState(() {
      fileData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDirectory = FileSystemEntity.isDirectorySync(widget.path);
    final isHidden = ref
        .read(hiddenPathsProvider.notifier)
        .isHidden(widget.path);

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeaderForSingleFileOperation(
              fileData: fileData,
              path: widget.path,
            ),
            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 2,
              ),
              child: BodyForSingleFileOperation(
                path: widget.path,
                loadAgain: widget.loadAgain,
                isChanged: widget.isChangeDirectory,
              ),
            ),

            const Divider(thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OptionRow(
                    icon: isHidden
                        ? Icons.visibility_off
                        : Icons.visibility,
                    label: isHidden ? "Un-Hide" : "Hide",
                    onTap: () async {
                      final notifier = ref.read(
                        hiddenPathsProvider.notifier,
                      );
                      if (isHidden) {
                        await notifier.unhidePath(widget.path);
                      } else {
                        await notifier.hidePath(widget.path);
                      }
                      if (context.mounted) Navigator.pop(context, true);
                      widget.loadAgain(p.dirname(widget.path));
                    },
                  ),
                  const Divider(),
                  if (!isDirectory)
                    _OptionRow(
                      icon: Icons.share,
                      label: "Share",
                      onTap: () async {
                        final params = ShareParams(
                          files: [XFile(widget.path)],
                        );
                        final result = await SharePlus.instance.share(
                          params,
                        );
                        if (result.status == ShareResultStatus.success &&
                            context.mounted) {
                          Navigator.pop(context, true);
                        } else if (result.status ==
                                ShareResultStatus.dismissed &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                        }
                      },
                    ),
                  if (!isDirectory) Divider(),
                  //
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
