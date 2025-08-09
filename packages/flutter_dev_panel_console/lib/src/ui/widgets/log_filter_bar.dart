import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import '../../providers/console_provider.dart';

/// Log filter bar widget
class LogFilterBar extends StatelessWidget {
  final ConsoleProvider provider;

  const LogFilterBar({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // All
                _buildFilterChip(
                  context,
                  label: 'All',
                  isSelected: provider.selectedLevel == null,
                  onTap: () => provider.setLevelFilter(null),
                ),
                
                const SizedBox(width: 8),
                
                // Level filters
                ...LogLevel.values.map((level) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildFilterChip(
                    context,
                    label: _getLevelLabel(level),
                    isSelected: provider.selectedLevel == level,
                    color: _getLevelColor(level),
                    icon: _getLevelIcon(level),
                    onTap: () => provider.setLevelFilter(level),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// Build filter chip
  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
            ? chipColor.withValues(alpha: 0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? chipColor
              : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                  ? chipColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                  ? chipColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Get log level label
  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return 'Verbose';
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }
  
  /// Get log level color
  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
  
  /// Get log level icon
  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Icons.text_snippet;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }
}