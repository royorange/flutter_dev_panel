import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:get/get.dart';
import '../../core/dev_panel_controller.dart';

class ShakeDetector extends StatefulWidget {
  final Widget child;
  final double shakeThreshold;
  final Duration shakeDuration;
  final VoidCallback? onShake;

  const ShakeDetector({
    super.key,
    required this.child,
    this.shakeThreshold = 2.7,
    this.shakeDuration = const Duration(milliseconds: 500),
    this.onShake,
  });

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  StreamSubscription? _subscription;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription = userAccelerometerEventStream().listen((event) {
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > widget.shakeThreshold) {
        final now = DateTime.now();
        
        if (_lastShakeTime == null || 
            now.difference(_lastShakeTime!) > widget.shakeDuration) {
          _shakeCount = 0;
        }
        
        _shakeCount++;
        _lastShakeTime = now;
        
        if (_shakeCount >= 3) {
          _shakeCount = 0;
          _onShakeDetected();
        }
      }
    });
  }

  void _onShakeDetected() {
    if (widget.onShake != null) {
      widget.onShake!();
    } else {
      DevPanelController.to.show();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}