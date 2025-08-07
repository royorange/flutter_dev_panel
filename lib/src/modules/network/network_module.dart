import 'package:flutter/material.dart';
import '../../models/module.dart';
import 'network_monitor_controller.dart';
import 'network_monitor_page.dart';

class NetworkModule extends DevModule {
  NetworkModule()
      : super(
          id: 'network',
          name: '网络监控',
          description: '监控HTTP请求和响应',
          icon: Icons.wifi,
          type: ModuleType.network,
          enabled: true,
          order: 1,
        );

  @override
  Widget buildPage(BuildContext context) {
    // Controller is initialized as singleton
    return const NetworkMonitorPage();
  }

  @override
  Widget? buildQuickAction(BuildContext context) {
    final controller = NetworkMonitorController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final stats = controller.getStatistics();
        final errorCount = stats['error'] ?? 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: errorCount > 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi,
                size: 16,
                color: errorCount > 0 ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '${stats['total']} 请求',
                style: TextStyle(
                  fontSize: 12,
                  color: errorCount > 0 ? Colors.red : Colors.green,
                ),
              ),
              if (errorCount > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '($errorCount 错误)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}