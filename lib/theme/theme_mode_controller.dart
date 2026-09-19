import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';

class ThemeModeController extends ChangeNotifier {
  new _(this._preferences, this._mode);

  final SharedPreferences _preferences;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  static Future<ThemeModeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_themeModeKey);
    final mode = ThemeMode.values
        .where((value) => value.name == saved)
        .firstOrNull;
    return ThemeModeController._(preferences, mode ?? ThemeMode.system);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _preferences.setString(_themeModeKey, mode.name);
  }
}
