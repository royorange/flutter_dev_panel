import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/log_entry.dart';
import '../../providers/console_provider.dart';

/// 单个日志项的显示组件
class LogItem extends StatelessWidget {
  final LogEntry log;
  final ConsoleProvider provider;
  final VoidCallback? onTap;

  const LogItem({
    super.key,
    required this.log,
    required this.provider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = provider.getLevelColor(log.level);
    final timeFormat = DateFormat('HH:mm:ss.SSS');
    
    return InkWell(
      onTap: onTap ?? () => _showLogDetail(context),
      onLongPress: () => _copyToClipboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 日志级别标识
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  log.levelText,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // 日志内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间戳和消息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeFormat.format(log.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.message,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // 错误信息（如果有）
                  if (log.error != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 展开图标
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 显示日志详情
  void _showLogDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogDetailSheet(log: log, provider: provider),
    );
  }
  
  /// 复制到剪贴板
  void _copyToClipboard(BuildContext context) {
    final text = StringBuffer();
    text.writeln('[${log.levelText}] ${log.formattedTime}');
    text.writeln(log.message);
    if (log.error != null) {
      text.writeln('Error: ${log.error}');
    }
    if (log.stackTrace != null) {
      text.writeln('Stack Trace:\n${log.stackTrace}');
    }
    
    Clipboard.setData(ClipboardData(text: text.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// 日志详情底部弹窗
class LogDetailSheet extends StatelessWidget {
  final LogEntry log;
  final ConsoleProvider provider;

  const LogDetailSheet({
    super.key,
    required this.log,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = provider.getLevelColor(log.level);
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖动手柄
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        provider.getLevelIcon(log.level),
                        size: 16,
                        color: levelColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        log.levelText,
                        style: TextStyle(
                          color: levelColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context),
                  tooltip: 'Copy',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // 日志内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 时间戳
                  _buildSection(
                    context,
                    title: '时间',
                    content: timeFormat.format(log.timestamp),
                    icon: Icons.access_time,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 消息
                  _buildSection(
                    context,
                    title: '消息',
                    content: log.message,
                    icon: Icons.message,
                  ),
                  
                  // 错误信息
                  if (log.error != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: '错误',
                      content: log.error!,
                      icon: Icons.error_outline,
                      isError: true,
                    ),
                  ],
                  
                  // 堆栈跟踪
                  if (log.stackTrace != null) ...[
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: '堆栈跟踪',
                      content: log.stackTrace!,
                      icon: Icons.layers,
                      isMonospace: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    bool isError = false,
    bool isMonospace = false,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError 
              ? Colors.red.withOpacity(0.1)
              : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isError
                ? Colors.red.withOpacity(0.3)
                : theme.dividerColor.withOpacity(0.2),
            ),
          ),
          child: SelectableText(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: isMonospace ? 'monospace' : null,
              color: isError ? Colors.red : null,
            ),
          ),
        ),
      ],
    );
  }
  
  void _copyToClipboard(BuildContext context) {
    final text = StringBuffer();
    text.writeln('[${log.levelText}] ${log.formattedTime}');
    text.writeln(log.message);
    if (log.error != null) {
      text.writeln('Error: ${log.error}');
    }
    if (log.stackTrace != null) {
      text.writeln('Stack Trace:\n${log.stackTrace}');
    }
    
    Clipboard.setData(ClipboardData(text: text.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}