import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

// 方式 1：最简单（自动从 .env 文件加载）
void main() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),
    ],
  );
}

// 方式 2：提供备用环境配置（当 .env 文件不存在时使用）
void mainWithFallback() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
    ),
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'HTTP_BASE_URL': 'https://dev-api.example.com',
          'API_KEY': 'dev_key',
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'HTTP_BASE_URL': 'https://api.example.com',
          'API_KEY': 'prod_key',
        },
      ),
    ],
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),
    ],
  );
}

// 方式 3：如果需要在 init 之前做其他初始化
void mainWithCustomInit() async {
  await DevPanel.init(
    () async {
      // 不需要手动调用 WidgetsFlutterBinding.ensureInitialized()
      // DevPanel.init 会自动调用
      
      // 你的其他初始化代码
      // await initHiveForFlutter();
      // await Get.putAsync(() => StorageService().init());
      
      // 监听环境切换
      DevPanel.environment.addListener(() {
        final httpUrl = DevPanel.environment.getString('HTTP_BASE_URL');
        debugPrint('环境已切换 - HTTP URL: $httpUrl');
      });
      
      runApp(const MyApp());
    },
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      home: const HomePage(),
      builder: (context, child) {
        return DevPanelWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                final env = DevPanel.environment.currentEnvironment;
                final url = DevPanel.environment.getString('HTTP_BASE_URL');
                debugPrint('当前环境: ${env?.name}');
                debugPrint('API URL: $url');
              },
              child: const Text('获取当前环境'),
            ),
          ],
        ),
      ),
    );
  }
}