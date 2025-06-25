enum ExplorerItemType { folderHeader, fileHeader, folder, file }

class ExplorerItem {
  final ExplorerItemType type;
  final String? path;

  ExplorerItem({required this.type, this.path});
}
