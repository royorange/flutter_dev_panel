import 'package:flutter/foundation.dart';

/// FAB显示控制器，用于管理FAB的展开/收起状态
class FabController extends ChangeNotifier {
  static FabController? _instance;
  
  static FabController get instance {
    _instance ??= FabController._();
    return _instance!;
  }
  
  FabController._();
  
  bool _shouldExpand = false;
  final Set<String> _activeModules = {};
  
  /// 是否应该展开FAB
  bool get shouldExpand => _shouldExpand && _activeModules.isNotEmpty;
  
  /// 获取活跃的模块ID列表
  Set<String> get activeModules => Set.unmodifiable(_activeModules);
  
  /// 模块请求显示FAB内容
  void requestShow(String moduleId) {
    if (!_activeModules.contains(moduleId)) {
      _activeModules.add(moduleId);
      _shouldExpand = true;
      notifyListeners();
    }
  }
  
  /// 模块请求隐藏FAB内容
  void requestHide(String moduleId) {
    if (_activeModules.remove(moduleId)) {
      // 如果没有活跃模块了，收起FAB
      if (_activeModules.isEmpty) {
        _shouldExpand = false;
      }
      notifyListeners();
    }
  }
  
  /// 手动展开FAB
  void expand() {
    if (_activeModules.isNotEmpty) {
      _shouldExpand = true;
      notifyListeners();
    }
  }
  
  /// 手动收起FAB
  void collapse() {
    _shouldExpand = false;
    notifyListeners();
  }
  
  /// 切换展开/收起状态
  void toggle() {
    if (_activeModules.isNotEmpty) {
      _shouldExpand = !_shouldExpand;
      notifyListeners();
    }
  }
  
  /// 重置
  void reset() {
    _shouldExpand = false;
    _activeModules.clear();
    notifyListeners();
  }
  
  /// 重置单例
  static void resetInstance() {
    _instance?.reset();
    _instance = null;
  }
}