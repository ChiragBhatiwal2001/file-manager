import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/shared_preference.dart';

final themeNotifierProvider =
StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final mode = SharedPrefsService.instance.getString('themeMode');
  final ThemeMode initialMode;

  if (mode == 'dark') {
    initialMode = ThemeMode.dark;
  } else if (mode == 'light') {
    initialMode = ThemeMode.light;
  } else {
    initialMode = ThemeMode.system;
  }

  return ThemeModeNotifier(initialMode);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initialMode) : super(initialMode);

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    SharedPrefsService.instance.setString(
      'themeMode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
