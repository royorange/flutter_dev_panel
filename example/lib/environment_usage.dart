import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

// ============================================================
// 环境配置使用指南
// ============================================================

/// 方式 1：最简单 - 自动加载 .env 文件（推荐）
/// 
/// 前提：
/// 1. 在项目根目录创建 .env, .env.dev, .env.prod 等文件
/// 2. 在 pubspec.yaml 的 assets 中声明这些文件
void main() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    // 默认 config.loadFromEnvFiles = true，自动加载 .env 文件
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}

/// 方式 2：纯代码配置（不需要 .env 文件）
void mainWithCode() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    config: const DevPanelConfig(
      loadFromEnvFiles: false,  // 禁用 .env 文件加载
    ),
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'HTTP_BASE_URL': 'https://dev-api.example.com',
          'API_KEY': 'dev_key',
          'DEBUG': true,
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'HTTP_BASE_URL': 'https://api.example.com',
          'API_KEY': 'prod_key',
          'DEBUG': false,
        },
      ),
    ],
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}

/// 方式 3：混合模式 - .env 文件 + 代码备用
void mainHybrid() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    // 默认会尝试加载 .env 文件
    environments: [
      // 当 .env 文件不存在时，使用这些配置
      const EnvironmentConfig(
        name: 'Fallback',
        variables: {
          'HTTP_BASE_URL': 'https://fallback-api.example.com',
        },
      ),
    ],
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}

// ============================================================
// 你的应用代码
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
      builder: (context, child) {
        return DevPanelWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    
    // 监听环境切换
    DevPanel.environment.addListener(_onEnvironmentChanged);
  }
  
  @override
  void dispose() {
    DevPanel.environment.removeListener(_onEnvironmentChanged);
    super.dispose();
  }
  
  void _onEnvironmentChanged() {
    // 环境切换时更新你的配置
    final newUrl = DevPanel.environment.getString('HTTP_BASE_URL');
    debugPrint('环境已切换，新的 API URL: $newUrl');
    
    // 更新你的 HTTP 客户端
    // if (Get.isRegistered<HttpClient>()) {
    //   Get.find<HttpClient>().updateBaseUrl(newUrl);
    // }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('环境配置示例')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 使用环境变量
            ElevatedButton(
              onPressed: () {
                // 获取环境变量
                final apiUrl = DevPanel.environment.getString('HTTP_BASE_URL');
                final apiKey = DevPanel.environment.getString('API_KEY');
                final isDebug = DevPanel.environment.getBool('DEBUG') ?? false;
                final timeout = DevPanel.environment.getInt('TIMEOUT') ?? 30000;
                
                debugPrint('API URL: $apiUrl');
                debugPrint('API Key: $apiKey');
                debugPrint('Debug: $isDebug');
                debugPrint('Timeout: ${timeout}ms');
              },
              child: const Text('获取环境变量'),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              '点击右下角 FAB 打开 DevPanel\n'
              '可以在面板顶部切换环境',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// .env 文件示例
// ============================================================
/*
1. 在项目根目录创建 .env 文件：

.env:
```
HTTP_BASE_URL=https://api.example.com
API_KEY=default_key
DEBUG=true
```

.env.dev:
```
HTTP_BASE_URL=https://dev-api.example.com
API_KEY=dev_key_123456
DEBUG=true
```

.env.prod:
```
HTTP_BASE_URL=https://api.example.com
API_KEY=prod_key_345678
DEBUG=false
```

2. 在 pubspec.yaml 中添加：
```yaml
flutter:
  assets:
    - .env
    - .env.dev
    - .env.prod
```

3. 运行时使用 --dart-define 覆盖（可选）：
```bash
flutter run --dart-define=HTTP_BASE_URL=https://custom.example.com
```
*/