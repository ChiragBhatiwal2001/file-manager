import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/shared_preference.dart';

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
      (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final theme = SharedPrefsService.instance.getString('themeMode') ?? 'system';
    switch (theme) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setTheme(String mode) async {
    await SharedPrefsService.instance.setString('themeMode', mode);
    await loadTheme();
  }
}