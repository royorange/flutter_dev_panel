import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'ui/pages/console_page.dart';

/// Console 日志模块
class ConsoleModule extends DevModule {
  const ConsoleModule() : super(
    id: 'console',
    name: '控制台',
    description: '查看应用日志和错误信息',
    icon: Icons.terminal,
    enabled: true,
    order: 20, // 显示在网络监控之后
  );

  @override
  Widget buildPage(BuildContext context) {
    return const ConsolePage();
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // 在 FAB 中显示错误计数
    final errorCount = DevLogger.instance.getFilteredLogs(minLevel: LogLevel.error).length;
    if (errorCount > 0) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          errorCount.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return null;
  }
  
  @override
  int get fabPriority => 10; // 高优先级，显示错误计数
  
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
    DevLogger.instance.warning('Warning: API rate limit approaching', error: 'Rate limit: 95%');
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