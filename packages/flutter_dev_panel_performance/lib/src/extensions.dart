import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'performance_module.dart';
import 'performance_api.dart';

/// Performance 模块的扩展
/// 为 DevPanelAPI 添加 performance 属性
extension PerformanceExtension on DevPanelAPI {
  /// 获取 Performance API
  /// 
  /// 使用示例:
  /// ```dart
  /// // 需要先获取 DevPanel 实例
  /// DevPanel.instance.performance?.startMonitoring();
  /// 
  /// // 或者通过 get() 方法（更简洁）
  /// DevPanel.get().performance?.startMonitoring();
  /// ```
  PerformanceAPI? get performance {
    if (!DevPanel.isInitialized) {
      if (kDebugMode) {
        debugPrint('DevPanel: Not initialized. Call DevPanel.initialize() first.');
      }
      return null;
    }
    
    final module = DevPanel.getModule<PerformanceModule>();
    if (module == null) {
      if (kDebugMode) {
        debugPrint('Performance module not installed. Add flutter_dev_panel_performance to pubspec.yaml');
      }
      return null;
    }
    
    return module.api;
  }
}