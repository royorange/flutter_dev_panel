import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

// ... 你的其他导入

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  // logger.init();

  // 初始化Hive缓存（GraphQL需要）
  await initHiveForFlutter();

  // 初始化存储服务
  // await Get.putAsync(() => StorageService().init());

  // ========== 添加这部分：初始化环境配置 ==========
  await EnvironmentManager.instance.initialize(
    // 方式 1: 纯代码配置（推荐先用这个测试）
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'HTTP_BASE_URL': 'https://dev-api.wisburg.com',
          'GRAPHQL_ENDPOINT': 'https://dev-graphql.wisburg.com/graphql',
          'SOCKET_URL': 'wss://dev-socket.wisburg.com',
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
          'HTTP_BASE_URL': 'https://staging-api.wisburg.com',
          'GRAPHQL_ENDPOINT': 'https://staging-graphql.wisburg.com/graphql',
          'SOCKET_URL': 'wss://staging-socket.wisburg.com',
          'API_KEY': 'staging_key_789012',
          'DEBUG': true,
          'LOG_LEVEL': 'info',
          'TIMEOUT': 20000,
        },
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'HTTP_BASE_URL': 'https://api.wisburg.com',
          'GRAPHQL_ENDPOINT': 'https://graphql.wisburg.com/graphql',
          'SOCKET_URL': 'wss://socket.wisburg.com',
          'API_KEY': 'prod_key_345678',
          'DEBUG': false,
          'LOG_LEVEL': 'error',
          'TIMEOUT': 15000,
        },
      ),
    ],
    defaultEnvironment: 'Development',
    
    // 方式 2: 如果你想从 .env 文件加载，取消下面的注释
    // loadFromEnvFiles: true,
  );
  // ========== 初始化环境配置结束 ==========

  // 监听环境切换
  DevPanel.environment.addListener(() {
    // 使用新的 getString 方法（不需要泛型）
    final httpUrl = DevPanel.environment.getString('HTTP_BASE_URL');
    if (httpUrl != null && httpUrl.isNotEmpty) {
      // 更新 HTTP 客户端
      if (Get.isRegistered<HttpClient>()) {
        Get.find<HttpClient>().updateBaseUrl(httpUrl);
      }
      debugPrint('切换环境 - HTTP URL: $httpUrl');
    }
    
    // 获取其他环境变量
    final graphqlUrl = DevPanel.environment.getString('GRAPHQL_ENDPOINT');
    final apiKey = DevPanel.environment.getString('API_KEY');
    final isDebug = DevPanel.environment.getBool('DEBUG');
    
    debugPrint('GraphQL URL: $graphqlUrl');
    debugPrint('API Key: $apiKey');
    debugPrint('Debug Mode: $isDebug');
  });

  // 使用 FlutterDevPanel.init，类似 Sentry 的模式
  await FlutterDevPanel.init(
    () => runApp(const MyApp()),
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
    ),
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),
    ],
  );
}

// ... 你的 MyApp 类保持不变