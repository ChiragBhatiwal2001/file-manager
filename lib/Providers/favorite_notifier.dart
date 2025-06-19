import 'package:file_manager/Services/sqflite_favorites_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends StateNotifier<List<String>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  List<String> get topFavorites => state.take(4).toList();

  Future<void> _loadFavorites() async {
    state = await FavoritesDB().getFavoritesOrdered();
  }

  Future<void> reorderFavorites(int oldIndex, int newIndex) async {
    final updated = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);
    state = updated;
    await FavoritesDB().updateFavoritesOrder(updated);
  }

  Future<void> toggleFavorite(String path, bool isDir) async {
    if (state.contains(path)) {
      await FavoritesDB().removeFavorite(path);
    } else {
      await FavoritesDB().addFavorite(path, isDir);
    }
    await _loadFavorites();
  }



  Future<void> clearFavorites() async {
    await FavoritesDB().clearFavorites();
    state = [];
  }

  bool isFavorite(String path) => state.contains(path);
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<String>>(
      (ref) => FavoritesNotifier(),
);