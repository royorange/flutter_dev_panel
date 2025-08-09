import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import '../../providers/console_provider.dart';

/// 日志过滤栏
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
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Obx(() => Row(
        children: [
          // 全部
          _buildFilterChip(
            context,
            label: '全部',
            isSelected: provider.selectedLevel.value == null,
            onTap: () => provider.setLevelFilter(null),
          ),
          
          const SizedBox(width: 8),
          
          // 各级别过滤
          ...LogLevel.values.map((level) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildFilterChip(
              context,
              label: _getLevelLabel(level),
              isSelected: provider.selectedLevel.value == level,
              color: provider.getLevelColor(level),
              icon: provider.getLevelIcon(level),
              onTap: () => provider.setLevelFilter(level),
            ),
          )),
        ],
      )),
    );
  }
  
  /// 构建过滤芯片
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
            ? chipColor.withOpacity(0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
              ? chipColor
              : theme.dividerColor.withOpacity(0.3),
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
                  : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                  ? chipColor
                  : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取日志级别标签
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
}