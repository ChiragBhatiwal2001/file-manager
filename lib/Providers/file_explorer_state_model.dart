// lib/Providers/file_explorer_state_model.dart
import 'dart:io';

class FileExplorerState {
  final String currentPath;
  final List<FileSystemEntity> folders;
  final List<FileSystemEntity> files;
  final bool isLoading;
  final String sortValue;
  final Map<String, DateTime?>? lastModifiedMap;

  FileExplorerState({
    required this.currentPath,
    required this.folders,
    required this.files,
    required this.isLoading,
    required this.sortValue,
    required this.lastModifiedMap,
  });

  FileExplorerState copyWith({
    String? currentPath,
    List<FileSystemEntity>? folders,
    List<FileSystemEntity>? files,
    bool? isLoading,
    String? sortValue,
    Map<String, DateTime?>? lastModifiedMap, // <-- Add this
  }) {
    return FileExplorerState(
      currentPath: currentPath ?? this.currentPath,
      folders: folders ?? this.folders,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      sortValue: sortValue ?? this.sortValue,
      lastModifiedMap: lastModifiedMap ?? this.lastModifiedMap, // <-- Add this
    );
  }
}