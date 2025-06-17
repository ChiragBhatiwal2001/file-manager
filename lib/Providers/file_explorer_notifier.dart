import 'dart:io';

import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/sorting_operation.dart';

class FileExplorerNotifier extends StateNotifier<FileExplorerState> {
  FileExplorerNotifier(String initialPath)
    : super(
        FileExplorerState(
          currentPath: initialPath,
          folders: [],
          files: [],
          isLoading: false,
          sortValue: "name-asc",
          lastModifiedMap: {},
        ),
      ) {
    _init(initialPath);
  }

  Future<void> _init(String loadPath) async {
    final savedSort = SharedPrefsService.instance.getString('sort-preference');

    if (savedSort != null && savedSort != state.sortValue) {
      state = state.copyWith(sortValue: savedSort);
    }
    await loadAllContentOfPath(loadPath);
  }



  Future<void> loadAllContentOfPath(String path) async {
    state = state.copyWith(isLoading: true);
    final data = await compute(PathLoadingOperations.loadContentIsolate, path);

    final sorting = SortingOperation(
      filterItem: state.sortValue,
      folderData: data.folders,
      fileData: data.files,
    );
    sorting.sortFileAndFolder();

    // Preload last modified dates
    final lastModifiedMap = <String, DateTime?>{};
    for (final entity in [...sorting.folderData, ...sorting.fileData]) {
      try {
        lastModifiedMap[entity.path] = await FileStat.stat(entity.path).then((s) => s.modified);
      } catch (_) {
        lastModifiedMap[entity.path] = null;
      }
    }

    state = state.copyWith(
      currentPath: path,
      folders: sorting.folderData,
      files: sorting.fileData,
      lastModifiedMap: lastModifiedMap,
      isLoading: false,
    );
  }

  void clearState() {
    state = state.copyWith(
      currentPath: '',
      folders: [],
      files: [],
      lastModifiedMap: {},
      isLoading: false,
    );
  }

  void setSortValue(String sortValue) async {
    await SharedPrefsService.instance.setString('sort-preference', sortValue);
    state = state.copyWith(sortValue: sortValue);
    await loadAllContentOfPath(state.currentPath);
  }

  Future<void> goBack(String path, BuildContext context) async {
    final data = await PathLoadingOperations.goBackToParentPath(context, path);

    if (data == null) {
      return;
    }

    String parentPath = Directory(path).parent.path;
    await loadAllContentOfPath(parentPath);
  }
}

final fileExplorerProvider =
    StateNotifierProvider.family<
      FileExplorerNotifier,
      FileExplorerState,
      String?
    >((ref, path) => FileExplorerNotifier(path ?? Constant.internalPath));
