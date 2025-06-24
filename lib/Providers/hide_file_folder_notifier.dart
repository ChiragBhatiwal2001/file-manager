import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sqflite_hide_file_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hiddenPathsProvider =
    StateNotifierProvider<HiddenPathsNotifier, HiddenState>((ref) {
      return HiddenPathsNotifier()..loadHiddenPaths();
    });

class HiddenState {
  final Set<String> hiddenPaths;
  final bool showHidden;

  HiddenState({required this.hiddenPaths, required this.showHidden});

  HiddenState copyWith({Set<String>? hiddenPaths, bool? showHidden}) {
    return HiddenState(
      hiddenPaths: hiddenPaths ?? this.hiddenPaths,
      showHidden: showHidden ?? this.showHidden,
    );
  }
}

class HiddenPathsNotifier extends StateNotifier<HiddenState> {
  HiddenPathsNotifier()
    : super(HiddenState(hiddenPaths: {}, showHidden: false));

  Future<void> loadHiddenPaths() async {
    final hidden = await HiddenFileDb.getHiddenPaths();

    // Load user preference from SharedPrefs
    final storedShowHidden =
        SharedPrefsService.instance.getBool('showHidden') ?? false;

    state = state.copyWith(
      hiddenPaths: hidden.toSet(),
      showHidden: storedShowHidden,
    );
  }

  Future<bool> hidePath(String path) async {
    final success = await HiddenFileDb.hidePath(path);
    if (success) {
      state = state.copyWith(hiddenPaths: {...state.hiddenPaths, path});
    }
    return success;
  }

  Future<bool> unhidePath(String path) async {
    final success = await HiddenFileDb.unhidePath(path);
    if (success) {
      final newPaths = {...state.hiddenPaths}..remove(path);
      state = state.copyWith(hiddenPaths: newPaths);
    }
    return success;
  }

  bool isHidden(String path) => state.hiddenPaths.contains(path);

  bool get isShowHidden => state.showHidden;

  void toggleShowHidden() {
    final newValue = !state.showHidden;
    state = state.copyWith(showHidden: newValue);
    SharedPrefsService.instance.setBool('showHidden', newValue);
  }

  void setShowHidden(bool value) {
    state = state.copyWith(showHidden: value);
    SharedPrefsService.instance.setBool('showHidden', value);
  }
}
