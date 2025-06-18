import 'dart:io';

import 'package:file_manager/Services/get_meta_data.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/header_for_single_file_operations.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/body_for_single_file_operation.dart';
import 'package:share_plus/share_plus.dart';

class BottomSheetForSingleFileOperation extends StatefulWidget {
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
  State<BottomSheetForSingleFileOperation> createState() =>
      _BottomSheetForSingleFileOperationState();
}

class _BottomSheetForSingleFileOperationState
    extends State<BottomSheetForSingleFileOperation> {
  Map<String, dynamic> fileData = {};

  @override
  void initState() {
    super.initState();
    _getFileDetails();
  }

  Future<void> _getFileDetails() async {
    final data = await getMetadata(widget.path);
    setState(() {
      fileData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDirectory = FileSystemEntity.isDirectorySync(widget.path);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: isDirectory ? 0.8 : 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HeaderForSingleFileOperation(
                fileData: fileData,
                path: widget.path,
              ),
              const Divider(height: 24, thickness: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BodyForSingleFileOperation(
                    path: widget.path,
                    loadAgain: widget.loadAgain,
                    isChanged: widget.isChangeDirectory,
                  ),
                ),
              ),
              const Divider(thickness: 1),
              if (!FileSystemEntity.isDirectorySync(widget.path))
                InkWell(
                  splashColor: Colors.grey,
                  onTap: () async {
                    final params = ShareParams(files: [XFile(widget.path)]);
                    final result = await SharePlus.instance.share(params);

                    if (result.status == ShareResultStatus.dismissed) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                      }
                    }
                  },
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.only(left: 35.0, top: 12.0),
                        child: Icon(Icons.share),
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          "Share",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!FileSystemEntity.isDirectorySync(widget.path))
                SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
