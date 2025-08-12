import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Panel settings configuration
class PanelSettings extends ChangeNotifier {
  static PanelSettings? _instance;
  static PanelSettings get instance {
    _instance ??= PanelSettings._();
    return _instance!;
  }
  
  PanelSettings._() {
    _loadSettings();
  }
  
  // Settings
  bool _showEnvironmentSwitcher = true;
  bool _showThemeSwitcher = true;
  bool _showFab = true;
  bool _enableShake = true;
  
  // Getters
  bool get showEnvironmentSwitcher => _showEnvironmentSwitcher;
  bool get showThemeSwitcher => _showThemeSwitcher;
  bool get showFab => _showFab;
  bool get enableShake => _enableShake;
  
  // Storage key
  static const String _storageKey = 'dev_panel_settings';
  
  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_storageKey);
      
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        _showEnvironmentSwitcher = settings['showEnvironmentSwitcher'] ?? true;
        _showThemeSwitcher = settings['showThemeSwitcher'] ?? true;
        _showFab = settings['showFab'] ?? true;
        _enableShake = settings['enableShake'] ?? true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load panel settings: $e');
    }
  }
  
  /// Save settings to storage
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = {
        'showEnvironmentSwitcher': _showEnvironmentSwitcher,
        'showThemeSwitcher': _showThemeSwitcher,
        'showFab': _showFab,
        'enableShake': _enableShake,
      };
      await prefs.setString(_storageKey, jsonEncode(settings));
    } catch (e) {
      debugPrint('Failed to save panel settings: $e');
    }
  }
  
  /// Update settings
  void updateSettings({
    bool? showEnvironmentSwitcher,
    bool? showThemeSwitcher,
    bool? showFab,
    bool? enableShake,
  }) {
    bool hasChanges = false;
    
    if (showEnvironmentSwitcher != null && _showEnvironmentSwitcher != showEnvironmentSwitcher) {
      _showEnvironmentSwitcher = showEnvironmentSwitcher;
      hasChanges = true;
    }
    
    if (showThemeSwitcher != null && _showThemeSwitcher != showThemeSwitcher) {
      _showThemeSwitcher = showThemeSwitcher;
      hasChanges = true;
    }
    
    if (showFab != null && _showFab != showFab) {
      _showFab = showFab;
      hasChanges = true;
    }
    
    if (enableShake != null && _enableShake != enableShake) {
      _enableShake = enableShake;
      hasChanges = true;
    }
    
    if (hasChanges) {
      _saveSettings();
      notifyListeners();
    }
  }
  
  /// Reset to defaults
  void reset() {
    _showEnvironmentSwitcher = true;
    _showThemeSwitcher = true;
    _showFab = true;
    _enableShake = true;
    _saveSettings();
    notifyListeners();
  }
}