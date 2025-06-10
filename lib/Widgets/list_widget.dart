import 'dart:io';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:flutter/material.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({
    super.key,
    required this.storageFile,
    required this.isSelected,
    required this.isChecked,
    required this.onLongPress,
    required this.onTap,
    this.onCheckboxChanged,
  });

  final FileSystemEntity storageFile;
  final bool isSelected;
  final bool isChecked;
  final void Function() onLongPress;
  final void Function() onTap;
  final ValueChanged<bool?>? onCheckboxChanged;

  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  Map<String, dynamic> data = {};
  bool isLoading = false;
  int? filesCount;

  @override
  void initState() {
    super.initState();
    _loadMetaData();
    countFilesInDirectory(widget.storageFile.path);
  }

  Future<int> countFilesInDirectory(String path) async {
    int fileCount = 0;
    try {
      final dir = Directory(path);

      if (await dir.exists()) {
        await for (FileSystemEntity entity in dir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is File) {
            fileCount++;
          } else if (entity is Directory) {
            fileCount++;
          }
        }
      }
      setState(() {
        filesCount = fileCount;
      });
    } catch (e) {
      if(context.mounted)
        {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
    }

    return fileCount;
  }

  Future<void> _loadMetaData() async {
    setState(() {
      isLoading = true;
    });
    final meta = await getMetadata(widget.storageFile.path);
    setState(() {
      data = meta;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.storageFile.path.split("/").last;
    final isDir = FileSystemEntity.isDirectorySync(widget.storageFile.path);

    return ListTile(
      leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
      title: Text(fileName),
      subtitle: isDir
          ? Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  Text("${filesCount ?? "-"} items"),
                  SizedBox(width: 5,),
                  Text("|"),
                  SizedBox(width: 5,),
                  Text(data["Modified"] ?? ""),
                ],
              ),
            )
          : null,
      trailing: widget.isSelected
          ? Checkbox(
              value: widget.isChecked,
              onChanged: widget.onCheckboxChanged,
            )
          : Icon(isDir ? Icons.arrow_forward_ios_sharp : null),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
    );
  }
}