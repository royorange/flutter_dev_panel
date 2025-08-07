import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

class FPSMonitor extends GetxController {
  static FPSMonitor get to => Get.find();
  
  final _fps = 0.0.obs;
  final _maxFps = 0.0.obs;
  final _minFps = 60.0.obs;
  final _avgFps = 0.0.obs;
  final _frameHistory = <double>[].obs;
  final _isMonitoring = false.obs;
  
  double get fps => _fps.value;
  double get maxFps => _maxFps.value;
  double get minFps => _minFps.value;
  double get avgFps => _avgFps.value;
  List<double> get frameHistory => _frameHistory;
  bool get isMonitoring => _isMonitoring.value;
  
  Timer? _timer;
  DateTime? _lastFrameTime;
  final List<double> _recentFrameTimes = [];
  final int _maxHistoryLength = 60;
  
  @override
  void onInit() {
    super.onInit();
    if (Get.arguments?['autoStart'] == true) {
      startMonitoring();
    }
  }
  
  void startMonitoring() {
    if (_isMonitoring.value) return;
    
    _isMonitoring.value = true;
    _lastFrameTime = DateTime.now();
    _recentFrameTimes.clear();
    
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    
    // Update stats every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStats();
    });
  }
  
  void stopMonitoring() {
    _isMonitoring.value = false;
    _timer?.cancel();
    _timer = null;
  }
  
  void _onFrame(Duration timestamp) {
    if (!_isMonitoring.value) return;
    
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
    if (_isMonitoring.value) {
      SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    }
  }
  
  void _updateStats() {
    if (_recentFrameTimes.isEmpty) return;
    
    // Calculate average FPS
    final avg = _recentFrameTimes.reduce((a, b) => a + b) / _recentFrameTimes.length;
    _fps.value = avg;
    _avgFps.value = avg;
    
    // Update min/max
    final sorted = List<double>.from(_recentFrameTimes)..sort();
    if (sorted.isNotEmpty) {
      final min = sorted.first;
      final max = sorted.last;
      
      if (min < _minFps.value) {
        _minFps.value = min;
      }
      if (max > _maxFps.value) {
        _maxFps.value = max;
      }
    }
    
    // Update history
    _frameHistory.add(avg);
    if (_frameHistory.length > _maxHistoryLength) {
      _frameHistory.removeAt(0);
    }
  }
  
  void reset() {
    _fps.value = 0.0;
    _maxFps.value = 0.0;
    _minFps.value = 60.0;
    _avgFps.value = 0.0;
    _frameHistory.clear();
    _recentFrameTimes.clear();
  }
  
  String getFPSStatus() {
    if (_fps.value >= 55) return '流畅';
    if (_fps.value >= 45) return '良好';
    if (_fps.value >= 30) return '一般';
    return '卡顿';
  }
  
  Color getFPSColor() {
    if (_fps.value >= 55) return Colors.green;
    if (_fps.value >= 45) return Colors.orange;
    if (_fps.value >= 30) return Colors.deepOrange;
    return Colors.red;
  }
  
  @override
  void onClose() {
    stopMonitoring();
    super.onClose();
  }
}