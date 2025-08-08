import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 摇一摇检测器
class ShakeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onShake;
  final double threshold;

  const ShakeDetector({
    super.key,
    required this.child,
    required this.onShake,
    this.threshold = 15.0,
  });

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription<UserAccelerometerEvent>? _streamSubscription;
  static const int _shakeCountThreshold = 3;
  static const Duration _shakeDuration = Duration(milliseconds: 500);
  
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _streamSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((UserAccelerometerEvent event) {
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > widget.threshold) {
        final now = DateTime.now();
        
        if (_lastShakeTime != null &&
            now.difference(_lastShakeTime!) < _shakeDuration) {
          _shakeCount++;
          
          if (_shakeCount >= _shakeCountThreshold) {
            widget.onShake();
            _shakeCount = 0;
            _lastShakeTime = null;
          }
        } else {
          _shakeCount = 1;
          _lastShakeTime = now;
        }
      }
    }, onError: (dynamic error) {
      // 处理错误，某些设备可能不支持加速度传感器
      debugPrint('ShakeDetector error: $error');
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}