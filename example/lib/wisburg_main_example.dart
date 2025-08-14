import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';
// import 'package:get/get.dart';
// import 'package:graphql_flutter/graphql_flutter.dart';

// import 'app/bindings/initial_binding.dart';
// import 'app/routes/app_pages.dart';
// import 'app/themes/app_theme.dart';
// import 'core/network/http_client.dart';
// import 'core/services/logger_service.dart';
// import 'core/services/storage_service.dart';
// import 'shared/widgets/navigation/adaptive_navigation_scaffold.dart';

void main() async {
  // 使用 DevPanel.init
  await DevPanel.init(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 初始化日志服务
      // logger.init();

      // 初始化Hive缓存（GraphQL需要）
      // await initHiveForFlutter();

      // 初始化存储服务
      // await Get.putAsync(() => StorageService().init());
      
      // ========== 重要：在 ensureInitialized() 之后初始化环境 ==========
      await EnvironmentManager.instance.initialize(
        loadFromEnvFiles: false,  // 先不使用 .env 文件
        environments: [
          const EnvironmentConfig(
            name: 'Development',
            variables: {
              'HTTP_BASE_URL': 'https://dev-api.wisburg.com',
              'GRAPHQL_ENDPOINT': 'https://dev-graphql.wisburg.com/graphql',
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
              'API_KEY': 'prod_key_345678',
              'DEBUG': false,
              'LOG_LEVEL': 'error',
              'TIMEOUT': 15000,
            },
          ),
        ],
      );

      // 监听环境切换
      DevPanel.environment.addListener(() {
        final httpUrl = DevPanel.environment.getString('HTTP_BASE_URL');
        if (httpUrl != null && httpUrl.isNotEmpty) {
          // 更新 HTTP 客户端
          // if (Get.isRegistered<HttpClient>()) {
          //   Get.find<HttpClient>().updateBaseUrl(httpUrl);
          // }
          debugPrint('环境已切换 - HTTP URL: $httpUrl');
        }
      });

      runApp(const MyApp());
    },
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wisburg App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: Text('Wisburg App'),
        ),
      ),
      builder: (context, child) {
        // 包装 DevPanelWrapper
        return DevPanelWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}