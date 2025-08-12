import 'package:flutter/foundation.dart';

/// 监控数据提供者，聚合各模块的监控数据
class MonitoringDataProvider extends ChangeNotifier {
  static MonitoringDataProvider? _instance;
  
  static MonitoringDataProvider get instance {
    _instance ??= MonitoringDataProvider._();
    return _instance!;
  }
  
  MonitoringDataProvider._();
  
  // 性能数据
  double? _fps;
  double? _memory;
  
  // 网络数据
  int _totalRequests = 0;
  int _errorRequests = 0;
  int _pendingRequests = 0;
  
  double? get fps => _fps;
  double? get memory => _memory;
  int get totalRequests => _totalRequests;
  int get errorRequests => _errorRequests;
  int get pendingRequests => _pendingRequests;
  
  // 更新性能数据
  void updatePerformanceData({double? fps, double? memory}) {
    bool changed = false;
    
    // 允许设置为null以清除数据
    if (fps != _fps) {
      _fps = fps;
      changed = true;
    }
    if (memory != _memory) {
      _memory = memory;
      changed = true;
    }
    
    if (changed) {
      notifyListeners();
    }
  }
  
  // 更新网络数据
  void updateNetworkData({
    int? totalRequests,
    int? errorRequests,
    int? pendingRequests,
  }) {
    bool changed = false;
    if (totalRequests != null && totalRequests != _totalRequests) {
      _totalRequests = totalRequests;
      changed = true;
    }
    if (errorRequests != null && errorRequests != _errorRequests) {
      _errorRequests = errorRequests;
      changed = true;
    }
    if (pendingRequests != null && pendingRequests != _pendingRequests) {
      _pendingRequests = pendingRequests;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
  
  // 网络请求完成
  void onRequestComplete(bool hasError) {
    _totalRequests++;
    if (hasError) {
      _errorRequests++;
    }
    if (_pendingRequests > 0) {
      _pendingRequests--;
    }
    notifyListeners();
  }
  
  // 网络请求开始
  void onRequestStart() {
    _pendingRequests++;
    notifyListeners();
  }
  
  // 重置数据
  void reset() {
    _fps = null;
    _memory = null;
    _totalRequests = 0;
    _errorRequests = 0;
    _pendingRequests = 0;
    notifyListeners();
  }
  
  // 手动触发更新通知（供其他模块使用）
  void triggerUpdate() {
    notifyListeners();
  }
}