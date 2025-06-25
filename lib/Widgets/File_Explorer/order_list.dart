import 'dart:io';

import 'package:file_manager/Utils/drag_ordering_enum_file_explorer.dart';

List<ExplorerItem> buildItemList(List<FileSystemEntity> folders, List<FileSystemEntity> files) {
  final items = <ExplorerItem>[];

  if (folders.isNotEmpty) {
    items.add(ExplorerItem(type: ExplorerItemType.folderHeader));
    items.addAll(folders.map((f) => ExplorerItem(type: ExplorerItemType.folder, path: f.path)));
  }

  if (files.isNotEmpty) {
    items.add(ExplorerItem(type: ExplorerItemType.fileHeader));
    items.addAll(files.map((f) => ExplorerItem(type: ExplorerItemType.file, path: f.path)));
  }

  return items;
}
