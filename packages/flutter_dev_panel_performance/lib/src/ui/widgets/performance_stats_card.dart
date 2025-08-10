import 'package:flutter/material.dart';
import '../../performance_monitor_controller.dart';

class PerformanceStatsCard extends StatelessWidget {
  final PerformanceMonitorController controller;
  
  const PerformanceStatsCard({
    super.key,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Stats',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.memory,
                    label: 'Peak Memory',
                    value: '${controller.peakMemory.toStringAsFixed(1)} MB',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.timer_outlined,
                    label: 'Render Time',
                    value: '${controller.renderTime.toStringAsFixed(1)} ms',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.broken_image_outlined,
                    label: 'Dropped Frames',
                    value: controller.droppedFrames.toString(),
                    color: controller.droppedFrames > 0 ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    context,
                    icon: Icons.speed,
                    label: 'Avg FPS',
                    value: controller.metrics.averageFps.toStringAsFixed(1),
                    color: _getFpsColor(controller.metrics.averageFps),
                  ),
                ),
              ],
            ),
            
            if (controller.metrics.dataPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildMemoryTrend(context),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMemoryTrend(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = controller.metrics;
    
    // Calculate memory growth trend
    final dataPoints = metrics.dataPoints.toList();
    if (dataPoints.length < 2) return const SizedBox.shrink();
    
    final recentPoints = dataPoints.length > 10 
        ? dataPoints.sublist(dataPoints.length - 10) 
        : dataPoints;
    
    final firstMemory = recentPoints.first.memoryUsage;
    final lastMemory = recentPoints.last.memoryUsage;
    final memoryDiff = lastMemory - firstMemory;
    final isIncreasing = memoryDiff > 1; // More than 1MB increase
    final isDecreasing = memoryDiff < -1; // More than 1MB decrease
    
    if (!isIncreasing && !isDecreasing) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isIncreasing 
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIncreasing
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isIncreasing ? Icons.trending_up : Icons.trending_down,
            size: 20,
            color: isIncreasing ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Memory ${isIncreasing ? "increasing" : "decreasing"}: '
              '${memoryDiff.abs().toStringAsFixed(1)} MB in last 10 samples',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isIncreasing ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }
}