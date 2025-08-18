import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'performance_update_coordinator.dart';

class FpsTracker {
  final _fpsController = StreamController<double>.broadcast();
  Stream<double> get fpsStream => _fpsController.stream;

  final List<Duration> _frameDurations = [];
  bool _isTracking = false;
  final _updateCoordinator = PerformanceUpdateCoordinator.instance;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    SchedulerBinding.instance.addTimingsCallback(_onTimingsCallback);

    // 使用协调器替代直接创建 Timer
    _updateCoordinator.addOneSecondListener(_calculateFps);
  }

  void stopTracking() {
    if (!_isTracking) return;
    _isTracking = false;

    SchedulerBinding.instance.removeTimingsCallback(_onTimingsCallback);
    _updateCoordinator.removeOneSecondListener(_calculateFps);
    _frameDurations.clear();
  }

  void _onTimingsCallback(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frameDurations.add(timing.totalSpan);
    }
  }

  void _calculateFps() {
    if (_frameDurations.isEmpty) {
      _fpsController.add(0);
      return;
    }

    final totalDuration = _frameDurations.reduce((a, b) => a + b);
    final averageFrameDuration =
        totalDuration.inMicroseconds / _frameDurations.length;
    final fps = averageFrameDuration > 0
        ? 1000000 / averageFrameDuration
        : 0.0;

    _fpsController.add(fps.clamp(0, 120));
    _frameDurations.clear();
  }

  void dispose() {
    stopTracking();
    _fpsController.close();
  }
}