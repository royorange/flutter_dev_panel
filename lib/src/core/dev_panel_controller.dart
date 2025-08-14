import 'package:flutter/foundation.dart';
import '../models/dev_panel_config.dart';
import 'module_registry.dart';

/// 编译时常量，通过 --dart-define=FORCE_DEV_PANEL=true 启用
const bool _forceDevPanel = bool.fromEnvironment(
  'FORCE_DEV_PANEL',
  defaultValue: false,
);

/// Dev Panel core controller
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

  /// Initialize dev panel
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
    if (!_isOpen && isEnabled) {
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

  /// 检查面板是否启用
  /// - 调试模式：始终启用
  /// - 生产模式：仅当 FORCE_DEV_PANEL=true 时启用
  static bool get isEnabled => kDebugMode || _forceDevPanel;

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