import 'dart:async';
import 'package:flutter/foundation.dart';
import 'performance_monitor_controller.dart';
import 'leak_detector.dart';

/// Performance 模块的公共 API
/// 通过 DevPanel.performance 访问
class PerformanceAPI {
  static PerformanceAPI? _instance;
  static PerformanceAPI get instance {
    _instance ??= PerformanceAPI._();
    return _instance!;
  }
  
  PerformanceAPI._();
  
  bool _autoTrackingEnabled = true;  // 默认启用
  
  /// 获取控制器实例（内部使用）
  PerformanceMonitorController get _controller => PerformanceMonitorController.instance;
  
  /// 获取泄露检测器（内部使用）
  LeakDetector get _leakDetector => LeakDetector.instance;
  
  // ========== 监控控制 ==========
  
  /// 开始性能监控
  /// 
  /// @param enableAutoTracking 是否启用自动 Timer 追踪（可选，默认使用模块配置）
  void startMonitoring({bool? enableAutoTracking}) {
    if (enableAutoTracking != null) {
      _autoTrackingEnabled = enableAutoTracking;
      if (_autoTrackingEnabled) {
        _leakDetector.enableAutoTracking();
      }
    }
    _controller.startMonitoring();
  }
  
  /// 停止性能监控
  void stopMonitoring() => _controller.stopMonitoring();
  
  /// 监控状态
  bool get isMonitoring => _controller.isMonitoring;
  
  /// 清除数据
  void clearData() => _controller.clearData();
  
  // ========== 性能指标 ==========
  
  /// 当前 FPS
  double get currentFps => _controller.currentFps;
  
  /// 当前内存使用（MB）
  double get currentMemory => _controller.currentMemory;
  
  /// 峰值内存（MB）
  double get peakMemory => _controller.peakMemory;
  
  /// 丢帧数
  int get droppedFrames => _controller.droppedFrames;
  
  /// 渲染时间（ms）
  double get renderTime => _controller.renderTime;
  
  // ========== 资源追踪 ==========
  
  /// 追踪 Timer
  /// 
  /// 示例:
  /// ```dart
  /// final timer = Timer.periodic(Duration(seconds: 1), (_) {
  ///   // do something
  /// });
  /// DevPanel.performance.trackTimer(timer);
  /// ```
  void trackTimer(Timer timer) => _leakDetector.trackTimer(timer);
  
  /// 追踪 StreamSubscription
  /// 
  /// 示例:
  /// ```dart
  /// final subscription = stream.listen((data) {
  ///   // handle data
  /// });
  /// DevPanel.performance.trackSubscription(subscription);
  /// ```
  void trackSubscription(StreamSubscription subscription) => 
      _leakDetector.trackSubscription(subscription);
  
  /// 获取活跃的 Timer 数量
  int get activeTimerCount => _leakDetector.activeTimerCount;
  
  /// 获取活跃的 StreamSubscription 数量
  int get activeSubscriptionCount => _leakDetector.activeSubscriptionCount;
  
  // ========== 内存分析 ==========
  
  /// 分析内存增长情况
  MemoryGrowthAnalysis analyzeMemoryGrowth() => _leakDetector.analyzeMemoryGrowth();
  
  /// 获取调试信息
  Map<String, dynamic> getDebugInfo() => _leakDetector.getDebugInfo();
  
  /// 手动记录内存快照（通常不需要手动调用）
  void recordMemorySnapshot(double memoryMB) => 
      _leakDetector.recordMemorySnapshot(memoryMB);
  
  // ========== 便捷方法 ==========
  
  /// 检查是否有潜在的内存泄露
  bool get hasPotentialLeak {
    final analysis = analyzeMemoryGrowth();
    return analysis.isGrowing || 
           activeTimerCount > 10 || 
           activeSubscriptionCount > 10;
  }
  
  /// 获取内存状态摘要
  String get memorySummary {
    final analysis = analyzeMemoryGrowth();
    if (!analysis.isGrowing) {
      return 'Memory stable';
    }
    return 'Memory growing: ${analysis.growthRateMBPerMinute.toStringAsFixed(1)} MB/min';
  }
  
  /// 获取资源摘要
  String get resourceSummary {
    return 'Timers: $activeTimerCount, Subscriptions: $activeSubscriptionCount';
  }
  
  // ========== 自动追踪功能 ==========
  
  /// 是否已启用自动追踪
  bool get isAutoTrackingEnabled => _autoTrackingEnabled;
  
  /// 设置自动追踪状态（由模块初始化时调用）
  void setAutoTrackingEnabled(bool enabled) {
    _autoTrackingEnabled = enabled;
    if (enabled) {
      _leakDetector.enableAutoTracking();
      if (kDebugMode) {
        debugPrint('Performance: Auto Timer tracking enabled');
      }
    }
  }
  
  /// 创建用于自动追踪的 ZoneSpecification
  /// 
  /// 在 DevPanel.init() 或 runZonedGuarded 中使用
  ZoneSpecification? createZoneSpecification() {
    if (!_autoTrackingEnabled || !kDebugMode) {
      return null;
    }
    
    return _leakDetector.createAutoTrackingZone();
  }
  
  /// 获取资源追踪统计
  Map<String, int> get resourceStats {
    final debugInfo = _leakDetector.getDebugInfo();
    return {
      'totalTimers': debugInfo['activeTimers'] ?? 0,
      'autoTrackedTimers': debugInfo['autoTrackedTimers'] ?? 0,
      'manualTrackedTimers': debugInfo['manualTrackedTimers'] ?? 0,
      'subscriptions': debugInfo['activeSubscriptions'] ?? 0,
    };
  }
}