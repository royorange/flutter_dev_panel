import 'package:flutter/material.dart';
import '../../models/module.dart';
import 'performance_monitor_page.dart';

class PerformanceModule extends DevModule {
  PerformanceModule()
      : super(
          id: 'performance',
          name: '性能监控',
          description: '监控应用性能指标',
          icon: Icons.speed,
          type: ModuleType.performance,
          enabled: true,
          order: 4,
        );

  @override
  Widget buildPage(BuildContext context) {
    return const PerformanceMonitorPage();
  }

  @override
  Widget? buildQuickAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.speed,
            size: 16,
            color: Colors.green,
          ),
          SizedBox(width: 4),
          Text(
            'FPS',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}