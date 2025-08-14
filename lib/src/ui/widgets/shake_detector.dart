import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

  /// 检查平台是否支持传感器
  bool get _isPlatformSupported {
    if (kIsWeb) return false;
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return false;
    }
    return true; // iOS 和 Android 默认支持
  }

  void _startListening() {
    // 不支持的平台直接跳过
    if (!_isPlatformSupported) return;
    
    try {
      _streamSubscription = userAccelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        _handleAccelerometerEvent,
        onError: (_) {}, // 静默处理错误
      );
    } catch (_) {
      // 初始化失败，静默处理
    }
  }

  void _handleAccelerometerEvent(UserAccelerometerEvent event) {
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