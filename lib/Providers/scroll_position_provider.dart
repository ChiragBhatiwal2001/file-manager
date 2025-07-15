import 'package:flutter_riverpod/flutter_riverpod.dart';

final scrollPositionProvider = StateNotifierProvider<ScrollPositionNotifier, Map<String, double>>(
      (ref) => ScrollPositionNotifier(),
);

class ScrollPositionNotifier extends StateNotifier<Map<String, double>> {
  ScrollPositionNotifier() : super({});

  void saveScrollOffset(String path, double offset) {
    state = {
      ...state,
      path: offset,
    };
  }

  double? getScrollOffset(String path) {
    return state[path];
  }
}
