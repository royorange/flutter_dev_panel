import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../performance_monitor_controller.dart';
import 'widgets/fps_chart.dart';
import 'widgets/memory_chart.dart';
import 'widgets/battery_indicator.dart';

class PerformanceMonitorPage extends StatelessWidget {
  const PerformanceMonitorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider.value(
      value: PerformanceMonitorController.instance,
      child: Consumer<PerformanceMonitorController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Performance Monitor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        controller.isMonitoring
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        color: controller.isMonitoring
                            ? colorScheme.error
                            : colorScheme.primary,
                      ),
                      onPressed: () {
                        if (controller.isMonitoring) {
                          controller.stopMonitoring();
                        } else {
                          controller.startMonitoring();
                        }
                      },
                      tooltip: controller.isMonitoring
                          ? 'Stop Monitoring'
                          : 'Start Monitoring',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      onPressed: controller.clearData,
                      tooltip: 'Clear Data',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatusCard(context, controller),
                        const SizedBox(height: 16),
                        FpsChart(
                          metrics: controller.metrics,
                          currentFps: controller.currentFps,
                        ),
                        const SizedBox(height: 16),
                        MemoryChart(
                          metrics: controller.metrics,
                          currentMemory: controller.currentMemory,
                        ),
                        const SizedBox(height: 16),
                        BatteryIndicator(
                          batteryLevel: controller.currentBatteryLevel,
                          batteryState: controller.currentBatteryState.toString().split('.').last,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, PerformanceMonitorController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: controller.isMonitoring
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.isMonitoring
                    ? colorScheme.primary
                    : colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isMonitoring ? 'Monitoring' : 'Idle',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: controller.isMonitoring
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isMonitoring
                        ? 'Collecting performance data...'
                        : 'Press play to start monitoring',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: controller.isMonitoring
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.isMonitoring)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}