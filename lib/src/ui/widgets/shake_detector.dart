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

  void _startListening() {
    // Skip shake detection on desktop platforms
    if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
      return;
    }
    
    try {
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
        // Silently handle errors - expected on platforms without accelerometer
        // Only log in debug mode to avoid cluttering the console
        if (kDebugMode) {
          // Check if it's a platform-specific error
          if (error.toString().contains('MissingPluginException') ||
              error.toString().contains('No implementation found')) {
            // This is expected on desktop/web, don't log
          } else {
            // Unexpected error, worth logging
            debugPrint('ShakeDetector: Unexpected error - $error');
          }
        }
      });
    } catch (e) {
      // Initialization failed - this is normal on unsupported platforms
      if (kDebugMode && !e.toString().contains('MissingPluginException')) {
        debugPrint('ShakeDetector: Could not initialize - $e');
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