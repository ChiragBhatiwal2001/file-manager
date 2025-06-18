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

  // Add these helper functions inside SortingOperation
  int safeLength(File f) {
    try {
      return f.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  DateTime safeModified(File f) {
    try {
      return f.statSync().modified;
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

// Update your sortFileAndFolder method:
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
          final aSize = safeLength(File(a.path));
          final bSize = safeLength(File(b.path));
          return sortOrder == 'asc'
              ? aSize.compareTo(bSize)
              : bSize.compareTo(aSize);
        });
        break;
      case "modified":
        folderData.sort((a, b) {
          final aTime = safeModified(File(a.path));
          final bTime = safeModified(File(b.path));
          return sortOrder == 'asc'
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
        fileData.sort((a, b) {
          final aTime = safeModified(File(a.path));
          final bTime = safeModified(File(b.path));
          return sortOrder == 'asc'
              ? aTime.compareTo(bTime)
              : bTime.compareTo(aTime);
        });
        break;
    }
  }
}
