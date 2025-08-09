import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final int batteryLevel;
  final String batteryState;
  
  const BatteryIndicator({
    Key? key,
    required this.batteryLevel,
    required this.batteryState,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Skip if battery monitoring not available
    if (batteryLevel < 0) {
      return const SizedBox.shrink();
    }
    
    // Use primary color when battery is 0 (not initialized)
    final batteryColor = batteryLevel == 0 ? colorScheme.primary : _getBatteryColor(batteryLevel);
    final isCharging = batteryState == 'Charging';
    
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
                  isCharging ? Icons.battery_charging_full : Icons.battery_std,
                  color: batteryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: batteryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$batteryLevel%',
                    style: TextStyle(
                      color: batteryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: batteryLevel / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStateIcon(batteryState),
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  batteryState,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getBatteryColor(int level) {
    if (level <= 20) return Colors.red;
    if (level <= 50) return Colors.orange;
    return Colors.teal;
  }
  
  IconData _getStateIcon(String state) {
    switch (state) {
      case 'Charging':
        return Icons.power;
      case 'Discharging':
        return Icons.battery_alert;
      case 'Full':
        return Icons.battery_full;
      case 'Connected (Not Charging)':
        return Icons.power_off;
      default:
        return Icons.battery_unknown;
    }
  }
}