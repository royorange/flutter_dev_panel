import 'package:flutter/foundation.dart';
import '../models/dev_module.dart';

/// 模块注册表，管理所有已注册的模块
class ModuleRegistry extends ChangeNotifier {
  static ModuleRegistry? _instance;
  
  static ModuleRegistry get instance {
    _instance ??= ModuleRegistry._();
    return _instance!;
  }
  
  ModuleRegistry._();
  
  final List<DevModule> _modules = [];
  final Set<String> _enabledModuleIds = {};

  List<DevModule> get modules => List.unmodifiable(_modules);
  Set<String> get enabledModuleIds => Set.unmodifiable(_enabledModuleIds);

  /// 注册模块
  void registerModule(DevModule module) {
    if (!_modules.any((m) => m.id == module.id)) {
      _modules.add(module);
      if (module.enabled) {
        _enabledModuleIds.add(module.id);
      }
      _modules.sort((a, b) => a.order.compareTo(b.order));
      module.initialize();
      notifyListeners();
    }
  }

  /// 注册多个模块
  void registerModules(List<DevModule> modules) {
    for (final module in modules) {
      registerModule(module);
    }
  }

  /// 注销模块
  void unregisterModule(String moduleId) {
    final module = _modules.firstWhere(
      (m) => m.id == moduleId,
      orElse: () => throw Exception('Module $moduleId not found'),
    );
    
    module.dispose();
    _modules.removeWhere((m) => m.id == moduleId);
    _enabledModuleIds.remove(moduleId);
    notifyListeners();
  }

  /// 启用模块
  void enableModule(String moduleId) {
    if (_modules.any((m) => m.id == moduleId)) {
      _enabledModuleIds.add(moduleId);
      notifyListeners();
    }
  }

  /// 禁用模块
  void disableModule(String moduleId) {
    _enabledModuleIds.remove(moduleId);
    notifyListeners();
  }

  /// 检查模块是否启用
  bool isModuleEnabled(String moduleId) {
    return _enabledModuleIds.contains(moduleId);
  }

  /// 获取所有启用的模块
  List<DevModule> getEnabledModules() {
    return _modules
        .where((m) => _enabledModuleIds.contains(m.id))
        .toList();
  }

  /// 获取指定模块
  DevModule? getModule(String moduleId) {
    try {
      return _modules.firstWhere((m) => m.id == moduleId);
    } catch (_) {
      return null;
    }
  }

  /// 清理所有模块
  void clear() {
    for (final module in _modules) {
      module.dispose();
    }
    _modules.clear();
    _enabledModuleIds.clear();
    notifyListeners();
  }

  /// 重置单例
  static void reset() {
    _instance?.clear();
    _instance = null;
  }
}