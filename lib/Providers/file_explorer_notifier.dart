import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Services/drag_order_file_explorer.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Services/sort_preference_db.dart';

class FileExplorerNotifier extends StateNotifier<FileExplorerState> {
  FileExplorerNotifier(this.initialPath, this.ref)
      : super(
    FileExplorerState(
      currentPath: initialPath,
      folders: [],
      files: [],
      isLoading: false,
      sortValue: "name-asc",
    ),
  ) {
    _init(initialPath);
  }

  final String initialPath;
  final Ref ref;

  Future<void> _init(String loadPath) async {
    await loadAllContentOfPath(loadPath);
  }

  Future<void> loadAllContentOfPath(String path) async {
    ref.read(currentPathProvider.notifier).state = path;
    state = state.copyWith(isLoading: true);

    final perPathSort = await SortPreferenceDB.getSortForPath(path);
    final globalSort = SharedPrefsService.instance.getString('sort-preference');
    final sortValue = perPathSort ?? globalSort ?? "name-asc";

    DirectoryContent data = await PathLoadingOperations.loadContent(path);

    if (sortValue == "drag") {
      final orderList = await DragOrderStore.getOrderForPath(path);
      if (orderList != null) {
        data.folders.sort((a, b) => orderList.indexOf(a.path).compareTo(orderList.indexOf(b.path)));
        data.files.sort((a, b) => orderList.indexOf(a.path).compareTo(orderList.indexOf(b.path)));
      }
    } else {
      final sorting = SortingOperation(
        filterItem: sortValue,
        folderData: data.folders,
        fileData: data.files,
      );
      sorting.sortFileAndFolder();
      data.folders = sorting.folderData;
      data.files = sorting.fileData;
    }

    state = state.copyWith(
      currentPath: path,
      folders: data.folders,
      files: data.files,
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
    if (forCurrentPath) {
      await SortPreferenceDB.setSortForPath(state.currentPath, sortValue);
    } else {
      await SharedPrefsService.instance.setString('sort-preference', sortValue);
      await SortPreferenceDB.removeSortForPath(state.currentPath);
    }
    state = state.copyWith(sortValue: sortValue);
    await loadAllContentOfPath(state.currentPath);
  }

  Future<void> goBack(BuildContext context) async {
    if (state.currentPath == Constant.internalPath) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final newPath = PathLoadingOperations.goBackToParentPath(state.currentPath);
    if (newPath != null) {
      await loadAllContentOfPath(newPath);
    }
  }
}

final fileExplorerProvider =
StateNotifierProvider<FileExplorerNotifier, FileExplorerState>((ref) {
  final initialPath = ref.watch(currentPathProvider);
  return FileExplorerNotifier(initialPath, ref);
});

final currentPathProvider = StateProvider<String>((ref) {
  return Constant.internalPath!;
});
