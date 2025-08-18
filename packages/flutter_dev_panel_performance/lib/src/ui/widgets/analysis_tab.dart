import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../leak_detector.dart';

class AnalysisTab extends StatefulWidget {
  final LeakDetector leakDetector;
  final List<double> memoryHistory;
  final bool hideInternalTimers;
  final int maxTimersToShow;

  const AnalysisTab({
    Key? key,
    required this.leakDetector,
    required this.memoryHistory,
    this.hideInternalTimers = true,
    this.maxTimersToShow = 5,
  }) : super(key: key);

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  Timer? _updateTimer;
  bool _showTimerDetails = false; // 控制 Timer 列表展开状态

  @override
  void initState() {
    super.initState();
    // 只有在有数据时才启动更新 Timer
    _startUpdateTimerIfNeeded();
  }

  @override
  void didUpdateWidget(AnalysisTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 memoryHistory 变化时检查是否需要启动/停止 Timer
    if (oldWidget.memoryHistory.isEmpty && widget.memoryHistory.isNotEmpty) {
      _startUpdateTimerIfNeeded();
    } else if (oldWidget.memoryHistory.isNotEmpty &&
        widget.memoryHistory.isEmpty) {
      _stopUpdateTimer();
    }
  }

  void _startUpdateTimerIfNeeded() {
    // 只有在监控中（有数据）时才启动 Timer
    if (widget.memoryHistory.isNotEmpty && _updateTimer == null) {
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted && widget.memoryHistory.isNotEmpty) {
          // 记录内存快照
          widget.leakDetector.recordMemorySnapshot(widget.memoryHistory.last);
          setState(() {});
        }
      });
    }
  }

  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  @override
  void dispose() {
    _stopUpdateTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取调试信息
    final debugInfo = widget.leakDetector.getDebugInfo();
    final memoryAnalysis = widget.leakDetector.analyzeMemoryGrowth();

    // 不在 build 中记录快照，避免频繁调用

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 内存状态卡片
          _buildMemoryStatusCard(context, memoryAnalysis),
          const SizedBox(height: 16),

          // 资源泄露检测卡片
          _buildLeakDetectionCard(context, debugInfo),
          const SizedBox(height: 16),

          // 实用建议卡片
          _buildActionableAdviceCard(context, debugInfo, memoryAnalysis),
        ],
      ),
    );
  }

  Widget _buildMemoryStatusCard(
    BuildContext context,
    MemoryGrowthAnalysis analysis,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 检查是否正在收集数据（需要有数据点才算开始收集）
    final isCollectingData = (analysis.suggestion.contains('Collecting data') ||
            analysis.suggestion.contains('Need more')) &&
        widget.memoryHistory.isNotEmpty; // 只有有数据时才显示收集状态

    // 检查是否未开始监控
    final notStarted = widget.memoryHistory.isEmpty;

    final isStable = !analysis.isGrowing;
    final statusColor = notStarted
        ? colorScheme.onSurfaceVariant
        : isCollectingData
            ? colorScheme.primary
            : (isStable
                ? Colors.green
                : (analysis.growthRateMBPerMinute > 10
                    ? Colors.red
                    : Colors.orange));
    final statusIcon = notStarted
        ? Icons.play_circle_outline
        : isCollectingData
            ? null // 收集数据时不显示图标
            : (isStable ? Icons.check_circle : Icons.warning_amber);
    final statusText = notStarted
        ? 'Not Monitoring'
        : isCollectingData
            ? 'Analyzing'
            : (isStable ? 'Stable' : 'Growing');

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
                if (isCollectingData)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  )
                else if (statusIcon != null)
                  Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Memory Status: $statusText',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!notStarted &&
                !isCollectingData &&
                analysis.growthRateMBPerMinute.abs() > 0.1) ...[
              _buildMetricRowWithIcon(
                context,
                'Growth Rate',
                '${analysis.growthRateMBPerMinute.abs().toStringAsFixed(1)} MB/min',
                statusColor,
                icon: analysis.growthRateMBPerMinute > 0
                    ? Icons.trending_up
                    : Icons.trending_down,
              ),
              const SizedBox(height: 8),
            ],
            if (notStarted) ...[
              Text(
                'Start monitoring to analyze memory usage',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  if (isCollectingData)
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (isCollectingData) const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      analysis.suggestion,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeakDetectionCard(
    BuildContext context,
    Map<String, dynamic> debugInfo,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeTimers = debugInfo['activeTimers'] as int;
    final activeSubscriptions = debugInfo['activeSubscriptions'] as int;

    // 判断是否有潜在问题
    final hasTimerIssue = activeTimers > 10;
    final hasSubscriptionIssue = activeSubscriptions > 10;
    final hasIssue = hasTimerIssue || hasSubscriptionIssue;

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
                  hasIssue ? Icons.bug_report : Icons.memory,
                  color: hasIssue ? Colors.orange : colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Resource Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: activeTimers > 0
                  ? () {
                      setState(() {
                        _showTimerDetails = !_showTimerDetails;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: _buildMetricRowWithAction(
                context,
                'Active Timers',
                '$activeTimers',
                hasTimerIssue ? Colors.orange : colorScheme.primary,
                trailing: activeTimers > 0
                    ? Icon(
                        _showTimerDetails
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),

            // Timer 详情列表
            if (_showTimerDetails && activeTimers > 0) ...[
              const SizedBox(height: 8),
              _buildTimerDetailsList(context, debugInfo),
            ],

            const SizedBox(height: 8),
            _buildMetricRow(
              context,
              'Active Subscriptions',
              '$activeSubscriptions',
              hasSubscriptionIssue ? Colors.orange : colorScheme.primary,
            ),
            if (hasIssue) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasTimerIssue
                          ? 'High number of active timers detected'
                          : 'High number of active subscriptions detected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionableAdviceCard(
    BuildContext context,
    Map<String, dynamic> debugInfo,
    MemoryGrowthAnalysis memoryAnalysis,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeTimers = debugInfo['activeTimers'] as int;
    final activeSubscriptions = debugInfo['activeSubscriptions'] as int;

    final advice = <String>[];

    // 实用的建议
    if (memoryAnalysis.growthRateMBPerMinute > 20) {
      advice.add('🔴 Immediate action needed: Memory growing rapidly');
      advice.add('• Check for infinite loops or recursive calls');
      advice.add('• Review recent code changes');
    } else if (memoryAnalysis.growthRateMBPerMinute > 10) {
      advice.add('🟠 Memory leak likely detected');
      advice.add('• Check dispose() methods in StatefulWidgets');
      advice.add('• Verify stream subscriptions are canceled');
    }

    if (activeTimers > 10) {
      advice.add('⏱️ Too many active timers ($activeTimers)');
      advice.add('• Ensure Timer.cancel() is called in dispose()');
      advice
          .add('• Consider using Timer.periodic() instead of multiple timers');
    }

    if (activeSubscriptions > 10) {
      advice.add('📡 Too many stream subscriptions ($activeSubscriptions)');
      advice.add('• Call subscription.cancel() in dispose()');
      advice.add('• Use StreamBuilder for automatic cleanup');
    }

    // 如果没有问题，不显示 Advice 卡片
    if (advice.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  Icons.tips_and_updates_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Actionable Advice',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...advice.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: item.startsWith('•')
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: item.startsWith('•')
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRowWithIcon(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: valueColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRowWithAction(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: valueColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDetailsList(
      BuildContext context, Map<String, dynamic> debugInfo) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    var timerInfos = debugInfo['timerInfos'] as List<TimerInfo>? ?? [];

    // 根据设置过滤内部 Timer
    if (widget.hideInternalTimers) {
      timerInfos = timerInfos.where((info) => !info.isInternalTimer).toList();
    }

    final totalTimerCount =
        (debugInfo['timerInfos'] as List<TimerInfo>? ?? []).length;

    if (timerInfos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.hideInternalTimers && totalTimerCount > 0
              ? 'All timers are internal (setting in config above)'
              : 'No timer details available',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 限制显示数量
    final timersToShow = timerInfos.take(widget.maxTimersToShow).toList();
    final hasMoreTimers = timerInfos.length > widget.maxTimersToShow;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Timer 列表
          ...timersToShow.map((info) {
            final location = info.location;
            final isPeriodic = info.isPeriodic;

            // 格式化创建时间为 HH:mm:ss
            final timeStr = '${info.createdAt.hour.toString().padLeft(2, '0')}:'
                '${info.createdAt.minute.toString().padLeft(2, '0')}:'
                '${info.createdAt.second.toString().padLeft(2, '0')}';

            return InkWell(
              onTap: () => _showTimerDetailsDialog(context, info),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isPeriodic ? Icons.loop : Icons.timer,
                      size: 16,
                      color: isPeriodic ? Colors.orange : colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${isPeriodic ? "Periodic" : "One-time"} • $timeStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            );
          }),
          // 如果有更多 Timer，显示提示
          if (hasMoreTimers) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing ${widget.maxTimersToShow} of ${timerInfos.length} timers. '
                      'Adjust limit in settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showTimerDetailsDialog(BuildContext context, TimerInfo info) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              info.isPeriodic ? Icons.loop : Icons.timer,
              color: info.isPeriodic ? Colors.orange : colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Text(info.isPeriodic ? 'Periodic Timer' : 'One-time Timer'),
            ),
            if (info.isInternalTimer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Internal',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Location', info.location),
              const SizedBox(height: 12),
              _buildDetailRow('Created', info.createdAt.toString()),
              const SizedBox(height: 12),
              _buildDetailRow(
                  'Type', info.isPeriodic ? 'Periodic' : 'One-time'),
              const SizedBox(height: 12),
              _buildDetailRow('Active', info.timer.isActive ? 'Yes' : 'No'),
              if (info.stackTrace != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stack Trace',
                      style: theme.textTheme.titleSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy stack trace',
                      onPressed: () {
                        // 复制到剪贴板
                        Clipboard.setData(ClipboardData(
                          text: info.stackTrace.toString(),
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stack trace copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    info.stackTrace.toString().split('\n').take(15).join('\n'),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (info.stackTrace != null)
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                  text: 'Timer Details:\n'
                      'Location: ${info.location}\n'
                      'Created: ${info.createdAt}\n'
                      'Type: ${info.isPeriodic ? "Periodic" : "One-time"}\n'
                      'Active: ${info.timer.isActive ? "Yes" : "No"}\n\n'
                      'Stack Trace:\n${info.stackTrace}',
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All details copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy All'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
