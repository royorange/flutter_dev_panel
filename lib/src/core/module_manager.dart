import 'package:get/get.dart';
import '../models/module.dart';

class ModuleManager extends GetxController {
  final _modules = <DevModule>[].obs;
  final _enabledModuleIds = <String>{}.obs;

  List<DevModule> get modules => _modules;
  Set<String> get enabledModuleIds => _enabledModuleIds;

  void initialize(List<DevModule> modules) {
    _modules.value = modules;
    // Enable all modules by default
    _enabledModuleIds.value = modules.where((m) => m.enabled).map((m) => m.id).toSet();
  }

  void registerModule(DevModule module) {
    if (!_modules.any((m) => m.id == module.id)) {
      _modules.add(module);
      if (module.enabled) {
        _enabledModuleIds.add(module.id);
      }
    }
  }

  void unregisterModule(String moduleId) {
    _modules.removeWhere((m) => m.id == moduleId);
    _enabledModuleIds.remove(moduleId);
  }

  void enableModule(String moduleId) {
    _enabledModuleIds.add(moduleId);
  }

  void disableModule(String moduleId) {
    _enabledModuleIds.remove(moduleId);
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
    return _modules.firstWhereOrNull((m) => m.id == moduleId);
  }

  void reorderModules(List<String> moduleIds) {
    final reorderedModules = <DevModule>[];
    for (final id in moduleIds) {
      final module = getModule(id);
      if (module != null) {
        reorderedModules.add(module);
      }
    }
    _modules.value = reorderedModules;
  }
}