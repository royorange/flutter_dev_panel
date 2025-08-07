import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FPSMonitor extends ChangeNotifier {
  static FPSMonitor? _instance;
  static FPSMonitor get instance => _instance ??= FPSMonitor._();
  
  FPSMonitor._();
  
  factory FPSMonitor() => instance;
  
  double _fps = 0.0;
  double _maxFps = 0.0;
  double _minFps = 60.0;
  double _avgFps = 0.0;
  final List<double> _frameHistory = [];
  bool _isMonitoring = false;
  
  double get fps => _fps;
  double get maxFps => _maxFps;
  double get minFps => _minFps;
  double get avgFps => _avgFps;
  List<double> get frameHistory => _frameHistory;
  bool get isMonitoring => _isMonitoring;
  
  Timer? _timer;
  DateTime? _lastFrameTime;
  final List<double> _recentFrameTimes = [];
  final int _maxHistoryLength = 60;
  
  void init({bool autoStart = false}) {
    if (autoStart) {
      startMonitoring();
    }
  }
  
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    notifyListeners();
    _lastFrameTime = DateTime.now();
    _recentFrameTimes.clear();
    
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    
    // Update stats every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStats();
    });
  }
  
  void stopMonitoring() {
    _isMonitoring = false;
    notifyListeners();
    _timer?.cancel();
    _timer = null;
  }
  
  void _onFrame(Duration timestamp) {
    if (!_isMonitoring) return;
    
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!).inMicroseconds / 1000.0;
      if (frameDuration > 0) {
        final currentFps = 1000.0 / frameDuration;
        _recentFrameTimes.add(currentFps);
        
        // Keep only recent frame times
        if (_recentFrameTimes.length > 60) {
          _recentFrameTimes.removeAt(0);
        }
      }
    }
    _lastFrameTime = now;
    
    // Schedule next frame callback
    if (_isMonitoring) {
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }
  
  void _updateStats() {
    if (_recentFrameTimes.isEmpty) return;
    
    // Calculate average FPS
    final avg = _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;
    _fps = avg;
    _avgFps = avg;
    
    // Update min/max
    final sorted = List<double>.from(_recentFrameTimes)..sort();
    if (sorted.isNotEmpty) {
      final min = sorted.first;
      final max = sorted.last;
      
      if (min < _minFps) {
        _minFps = min;
      }
      if (max > _maxFps) {
        _maxFps = max;
      }
    }
    
    // Update history
    _frameHistory.add(avg);
    if (_frameHistory.length > _maxHistoryLength) {
      _frameHistory.removeAt(0);
    }
    
    notifyListeners();
  }
  
  void reset() {
    _fps = 0.0;
    _maxFps = 0.0;
    _minFps = 60.0;
    _avgFps = 0.0;
    _frameHistory.clear();
    _recentFrameTimes.clear();
    notifyListeners();
  }
  
  String getFPSStatus() {
    if (_fps >= 55) return '流畅';
    if (_fps >= 45) return '良好';
    if (_fps >= 30) return '一般';
    return '卡顿';
  }
  
  Color getFPSColor() {
    if (_fps >= 55) return Colors.green;
    if (_fps >= 45) return Colors.orange;
    if (_fps >= 30) return Colors.deepOrange;
    return Colors.red;
  }
  
  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}