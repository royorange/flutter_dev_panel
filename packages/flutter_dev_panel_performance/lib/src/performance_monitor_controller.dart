import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
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
  Timer? _renderTimer;
  
  // Performance tracking variables
  double _peakMemory = 0;
  int _droppedFramesCount = 0;
  double _lastRenderTime = 0;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  
  double _currentFps = 0;
  double get currentFps => _currentFps;
  
  double _currentMemory = 0;
  double get currentMemory => _currentMemory;
  
  double get peakMemory => _peakMemory;
  int get droppedFrames => _droppedFramesCount;
  double get renderTime => _lastRenderTime;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _fpsTracker.startTracking();
    _fpsSubscription = _fpsTracker.fpsStream.listen((fps) {
      _currentFps = fps;
      _updateMetrics();
    });
    
    // Update memory usage less frequently to reduce performance impact
    _memoryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateMemoryUsage();
    });
    
    // Track render metrics
    _startRenderTracking();
    
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
    
    _renderTimer?.cancel();
    _renderTimer = null;
    
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
    _peakMemory = 0;
    _droppedFramesCount = 0;
    _lastRenderTime = 0;
    notifyListeners();
  }

  void _updateMetrics() {
    final data = PerformanceData(
      timestamp: DateTime.now(),
      fps: _currentFps,
      memoryUsage: _currentMemory,
      peakMemory: _peakMemory,
      droppedFrames: _droppedFramesCount,
      renderTime: _lastRenderTime,
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
    // Get current memory usage
    final memoryInfo = ProcessInfo.currentRss;
    _currentMemory = memoryInfo / (1024 * 1024);
    
    // Track peak memory
    if (_currentMemory > _peakMemory) {
      _peakMemory = _currentMemory;
    }
    
    // Get max RSS (peak memory usage)
    try {
      final maxRss = ProcessInfo.maxRss;
      final maxMemory = maxRss / (1024 * 1024);
      if (maxMemory > _peakMemory) {
        _peakMemory = maxMemory;
      }
    } catch (_) {
      // maxRss might not be available on all platforms
    }
    
    _updateMetrics();
  }
  
  void _startRenderTracking() {
    // Track frame rendering metrics
    // Use a lower frequency to avoid performance impact
    _renderTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRenderMetrics();
    });
  }
  
  void _updateRenderMetrics() {
    try {
      // Track dropped frames (simplified approach)
      // In a real implementation, you'd track frame callbacks
      if (_currentFps < 55 && _currentFps > 0) {
        // Estimate dropped frames based on FPS
        const expectedFrames = 60;
        final actualFrames = _currentFps.round();
        _droppedFramesCount += max(0, expectedFrames - actualFrames);
      }
      
      // Estimate render time based on FPS
      if (_currentFps > 0) {
        _lastRenderTime = 1000 / _currentFps; // Convert to milliseconds
      }
    } catch (_) {
      // Ignore errors in render tracking
    }
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