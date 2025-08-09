import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import '../../providers/console_provider.dart';
import '../widgets/log_item.dart';
import '../widgets/log_filter_bar.dart';

/// Console 日志页面
class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Get.put(ConsoleProvider());
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // 顶部工具栏
          _buildToolbar(context, provider),
          
          // 过滤栏
          LogFilterBar(provider: provider),
          
          // 日志列表
          Expanded(
            child: Obx(() {
              if (provider.filteredLogs.isEmpty) {
                return _buildEmptyState(context);
              }
              
              return ListView.builder(
                controller: provider.scrollController,
                itemCount: provider.filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = provider.filteredLogs[index];
                  return LogItem(
                    key: ValueKey('${log.timestamp.millisecondsSinceEpoch}_$index'),
                    log: log,
                    provider: provider,
                  );
                },
              );
            }),
          ),
          
          // 底部状态栏
          _buildStatusBar(context, provider),
        ],
      ),
    );
  }
  
  /// 构建顶部工具栏
  Widget _buildToolbar(BuildContext context, ConsoleProvider provider) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 搜索框
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => provider.searchText.value = value,
                      decoration: InputDecoration(
                        hintText: '搜索日志...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Obx(() {
                    if (provider.searchText.value.isNotEmpty) {
                      return IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => provider.searchText.value = '',
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 暂停/继续按钮
          Obx(() => IconButton(
            icon: Icon(
              provider.isPaused.value ? Icons.play_arrow : Icons.pause,
              size: 20,
            ),
            onPressed: provider.togglePause,
            tooltip: provider.isPaused.value ? '继续' : '暂停',
          )),
          
          // 自动滚动按钮
          Obx(() => IconButton(
            icon: Icon(
              provider.autoScroll.value 
                ? Icons.vertical_align_bottom 
                : Icons.vertical_align_center,
              size: 20,
            ),
            onPressed: provider.toggleAutoScroll,
            tooltip: provider.autoScroll.value ? '关闭自动滚动' : '开启自动滚动',
          )),
          
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.clear_all, size: 20),
            onPressed: () => _showClearConfirmDialog(context, provider),
            tooltip: '清空日志',
          ),
        ],
      ),
    );
  }
  
  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无日志',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待应用产生日志...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建底部状态栏
  Widget _buildStatusBar(BuildContext context, ConsoleProvider provider) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 日志统计
          Obx(() {
            final stats = provider.getLogStatistics();
            return Row(
              children: [
                _buildStatChip(
                  context,
                  count: stats[LogLevel.error] ?? 0,
                  color: Colors.red,
                  icon: Icons.error_outline,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  count: stats[LogLevel.warning] ?? 0,
                  color: Colors.orange,
                  icon: Icons.warning_amber,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  count: stats[LogLevel.info] ?? 0,
                  color: Colors.green,
                  icon: Icons.info_outline,
                ),
              ],
            );
          }),
          
          const Spacer(),
          
          // 总日志数
          Obx(() => Text(
            '共 ${provider.filteredLogs.length} / ${provider.logs.length} 条',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          )),
        ],
      ),
    );
  }
  
  /// 构建统计芯片
  Widget _buildStatChip(
    BuildContext context, {
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    if (count == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 显示清空确认对话框
  void _showClearConfirmDialog(BuildContext context, ConsoleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('确定要清空所有日志吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.clearLogs();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('日志已清空'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              '清空',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}