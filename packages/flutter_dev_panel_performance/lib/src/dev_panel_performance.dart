import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'performance_module.dart';
import 'performance_api.dart';

/// Performance 模块的便捷访问类
/// 
/// 使用示例:
/// ```dart
/// import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';
/// 
/// // 使用便捷访问
/// DevPanelPerformance.startMonitoring();
/// DevPanelPerformance.trackTimer(myTimer);
/// 
/// // 或者通过 api 属性
/// DevPanelPerformance.api?.currentFps;
/// ```
class DevPanelPerformance {
  DevPanelPerformance._();
  
  /// 获取 Performance 模块的 API
  static PerformanceAPI? get api {
    // 检查 DevPanel 是否已初始化
    if (!DevPanel.isInitialized) {
      if (kDebugMode) {
        debugPrint('DevPanel: Not initialized. Please call DevPanel.initialize() first.');
      }
      return null;
    }
    
    // 检查模块是否已安装
    if (!DevPanel.hasModule('performance')) {
      if (kDebugMode) {
        debugPrint('DevPanelPerformance: Performance module not installed.\n'
            'To use performance monitoring, add to pubspec.yaml:\n'
            '  flutter_dev_panel_performance: ^latest_version\n'
            'And register the module:\n'
            '  DevPanel.initialize(modules: [PerformanceModule()])');
      }
      return null;
    }
    
    // 获取模块
    final module = DevPanel.getModule<PerformanceModule>();
    if (module == null) {
      if (kDebugMode) {
        debugPrint('DevPanelPerformance: Failed to get PerformanceModule instance.');
      }
      return null;
    }
    
    // 返回 API
    return module.api;
  }
  
  // ========== 便捷方法 ==========
  
  static void startMonitoring() => api?.startMonitoring();
  static void stopMonitoring() => api?.stopMonitoring();
  static bool get isMonitoring => api?.isMonitoring ?? false;
  
  static double get currentFps => api?.currentFps ?? 0;
  static double get currentMemory => api?.currentMemory ?? 0;
  
  static void trackTimer(Timer timer) => api?.trackTimer(timer);
  static void trackSubscription(StreamSubscription subscription) => 
      api?.trackSubscription(subscription);
  
  static bool get hasPotentialLeak => api?.hasPotentialLeak ?? false;
  static String get memorySummary => api?.memorySummary ?? 'N/A';
}