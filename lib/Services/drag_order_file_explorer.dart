import 'package:hive/hive.dart';

class DragOrderStore {
  static const String _boxName = 'dragOrderBox';

  static Future<void> saveOrderForPath(String path, List<String> orderedPaths) async {
    final box = await Hive.openBox<List<String>>(_boxName);
    await box.put(path, orderedPaths);
  }

  static Future<List<String>?> getOrderForPath(String path) async {
    final box = await Hive.openBox<List<String>>(_boxName);
    return box.get(path);
  }

  // static Future<void> removeOrderForPath(String path) async {
  //   final box = await Hive.openBox<List<String>>(_boxName);
  //   await box.delete(path);
  // }
}
