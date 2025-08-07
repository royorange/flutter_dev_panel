import 'dart:async';
import 'package:flutter/scheduler.dart';

class FpsTracker {
  final _fpsController = StreamController<double>.broadcast();
  Stream<double> get fpsStream => _fpsController.stream;

  Timer? _timer;
  final List<Duration> _frameDurations = [];
  bool _isTracking = false;

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    SchedulerBinding.instance.addTimingsCallback(_onTimingsCallback);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFps();
    });
  }

  void stopTracking() {
    if (!_isTracking) return;
    _isTracking = false;

    SchedulerBinding.instance.removeTimingsCallback(_onTimingsCallback);
    _timer?.cancel();
    _timer = null;
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