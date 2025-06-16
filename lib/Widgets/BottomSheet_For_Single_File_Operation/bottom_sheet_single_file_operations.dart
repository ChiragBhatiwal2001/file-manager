import 'package:file_manager/Services/get_meta_data.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/header_for_single_file_operations.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/body_for_single_file_operation.dart';

class BottomSheetForSingleFileOperation extends StatefulWidget {
  BottomSheetForSingleFileOperation({
    super.key,
    required this.path,
    required this.loadAgain,
    this.isChangeDirectory = true,
  });

  final String path;
  final void Function(String path) loadAgain;
  bool isChangeDirectory;

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
    getFileDetails();
  }

  void getFileDetails() async {
    final data = await getMetadata(widget.path);
    setState(() {
      fileData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderForSingleFileOperation(
                fileData: fileData,
                path: widget.path,
              ),
              const Divider(height: 24, thickness: 1),
              // Actions grid
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
            ],
          ),
        );
      },
    );
  }
}
