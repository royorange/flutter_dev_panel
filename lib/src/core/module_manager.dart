import 'package:flutter/foundation.dart';
import '../models/module.dart';

class ModuleManager extends ChangeNotifier {
  List<DevModule> _modules = [];
  Set<String> _enabledModuleIds = {};

  List<DevModule> get modules => _modules;
  Set<String> get enabledModuleIds => _enabledModuleIds;

  void initialize(List<DevModule> modules) {
    _modules = modules;
    // Enable all modules by default
    _enabledModuleIds = modules.where((m) => m.enabled).map((m) => m.id).toSet();
    notifyListeners();
  }

  void registerModule(DevModule module) {
    if (!_modules.any((m) => m.id == module.id)) {
      _modules.add(module);
      if (module.enabled) {
        _enabledModuleIds.add(module.id);
      }
      notifyListeners();
    }
  }

  void unregisterModule(String moduleId) {
    _modules.removeWhere((m) => m.id == moduleId);
    _enabledModuleIds.remove(moduleId);
    notifyListeners();
  }

  void enableModule(String moduleId) {
    _enabledModuleIds.add(moduleId);
    notifyListeners();
  }

  void disableModule(String moduleId) {
    _enabledModuleIds.remove(moduleId);
    notifyListeners();
  }

  bool isModuleEnabled(String moduleId) {
    return _enabledModuleIds.contains(moduleId);
  }

  List<DevModule> getEnabledModules() {
    return _modules
        .where((m) => _enabledModuleIds.contains(m.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  DevModule? getModule(String moduleId) {
    try {
      return _modules.firstWhere((m) => m.id == moduleId);
    } catch (_) {
      return null;
    }
  }

  void reorderModules(List<String> moduleIds) {
    final reorderedModules = <DevModule>[];
    for (final id in moduleIds) {
      final module = getModule(id);
      if (module != null) {
        reorderedModules.add(module);
      }
    }
    _modules = reorderedModules;
    notifyListeners();
  }
}