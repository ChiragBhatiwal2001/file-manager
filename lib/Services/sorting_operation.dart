import 'dart:io';

class SortingOperation {
  final String filterItem;
  List<FileSystemEntity> folderData;
  List<FileSystemEntity> fileData;

  SortingOperation({
    required this.filterItem,
    required this.folderData,
    required this.fileData,
  });

  void sortFileAndFolder() {
    final parts = filterItem.split('-');
    final sortBy = parts[0];
    final sortOrder = parts.length > 1 ? parts[1] : 'asc';

    int compare(String a, String b) =>
        sortOrder == 'asc' ? a.compareTo(b) : b.compareTo(a);

    switch (sortBy) {
      case "name":
        folderData.sort(
          (a, b) => compare(a.path.toLowerCase(), b.path.toLowerCase()),
        );
        fileData.sort(
          (a, b) => compare(a.path.toLowerCase(), b.path.toLowerCase()),
        );
        break;
      case "size":
        fileData.sort((a, b) {
          final aSize = File(a.path).lengthSync();
          final bSize = File(b.path).lengthSync();
          return sortOrder == 'asc'
              ? aSize.compareTo(bSize)
              : bSize.compareTo(aSize);
        });
        break;
      case "modified":
        folderData.sort((a, b) {
          final aTime = File(a.path).statSync().modified;
          final bTime = File(b.path).statSync().modified;
          return sortOrder == 'asc'
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
        fileData.sort((a, b) {
          final aTime = File(a.path).statSync().modified;
          final bTime = File(b.path).statSync().modified;
          return sortOrder == 'asc'
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
        break;
    }
  }
}
