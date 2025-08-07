import 'package:flutter/foundation.dart';
import '../models/dev_panel_config.dart';
import 'module_registry.dart';

/// 开发面板核心控制器
class DevPanelController extends ChangeNotifier {
  static DevPanelController? _instance;
  
  static DevPanelController get instance {
    _instance ??= DevPanelController._();
    return _instance!;
  }
  
  DevPanelController._();

  bool _isOpen = false;
  DevPanelConfig _config = const DevPanelConfig();
  
  bool get isOpen => _isOpen;
  DevPanelConfig get config => _config;
  ModuleRegistry get moduleRegistry => ModuleRegistry.instance;

  /// 初始化开发面板
  void initialize({DevPanelConfig? config}) {
    if (config != null) {
      _config = config;
    }
    notifyListeners();
  }

  /// 更新配置
  void updateConfig(DevPanelConfig config) {
    _config = config;
    notifyListeners();
  }

  /// 打开面板
  void open() {
    if (!_isOpen && _config.enabled) {
      _isOpen = true;
      notifyListeners();
    }
  }

  /// 关闭面板
  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// 切换面板状态
  void toggle() {
    if (_isOpen) {
      close();
    } else {
      open();
    }
  }

  /// 检查是否应该在生产环境显示
  bool shouldShowInProduction() {
    return _config.showInProduction || kDebugMode;
  }

  /// 清理资源
  @override
  void dispose() {
    moduleRegistry.clear();
    super.dispose();
  }

  /// 重置单例
  static void reset() {
    _instance?.dispose();
    _instance = null;
    ModuleRegistry.reset();
  }
}