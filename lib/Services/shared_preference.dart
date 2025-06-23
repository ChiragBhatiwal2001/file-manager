import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static final SharedPrefsService _instance = SharedPrefsService._internal();
  late SharedPreferences _prefs;

  SharedPrefsService._internal();

  static SharedPrefsService get instance => _instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  int getInt(String key, {required int defaultValue}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  bool? getBool(String key){
    return _prefs.getBool(key);
  }

  Future<bool> setBool(String key,bool value){
    return _prefs.setBool(key, value);
  }
}