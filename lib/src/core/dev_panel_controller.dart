import 'package:flutter/material.dart';
import '../models/dev_panel_config.dart';
import '../models/module.dart';
import '../models/theme_config.dart';
import 'storage.dart';
import 'environment_manager.dart';
import 'module_manager.dart';

class DevPanelController extends ChangeNotifier {
  static DevPanelController? _instance;
  
  static DevPanelController get instance {
    _instance ??= DevPanelController._();
    return _instance!;
  }
  
  DevPanelController._() {
    _init();
  }
  
  DevPanelConfig _config = const DevPanelConfig();
  bool _isVisible = false;
  final _storage = DevPanelStorage();
  late final EnvironmentManager _environmentManager;
  late final ModuleManager _moduleManager;

  DevPanelConfig get config => _config;
  bool get isVisible => _isVisible;
  EnvironmentManager get environmentManager => _environmentManager;
  ModuleManager get moduleManager => _moduleManager;

  void _init() {
    _environmentManager = EnvironmentManager();
    _moduleManager = ModuleManager();
    _loadConfig();
    _initializeManagers();
  }

  Future<void> initialize(DevPanelConfig config) async {
    _config = config;
    await _storage.saveConfig(config);
    _initializeManagers();
    notifyListeners();
  }

  void _initializeManagers() {
    _environmentManager.initialize(_config.environments);
    _moduleManager.initialize(_config.modules);
  }

  Future<void> _loadConfig() async {
    final savedConfig = await _storage.loadConfig();
    if (savedConfig != null) {
      _config = savedConfig;
      notifyListeners();
    }
  }

  void show() {
    if (_config.enabled) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  void updateConfig(DevPanelConfig config) {
    _config = config;
    _storage.saveConfig(config);
    notifyListeners();
  }

  void switchEnvironment(String environmentName) {
    _environmentManager.switchEnvironment(environmentName);
  }

  void updateTheme(ThemeConfig themeConfig) {
    _config = _config.copyWith(themeConfig: themeConfig);
    _storage.saveConfig(_config);
    notifyListeners();
  }

  void updateLocale(Locale locale) {
    _config = _config.copyWith(locale: locale);
    _storage.saveConfig(_config);
    notifyListeners();
  }

  void enableModule(String moduleId) {
    _moduleManager.enableModule(moduleId);
  }

  void disableModule(String moduleId) {
    _moduleManager.disableModule(moduleId);
  }

  List<DevModule> getEnabledModules() {
    return _moduleManager.getEnabledModules();
  }

  @override
  void dispose() {
    _storage.saveConfig(_config);
    _environmentManager.dispose();
    _moduleManager.dispose();
    super.dispose();
  }
  
  // 单例清理方法
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}