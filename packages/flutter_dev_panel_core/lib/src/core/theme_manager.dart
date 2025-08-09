import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme configuration
class ThemeConfig {
  final String name;
  final ThemeMode mode;
  final Color? primaryColor;
  final Brightness? brightness;
  final Map<String, dynamic>? customProperties;
  
  const ThemeConfig({
    required this.name,
    required this.mode,
    this.primaryColor,
    this.brightness,
    this.customProperties,
  });
  
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      name: json['name'] as String,
      mode: ThemeMode.values[json['mode'] as int],
      primaryColor: json['primaryColor'] != null 
        ? Color(json['primaryColor'] as int) 
        : null,
      brightness: json['brightness'] != null
        ? Brightness.values[json['brightness'] as int]
        : null,
      customProperties: json['customProperties'] != null
        ? Map<String, dynamic>.from(json['customProperties'] as Map)
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mode': mode.index,
      'primaryColor': primaryColor?.toARGB32(),
      'brightness': brightness?.index,
      'customProperties': customProperties,
    };
  }
  
  ThemeConfig copyWith({
    String? name,
    ThemeMode? mode,
    Color? primaryColor,
    Brightness? brightness,
    Map<String, dynamic>? customProperties,
  }) {
    return ThemeConfig(
      name: name ?? this.name,
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      brightness: brightness ?? this.brightness,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}

/// Theme manager singleton
class ThemeManager extends ChangeNotifier {
  static ThemeManager? _instance;
  static ThemeManager get instance {
    _instance ??= ThemeManager._();
    return _instance!;
  }
  
  ThemeManager._() {
    _loadTheme();
  }
  
  // Current theme configuration
  ThemeConfig _currentTheme = const ThemeConfig(
    name: 'System',
    mode: ThemeMode.system,
  );
  
  ThemeConfig get currentTheme => _currentTheme;
  
  // Storage keys
  static const String _storageKey = 'dev_panel_theme';
  
  // Predefined themes
  static final List<ThemeConfig> predefinedThemes = [
    const ThemeConfig(
      name: 'System',
      mode: ThemeMode.system,
    ),
    const ThemeConfig(
      name: 'Light',
      mode: ThemeMode.light,
      brightness: Brightness.light,
    ),
    const ThemeConfig(
      name: 'Dark', 
      mode: ThemeMode.dark,
      brightness: Brightness.dark,
    ),
  ];
  
  // User-defined custom themes
  final List<ThemeConfig> _customThemes = [];
  
  /// Get available themes (predefined + custom)
  List<ThemeConfig> get availableThemes => [...predefinedThemes, ..._customThemes];
  
  /// Load theme from storage
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString(_storageKey);
      
      if (themeJson != null) {
        final themeData = jsonDecode(themeJson) as Map<String, dynamic>;
        _currentTheme = ThemeConfig.fromJson(themeData);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load theme: $e');
    }
  }
  
  /// Save theme to storage
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_currentTheme.toJson()));
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }
  
  /// Switch theme
  void switchTheme(ThemeConfig theme) {
    if (_currentTheme.name != theme.name) {
      _currentTheme = theme;
      _saveTheme();
      notifyListeners();
    }
  }
  
  /// Switch by theme mode
  void switchThemeMode(ThemeMode mode) {
    final theme = predefinedThemes.firstWhere(
      (t) => t.mode == mode,
      orElse: () => predefinedThemes.first,
    );
    switchTheme(theme);
  }
  
  /// Add custom theme
  void addCustomTheme({
    required String name,
    required ThemeMode mode,
    Color? primaryColor,
    Brightness? brightness,
    Map<String, dynamic>? customProperties,
  }) {
    // Remove existing theme with same name
    _customThemes.removeWhere((t) => t.name == name);
    
    final theme = ThemeConfig(
      name: name,
      mode: mode,
      primaryColor: primaryColor,
      brightness: brightness,
      customProperties: customProperties,
    );
    
    _customThemes.add(theme);
    notifyListeners();
  }
  
  /// Remove custom theme
  void removeCustomTheme(String name) {
    _customThemes.removeWhere((t) => t.name == name);
    
    // If current theme was removed, switch to System
    if (_currentTheme.name == name) {
      switchTheme(predefinedThemes.first);
    } else {
      notifyListeners();
    }
  }
  
  /// Get theme data for Material app
  ThemeData? getThemeData(BuildContext context, {ThemeData? baseTheme}) {
    if (_currentTheme.mode == ThemeMode.system) {
      return null; // Let system decide
    }
    
    final isDark = _currentTheme.mode == ThemeMode.dark || 
                   _currentTheme.brightness == Brightness.dark;
    
    ThemeData theme = baseTheme ?? (isDark ? ThemeData.dark() : ThemeData.light());
    
    if (_currentTheme.primaryColor != null) {
      theme = theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _currentTheme.primaryColor!,
          brightness: _currentTheme.brightness ?? theme.brightness,
        ),
      );
    }
    
    return theme;
  }
  
  /// Reset to default theme
  void reset() {
    _currentTheme = predefinedThemes.first;
    _saveTheme();
    notifyListeners();
  }
  
  /// Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    if (_currentTheme.mode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _currentTheme.mode == ThemeMode.dark || 
           _currentTheme.brightness == Brightness.dark;
  }
}