import 'dart:io';

class FileExplorerState {
  final String currentPath;
  final List<FileSystemEntity> folders;
  final List<FileSystemEntity> files;
  final bool isLoading;
  final String sortValue;


  FileExplorerState({
    required this.currentPath,
    required this.folders,
    required this.files,
    required this.isLoading,
    required this.sortValue,

  });

  FileExplorerState copyWith({
    String? currentPath,
    List<FileSystemEntity>? folders,
    List<FileSystemEntity>? files,
    bool? isLoading,
    String? sortValue,
    Map<String, DateTime?>? lastModifiedMap,
  }) {
    return FileExplorerState(
      currentPath: currentPath ?? this.currentPath,
      folders: folders ?? this.folders,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      sortValue: sortValue ?? this.sortValue,
    );
  }
}