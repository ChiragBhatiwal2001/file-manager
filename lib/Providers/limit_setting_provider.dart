import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/shared_preference.dart';

class LimitSettingsState {
  final int recentLimit;
  final int favoriteLimit;

  const LimitSettingsState({
    required this.recentLimit,
    required this.favoriteLimit,
  });

  LimitSettingsState copyWith({
    int? recentLimit,
    int? favoriteLimit,
  }) {
    return LimitSettingsState(
      recentLimit: recentLimit ?? this.recentLimit,
      favoriteLimit: favoriteLimit ?? this.favoriteLimit,
    );
  }
}

final limitSettingsProvider =
StateNotifierProvider<LimitSettingsNotifier, LimitSettingsState>((ref) {
  final recent = SharedPrefsService.instance.getInt('recentLimit', defaultValue: 50);
  final favorite = SharedPrefsService.instance.getInt('favoriteLimit', defaultValue: 10);
  return LimitSettingsNotifier(
    LimitSettingsState(
      recentLimit: recent,
      favoriteLimit: favorite,
    ),
  );
});

class LimitSettingsNotifier extends StateNotifier<LimitSettingsState> {
  LimitSettingsNotifier(super.state);

  Future<void> updateRecentLimit(int value) async {
    await SharedPrefsService.instance.setInt('recentLimit', value);
    state = state.copyWith(recentLimit: value);
  }

  Future<void> updateFavoriteLimit(int value) async {
    await SharedPrefsService.instance.setInt('favoriteLimit', value);
    state = state.copyWith(favoriteLimit: value);
  }
}
