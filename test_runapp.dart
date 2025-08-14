import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// 注意：在实际使用中，这些模块应该从独立的包导入
// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
// import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 模拟你的初始化代码
  await Future.delayed(const Duration(milliseconds: 100));
  print('App initialization completed');
  
  // 使用新的 DevPanel.runApp 方法
  // 这会自动设置 Zone 来拦截 print 语句
  DevPanel.runApp(
    const MyApp(),
    config: const DevPanelConfig(
      triggerModes: {
        TriggerMode.fab,
        TriggerMode.shake,
      },
    ),
    modules: [
      // ConsoleModule(),
      // NetworkModule(),
      // 其他模块...
    ],
    enableLogCapture: true,
    onError: (error, stack) {
      // 自定义错误处理
      print('Custom error handler: $error');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test DevPanel.runApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 使用 builder 包装 DevPanelWrapper
      builder: (context, child) {
        return DevPanelWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test DevPanel.runApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => DevPanel.open(context),
            tooltip: 'Open Dev Panel',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DevPanel.runApp 测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // 这些 print 语句会被自动捕获
                print('Test print statement 1');
                print('Test print statement 2');
                debugPrint('Test debugPrint statement');
              },
              icon: const Icon(Icons.print),
              label: const Text('Test Print Capture'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // 测试直接使用 DevLogger
                DevLogger.instance.info('Direct info log');
                DevLogger.instance.warning('Direct warning log');
                DevLogger.instance.error('Direct error log');
              },
              icon: const Icon(Icons.terminal),
              label: const Text('Test DevLogger'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // 测试错误抛出
                throw Exception('Test exception');
              },
              icon: const Icon(Icons.error),
              label: const Text('Throw Exception'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '✅ 特性',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• 自动拦截 print 语句'),
                    const Text('• 自动捕获 Logger 包输出'),
                    const Text('• 自动捕获未处理的错误'),
                    const Text('• Release 模式自动禁用'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}