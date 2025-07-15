enum FileAction {
  copy,
  move,
  markFavorite,
  removeFavorite,
  favorite,
  delete,
  details,
  rename,
}

extension FileActionExtension on FileAction {
  String get label {
    final spaced = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    final words = spaced.split(' ');

    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    });

    return capitalized.join(' ');
  }

  static FileAction? fromLabel(String label) {
    try {
      return FileAction.values.firstWhere((e) => e.label == label);
    } catch (_) {
      return null;
    }
  }
}
