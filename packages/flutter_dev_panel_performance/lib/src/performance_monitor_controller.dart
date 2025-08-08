import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel_core/src/core/monitoring_data_provider.dart';
import 'models/performance_data.dart';
import 'fps_tracker.dart';

class PerformanceMonitorController extends ChangeNotifier {
  static PerformanceMonitorController? _instance;
  
  static PerformanceMonitorController get instance {
    _instance ??= PerformanceMonitorController._();
    return _instance!;
  }
  
  PerformanceMonitorController._();
  
  final FpsTracker _fpsTracker = FpsTracker();
  final PerformanceMetrics metrics = PerformanceMetrics();
  
  StreamSubscription<double>? _fpsSubscription;
  Timer? _memoryTimer;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  
  double _currentFps = 0;
  double get currentFps => _currentFps;
  
  double _currentMemory = 0;
  double get currentMemory => _currentMemory;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _fpsTracker.startTracking();
    _fpsSubscription = _fpsTracker.fpsStream.listen((fps) {
      _currentFps = fps;
      _updateMetrics();
    });
    
    _memoryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMemoryUsage();
    });
    
    // 数据已通过MonitoringDataProvider自动通知
    
    notifyListeners();
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    
    _fpsTracker.stopTracking();
    _fpsSubscription?.cancel();
    _fpsSubscription = null;
    
    _memoryTimer?.cancel();
    _memoryTimer = null;
    
    // 清除全局监控数据
    try {
      MonitoringDataProvider.instance.updatePerformanceData(
        fps: null,
        memory: null,
      );
    } catch (_) {
      // 忽略错误
    }
    
    // 数据已通过MonitoringDataProvider自动通知
    
    notifyListeners();
  }

  void clearData() {
    metrics.clear();
    _currentFps = 0;
    _currentMemory = 0;
    notifyListeners();
  }

  void _updateMetrics() {
    final data = PerformanceData(
      timestamp: DateTime.now(),
      fps: _currentFps,
      memoryUsage: _currentMemory,
    );
    metrics.addDataPoint(data);
    
    // 更新到全局监控数据提供者
    _updateGlobalMonitoringData();
    
    notifyListeners();
  }
  
  void _updateGlobalMonitoringData() {
    try {
      MonitoringDataProvider.instance.updatePerformanceData(
        fps: _currentFps,
        memory: _currentMemory,
      );
    } catch (_) {
      // 忽略错误，避免影响主功能
    }
  }

  void _updateMemoryUsage() {
    if (Platform.isAndroid || Platform.isIOS) {
      final memoryInfo = ProcessInfo.currentRss;
      _currentMemory = memoryInfo / (1024 * 1024);
    } else {
      _currentMemory = ProcessInfo.currentRss / (1024 * 1024);
    }
    _updateMetrics();
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
  
  @override
  void dispose() {
    stopMonitoring();
    _fpsTracker.dispose();
    super.dispose();
  }
}