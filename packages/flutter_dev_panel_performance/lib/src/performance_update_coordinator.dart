import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance 模块的统一更新协调器
/// 使用单一 Timer 来协调所有性能数据的更新，减少 Timer 数量
class PerformanceUpdateCoordinator {
  static PerformanceUpdateCoordinator? _instance;
  static PerformanceUpdateCoordinator get instance {
    _instance ??= PerformanceUpdateCoordinator._();
    return _instance!;
  }
  
  PerformanceUpdateCoordinator._();
  
  Timer? _masterTimer;
  int _tickCount = 0;
  
  // 监听器列表
  final List<VoidCallback> _oneSecondListeners = [];
  final List<VoidCallback> _twoSecondListeners = [];
  
  /// 启动协调器
  void start() {
    if (_masterTimer != null) return;
    
    _tickCount = 0;
    _masterTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCount++;
      
      // 每秒执行
      for (final listener in _oneSecondListeners) {
        try {
          listener();
        } catch (e) {
          if (kDebugMode) {
            print('PerformanceUpdateCoordinator: Error in 1s listener: $e');
          }
        }
      }
      
      // 每2秒执行
      if (_tickCount % 2 == 0) {
        for (final listener in _twoSecondListeners) {
          try {
            listener();
          } catch (e) {
            if (kDebugMode) {
              print('PerformanceUpdateCoordinator: Error in 2s listener: $e');
            }
          }
        }
      }
    });
  }
  
  /// 停止协调器
  void stop() {
    _masterTimer?.cancel();
    _masterTimer = null;
    _tickCount = 0;
  }
  
  /// 添加每秒执行的监听器
  void addOneSecondListener(VoidCallback listener) {
    if (!_oneSecondListeners.contains(listener)) {
      _oneSecondListeners.add(listener);
    }
  }
  
  /// 移除每秒执行的监听器
  void removeOneSecondListener(VoidCallback listener) {
    _oneSecondListeners.remove(listener);
  }
  
  /// 添加每2秒执行的监听器
  void addTwoSecondListener(VoidCallback listener) {
    if (!_twoSecondListeners.contains(listener)) {
      _twoSecondListeners.add(listener);
    }
  }
  
  /// 移除每2秒执行的监听器
  void removeTwoSecondListener(VoidCallback listener) {
    _twoSecondListeners.remove(listener);
  }
  
  /// 清理所有监听器
  void clearAllListeners() {
    _oneSecondListeners.clear();
    _twoSecondListeners.clear();
  }
  
  /// 是否正在运行
  bool get isRunning => _masterTimer != null;
  
  /// 重置实例（用于测试）
  static void reset() {
    _instance?.stop();
    _instance?.clearAllListeners();
    _instance = null;
  }
}