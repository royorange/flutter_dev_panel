import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel_core/src/core/monitoring_data_provider.dart';
import 'package:battery_plus/battery_plus.dart';
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
  final Battery _battery = Battery();
  
  StreamSubscription<double>? _fpsSubscription;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _memoryTimer;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  
  double _currentFps = 0;
  double get currentFps => _currentFps;
  
  double _currentMemory = 0;
  double get currentMemory => _currentMemory;
  
  int _currentBatteryLevel = 0;
  int get currentBatteryLevel => _currentBatteryLevel;
  
  BatteryState _currentBatteryState = BatteryState.unknown;
  BatteryState get currentBatteryState => _currentBatteryState;

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
    
    // Start battery monitoring
    _startBatteryMonitoring();
    
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
    
    _batteryStateSubscription?.cancel();
    _batteryStateSubscription = null;
    
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
      batteryLevel: _currentBatteryLevel,
      batteryState: _getBatteryStateString(),
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
  
  void _startBatteryMonitoring() async {
    try {
      // Get initial battery level only once at startup
      final batteryLevel = await _battery.batteryLevel;
      _currentBatteryLevel = batteryLevel;
      
      // Get initial battery state
      final batteryState = await _battery.batteryState;
      _currentBatteryState = batteryState;
      
      // Listen to battery state changes (system broadcast)
      // This only triggers when battery state actually changes
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) async {
        _currentBatteryState = state;
        
        // When battery state changes, also update the battery level
        // This happens when plugging/unplugging charger or battery level changes significantly
        try {
          final level = await _battery.batteryLevel;
          if (level != _currentBatteryLevel) {
            _currentBatteryLevel = level;
            _updateMetrics();
          }
        } catch (_) {
          // Ignore errors
        }
        
        notifyListeners();
      });
      
      // No periodic timer needed - we rely on system events only
    } catch (_) {
      // Battery monitoring not available on this platform
      _currentBatteryLevel = -1;
    }
  }
  
  String _getBatteryStateString() {
    switch (_currentBatteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      case BatteryState.connectedNotCharging:
        return 'Connected (Not Charging)';
      case BatteryState.unknown:
        return 'Unknown';
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