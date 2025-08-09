import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/performance_data.dart';

class MemoryChart extends StatelessWidget {
  final PerformanceMetrics metrics;
  final double currentMemory;

  const MemoryChart({
    Key? key,
    required this.metrics,
    required this.currentMemory,
  }) : super(key: key);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Memory Usage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMemoryColor(currentMemory).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentMemory.toStringAsFixed(1)} MB',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getMemoryColor(currentMemory),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                        reservedSize: 35,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: metrics.maxDataPoints.toDouble() - 1,
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getSpots(),
                      isCurved: true,
                      color: colorScheme.secondary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Average',
                  '${metrics.averageMemory.toStringAsFixed(1)} MB',
                ),
                _buildStatItem(
                  context,
                  'Min',
                  '${metrics.minMemory.toStringAsFixed(1)} MB',
                ),
                _buildStatItem(
                  context,
                  'Max',
                  '${metrics.maxMemory.toStringAsFixed(1)} MB',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    if (metrics.dataPoints.isEmpty) return 200;
    final max = metrics.maxMemory;
    return ((max / 50).ceil() * 50).toDouble().clamp(200, 1000);
  }

  List<FlSpot> _getSpots() {
    final dataPoints = metrics.dataPoints.toList();
    if (dataPoints.isEmpty) {
      return [const FlSpot(0, 0)];
    }
    
    return dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.memoryUsage);
    }).toList();
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Color _getMemoryColor(double memory) {
    // Use the same color rules as in FAB
    if (memory <= 300) return Colors.green;
    if (memory <= 500) return Colors.orange;
    return Colors.red;
  }
}