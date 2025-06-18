import 'dart:io';

import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/sorting_operation.dart';

import 'package:file_manager/Services/sort_preference_db.dart';

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
    await loadAllContentOfPath(loadPath);
  }

  Future<void> loadAllContentOfPath(String path) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    final perPathSort = await SortPreferenceDB.getSortForPath(path);
    final globalSort = SharedPrefsService.instance.getString('sort-preference');
    final sortValue = perPathSort ?? globalSort ?? "name-asc";

    final data = await compute(PathLoadingOperations.loadContentIsolate, path);
    if (!mounted) return;

    final sorting = SortingOperation(
      filterItem: sortValue,
      folderData: data.folders,
      fileData: data.files,
    );
    sorting.sortFileAndFolder();

    final lastModifiedMap = <String, DateTime?>{};
    for (final entity in [...sorting.folderData, ...sorting.fileData]) {
      try {
        lastModifiedMap[entity.path] = await FileStat.stat(
          entity.path,
        ).then((s) => s.modified);
      } catch (_) {
        lastModifiedMap[entity.path] = null;
      }
    }

    if (!mounted) return;
    state = state.copyWith(
      currentPath: path,
      folders: sorting.folderData,
      files: sorting.fileData,
      lastModifiedMap: lastModifiedMap,
      isLoading: false,
      sortValue: sortValue,
    );
  }

  void clearState() {
    if (!mounted) return;
    state = state.copyWith(
      currentPath: '',
      folders: [],
      files: [],
      lastModifiedMap: {},
      isLoading: false,
    );
  }

  Future<void> setSortValue(
    String sortValue, {
    bool forCurrentPath = false,
  }) async {
    if (!mounted) return;

    if (forCurrentPath) {
      await SortPreferenceDB.setSortForPath(state.currentPath, sortValue);
    } else {
      await SharedPrefsService.instance.setString('sort-preference', sortValue);
      await SortPreferenceDB.removeSortForPath(state.currentPath);
    }

    if (!mounted) return;
    state = state.copyWith(sortValue: sortValue);
    await loadAllContentOfPath(state.currentPath);
  }

  Future<void> goBack(String path, BuildContext context) async {
    if (!mounted) return;

    final data = await PathLoadingOperations.goBackToParentPath(context, path);
    if (!mounted || data == null) return;

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
