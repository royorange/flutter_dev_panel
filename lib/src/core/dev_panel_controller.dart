import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/dev_panel_config.dart';
import '../models/module.dart';
import '../models/theme_config.dart';
import 'storage.dart';
import 'environment_manager.dart';
import 'module_manager.dart';

class DevPanelController extends GetxController {
  static DevPanelController get to => Get.find();

  final _config = Rx<DevPanelConfig>(const DevPanelConfig());
  final _isVisible = false.obs;
  final _storage = DevPanelStorage();
  final _environmentManager = EnvironmentManager();
  final _moduleManager = ModuleManager();

  DevPanelConfig get config => _config.value;
  bool get isVisible => _isVisible.value;
  EnvironmentManager get environmentManager => _environmentManager;
  ModuleManager get moduleManager => _moduleManager;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
    _initializeManagers();
  }

  Future<void> initialize(DevPanelConfig config) async {
    _config.value = config;
    await _storage.saveConfig(config);
    _initializeManagers();
  }

  void _initializeManagers() {
    _environmentManager.initialize(_config.value.environments);
    _moduleManager.initialize(_config.value.modules);
  }

  Future<void> _loadConfig() async {
    final savedConfig = await _storage.loadConfig();
    if (savedConfig != null) {
      _config.value = savedConfig;
    }
  }

  void show() {
    if (_config.value.enabled) {
      _isVisible.value = true;
    }
  }

  void hide() {
    _isVisible.value = false;
  }

  void toggle() {
    if (_isVisible.value) {
      hide();
    } else {
      show();
    }
  }

  void updateConfig(DevPanelConfig config) {
    _config.value = config;
    _storage.saveConfig(config);
  }

  void switchEnvironment(String environmentName) {
    _environmentManager.switchEnvironment(environmentName);
  }

  void updateTheme(ThemeConfig themeConfig) {
    _config.value = _config.value.copyWith(themeConfig: themeConfig);
    _storage.saveConfig(_config.value);
  }

  void updateLocale(Locale locale) {
    _config.value = _config.value.copyWith(locale: locale);
    _storage.saveConfig(_config.value);
    Get.updateLocale(locale);
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
  void onClose() {
    _storage.saveConfig(_config.value);
    super.onClose();
  }
}