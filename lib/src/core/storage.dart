import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dev_panel_config.dart';
import '../models/environment.dart';
import '../models/theme_config.dart';

class DevPanelStorage {
  static const String _configKey = 'dev_panel_config';
  static const String _environmentsKey = 'dev_panel_environments';
  static const String _themeKey = 'dev_panel_theme';
  static const String _localeKey = 'dev_panel_locale';

  Future<DevPanelConfig?> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        final json = jsonDecode(configJson) as Map<String, dynamic>;
        // Note: This is a simplified version. Full implementation would need
        // to properly deserialize modules and other complex objects
        return DevPanelConfig(
          enabled: json['enabled'] as bool? ?? true,
          showInProduction: json['showInProduction'] as bool? ?? false,
        );
      }
    } catch (e) {
      print('Error loading config: $e');
    }
    return null;
  }

  Future<void> saveConfig(DevPanelConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = config.toJson();
      await prefs.setString(_configKey, jsonEncode(json));
    } catch (e) {
      print('Error saving config: $e');
    }
  }

  Future<List<Environment>> loadEnvironments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final environmentsJson = prefs.getString(_environmentsKey);
      if (environmentsJson != null) {
        final list = jsonDecode(environmentsJson) as List;
        return list
            .map((json) => Environment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading environments: $e');
    }
    return [];
  }

  Future<void> saveEnvironments(List<Environment> environments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = environments.map((e) => e.toJson()).toList();
      await prefs.setString(_environmentsKey, jsonEncode(json));
    } catch (e) {
      print('Error saving environments: $e');
    }
  }

  Future<ThemeConfig?> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString(_themeKey);
      if (themeJson != null) {
        final json = jsonDecode(themeJson) as Map<String, dynamic>;
        return ThemeConfig.fromJson(json);
      }
    } catch (e) {
      print('Error loading theme: $e');
    }
    return null;
  }

  Future<void> saveTheme(ThemeConfig theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, jsonEncode(theme.toJson()));
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<String?> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_localeKey);
    } catch (e) {
      print('Error loading locale: $e');
    }
    return null;
  }

  Future<void> saveLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
    } catch (e) {
      print('Error saving locale: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      await prefs.remove(_environmentsKey);
      await prefs.remove(_themeKey);
      await prefs.remove(_localeKey);
    } catch (e) {
      print('Error clearing storage: $e');
    }
  }
}