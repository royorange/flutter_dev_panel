import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'packages/flutter_dev_panel_console/lib/flutter_dev_panel_console.dart';

// 测试新的 DevPanel.init helper
void main() {
  // 方法1: 使用 DevPanel.init
  DevPanel.init(
    () => runApp(MyApp()),
    modules: [ConsoleModule()],
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
    ),
  );
  
  // 方法2: 使用 extension（更简洁）
  // (() => runApp(MyApp())).withDevPanel(
  //   modules: [ConsoleModule()],
  // );
  
  // 方法3: 使用 wrap 方法
  // DevPanelApp.wrap(originalMain, modules: [ConsoleModule()]);
}

// void originalMain() {
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevPanelApp Test',
      home: DevPanelWrapper(
        child: TestScreen(),
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DevPanelApp Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // 测试 print 是否被自动捕获
                print('Testing print from DevPanelApp');
                print('This should be captured automatically!');
              },
              child: Text('Test Print'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 测试直接调用 DevLogger
                DevLogger.instance.info('Direct DevLogger info');
                DevLogger.instance.warning('Direct DevLogger warning');
                DevLogger.instance.error('Direct DevLogger error');
              },
              child: Text('Test DevLogger'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 打开 Dev Panel
                DevPanel.open(context);
              },
              child: Text('Open Dev Panel'),
            ),
          ],
        ),
      ),
    );
  }
}