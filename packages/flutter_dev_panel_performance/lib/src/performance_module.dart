import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'ui/performance_monitor_page.dart';

class PerformanceModule extends DevModule {
  const PerformanceModule()
      : super(
          id: 'performance',
          name: 'Performance',
          description: 'Monitor app performance metrics including FPS and memory usage',
          icon: Icons.speed,
        );

  @override
  Widget buildPage(BuildContext context) {
    return const PerformanceMonitorPage();
  }
}