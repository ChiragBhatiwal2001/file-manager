import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/shared_preference.dart';

final fileViewModeProvider = StateNotifierProvider<FileViewModeNotifier, String>((ref) {
  return FileViewModeNotifier();
});

class FileViewModeNotifier extends StateNotifier<String> {
  FileViewModeNotifier() : super("List View") {
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPrefsService.instance;
    final savedMode = prefs.getString("fileViewGrid") ?? "List View";
    state = savedMode;
  }

  Future<void> toggleMode() async {
    final newMode = state == "List View" ? "Grid View" : "List View";
    final prefs = await SharedPrefsService.instance;
    await prefs.setString("fileViewGrid", newMode);
    state = newMode;
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPrefsService.instance;
    await prefs.setString("fileViewGrid", mode);
    state = mode;
  }
}