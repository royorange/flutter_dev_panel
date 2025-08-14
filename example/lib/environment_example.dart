import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// 环境配置示例
class EnvironmentExample {
  
  /// 方式 1: 代码中直接配置环境
  static Future<void> initializeWithCode() async {
    await EnvironmentManager.instance.initialize(
      environments: [
        const EnvironmentConfig(
          name: 'Development',
          variables: {
            'HTTP_BASE_URL': 'https://dev-api.example.com',
            'GRAPHQL_ENDPOINT': 'https://dev-graphql.example.com/graphql',
            'SOCKET_URL': 'wss://dev-socket.example.com',
            'API_KEY': 'dev_key_123456',
            'DEBUG': true,
            'LOG_LEVEL': 'verbose',
            'TIMEOUT': 30000,
          },
          isDefault: true,
        ),
        const EnvironmentConfig(
          name: 'Staging',
          variables: {
            'HTTP_BASE_URL': 'https://staging-api.example.com',
            'GRAPHQL_ENDPOINT': 'https://staging-graphql.example.com/graphql',
            'SOCKET_URL': 'wss://staging-socket.example.com',
            'API_KEY': 'staging_key_789012',
            'DEBUG': true,
            'LOG_LEVEL': 'info',
            'TIMEOUT': 20000,
          },
        ),
        const EnvironmentConfig(
          name: 'Production',
          variables: {
            'HTTP_BASE_URL': 'https://api.example.com',
            'GRAPHQL_ENDPOINT': 'https://graphql.example.com/graphql',
            'SOCKET_URL': 'wss://socket.example.com',
            'API_KEY': 'prod_key_345678',
            'DEBUG': false,
            'LOG_LEVEL': 'error',
            'TIMEOUT': 15000,
          },
        ),
      ],
      defaultEnvironment: 'Development',
    );
  }
  
  /// 方式 2: 从 .env 文件加载 + 代码配置（混合模式）
  static Future<void> initializeWithEnvFiles() async {
    await EnvironmentManager.instance.initialize(
      loadFromEnvFiles: true,  // 自动加载 .env, .env.dev, .env.prod 等文件
      environments: [
        // 这些是备用配置，如果 .env 文件不存在时使用
        const EnvironmentConfig(
          name: 'Fallback',
          variables: {
            'HTTP_BASE_URL': 'https://fallback-api.example.com',
            'DEBUG': false,
          },
        ),
      ],
    );
  }
  
  /// 方式 3: 使用 --dart-define 覆盖
  /// 
  /// 运行时使用：
  /// flutter run --dart-define=HTTP_BASE_URL=https://custom.example.com \
  ///             --dart-define=API_KEY=custom_key \
  ///             --dart-define=DEBUG=true
  /// 
  /// 注意：dart-define 的值会覆盖所有环境中的同名变量
  static void showDartDefineExample() {
    // dart-define 的值会自动合并到环境变量中
    // 优先级：dart-define > .env 文件 > 代码配置
    
    // 可以通过 getString 等方法获取
    final apiUrl = DevPanel.environment.getString('HTTP_BASE_URL');
    final apiKey = DevPanel.environment.getString('API_KEY');
    final isDebug = DevPanel.environment.getBool('DEBUG');
    
    debugPrint('API URL: $apiUrl');
    debugPrint('API Key: $apiKey');
    debugPrint('Debug: $isDebug');
  }
}

/// 在你的 main.dart 中使用
void exampleMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 选择一种初始化方式：
  
  // 方式 1: 纯代码配置
  await EnvironmentExample.initializeWithCode();
  
  // 或者 方式 2: 从 .env 文件加载
  // await EnvironmentExample.initializeWithEnvFiles();
  
  // 然后初始化 DevPanel
  await FlutterDevPanel.init(
    () => runApp(const MyApp()),
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
    ),
    modules: [
      // ... 你的模块
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Environment Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 环境切换器会自动显示在 DevPanel 中
              ElevatedButton(
                onPressed: () {
                  // 获取当前环境变量
                  final baseUrl = DevPanel.environment.getString('HTTP_BASE_URL');
                  final debug = DevPanel.environment.getBool('DEBUG');
                  
                  debugPrint('Current Base URL: $baseUrl');
                  debugPrint('Debug Mode: $debug');
                },
                child: const Text('Get Current Environment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}