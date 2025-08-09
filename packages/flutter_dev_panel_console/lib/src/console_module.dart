import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'ui/pages/console_page.dart';

/// Console 日志模块
class ConsoleModule extends DevModule {
  const ConsoleModule()
      : super(
          id: 'console',
          name: 'Console',
          description: '查看应用日志和错误信息',
          icon: Icons.terminal,
          enabled: true,
          order: 0, // 最高优先级，显示在第一个
        );

  @override
  Widget buildPage(BuildContext context) {
    return const ConsolePage();
  }

  @override
  Widget? buildFabContent(BuildContext context) {
    // 在 FAB 中显示错误计数，更突出的样式
    final allLogs = DevLogger.instance.logs;
    final errorCount =
        allLogs.where((log) => log.level == LogLevel.error).length;
    final warningCount =
        allLogs.where((log) => log.level == LogLevel.warning).length;

    if (errorCount > 0) {
      // 有错误时显示红色背景的错误计数
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$errorCount 错误',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (warningCount > 0) {
      // 没有错误但有警告时显示橙色背景的警告计数
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$warningCount 警告',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  @override
  int get fabPriority => 1; // 最高优先级，优先显示错误计数

  @override
  Future<void> initialize() async {
    // DevLogger 已经在 core 中初始化
    // 这里可以添加额外的初始化逻辑
    DevLogger.log('Console module initialized');
  }

  @override
  void dispose() {
    // 清理资源
  }

  /// 添加测试日志的便捷方法
  static void addTestLogs() {
    DevLogger.instance.verbose('This is a verbose log message');
    DevLogger.instance.debug('Debug: Component rendered successfully');
    DevLogger.instance.info('Info: User logged in');
    DevLogger.instance.warning('Warning: API rate limit approaching',
        error: 'Rate limit: 95%');
    DevLogger.instance.error(
      'Error: Failed to fetch data',
      error: 'NetworkException: Connection timeout',
      stackTrace: '''
at fetchData (network.dart:123)
at _handleRequest (api_client.dart:45)
at main (main.dart:12)
''',
    );
  }
}
