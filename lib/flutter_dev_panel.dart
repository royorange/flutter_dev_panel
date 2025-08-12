library flutter_dev_panel;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Core exports
export 'src/core/dev_panel_controller.dart';
export 'src/core/module_registry.dart';
export 'src/core/monitoring_data_provider.dart';
export 'src/core/dev_logger.dart';
export 'src/core/environment_manager.dart';
export 'src/core/theme_manager.dart';

// Model exports
export 'src/models/dev_module.dart';
export 'src/models/dev_panel_config.dart';
export 'src/models/panel_settings.dart';

// UI exports
export 'src/ui/dev_panel.dart';
export 'src/ui/dev_panel_wrapper.dart';
export 'src/ui/widgets/shake_detector.dart';
export 'src/ui/widgets/modular_monitoring_fab.dart';
export 'src/ui/widgets/environment_switcher.dart';
export 'src/ui/widgets/theme_switcher.dart';

// Module exports (these are separate packages)
export 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
export 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
export 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';
export 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

// Import for internal use
import 'src/flutter_dev_panel_core.dart' as core;
import 'src/models/dev_panel_config.dart';
import 'src/models/dev_module.dart';

/// Flutter开发面板的主入口类
/// 提供更简洁的API访问方式
class FlutterDevPanel {
  FlutterDevPanel._();
  
  static bool _initialized = false;
  
  /// 获取单例实例
  static core.FlutterDevPanelCore get instance => core.FlutterDevPanelCore.instance;
  
  /// 初始化开发面板
  /// 
  /// 在 Release 模式下，这个方法会自动变成空操作（no-op）
  /// 用户可以直接调用，不需要手动添加 kDebugMode 判断
  /// 
  /// 示例:
  /// ```dart
  /// void main() {
  ///   FlutterDevPanel.initialize(
  ///     modules: [ConsoleModule(), NetworkModule()],
  ///   );
  ///   runApp(MyApp());
  /// }
  /// ```
  static void initialize({
    DevPanelConfig config = const DevPanelConfig(),
    List<DevModule> modules = const [],
    bool enableLogCapture = true,
  }) {
    // 使用 kDebugMode 常量，让编译器在 Release 模式完全剔除代码
    if (kDebugMode) {
      if (_initialized) return;
      _initialized = true;
      
      core.FlutterDevPanelCore.instance.initialize(
        config: config,
        modules: modules,
        enableLogCapture: enableLogCapture,
      );
    }
  }
  
  /// 打开开发面板（需要BuildContext）
  static void open(BuildContext context) {
    if (kDebugMode && _initialized) {
      core.FlutterDevPanelCore.instance.open(context);
    }
  }
  
  /// 关闭开发面板
  static void close() {
    if (kDebugMode && _initialized) {
      core.FlutterDevPanelCore.instance.close();
    }
  }
  
  /// 重置开发面板
  static void reset() {
    if (kDebugMode && _initialized) {
      core.FlutterDevPanelCore.instance.reset();
    }
  }
}