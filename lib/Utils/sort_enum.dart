enum SortByType { name, size, modified, type, drag }

enum SortOrderType { asc, desc, drag }

extension SortByTypeExtension on SortByType {
  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}