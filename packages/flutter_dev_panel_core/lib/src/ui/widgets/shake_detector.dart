import 'package:flutter/material.dart';

/// 摇一摇检测器（占位实现，实际功能需要sensors_plus）
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
  @override
  void initState() {
    super.initState();
    // 注意：实际实现需要sensors_plus包
    // 这里只是占位实现，具体功能在集成sensors_plus的模块中实现
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}