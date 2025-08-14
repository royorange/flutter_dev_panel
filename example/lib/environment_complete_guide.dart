/// 环境配置完整指南
/// 
/// Flutter Dev Panel 环境管理支持三种配置方式，按优先级从高到低：
/// 1. --dart-define（编译时）
/// 2. .env 文件
/// 3. 代码配置

import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

// ============================================================
// 方案 A：最简单 - 自动加载 .env 文件（推荐）
// ============================================================
void mainSimplest() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    // 默认 autoLoadEnvFiles = true，会自动加载 .env 文件
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}

// ============================================================
// 方案 B：混合模式 - .env 文件 + 代码备用配置
// ============================================================
void mainHybrid() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    autoLoadEnvFiles: true,  // 自动加载 .env 文件
    environments: [
      // 这些是备用配置，当 .env 文件不存在时使用
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
    ],
  );
}

// ============================================================
// 方案 C：纯代码配置（不依赖 .env 文件）
// ============================================================
void mainCodeOnly() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    autoLoadEnvFiles: false,  // 禁用 .env 文件加载
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'HTTP_BASE_URL': 'https://dev-api.example.com',
          'GRAPHQL_ENDPOINT': 'https://dev-graphql.example.com/graphql',
          'API_KEY': 'dev_key_123456',
          'DEBUG': true,
          'LOG_LEVEL': 'verbose',
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Staging',
        variables: {
          'HTTP_BASE_URL': 'https://staging-api.example.com',
          'GRAPHQL_ENDPOINT': 'https://staging-graphql.example.com/graphql',
          'API_KEY': 'staging_key_789012',
          'DEBUG': true,
          'LOG_LEVEL': 'info',
        },
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'HTTP_BASE_URL': 'https://api.example.com',
          'GRAPHQL_ENDPOINT': 'https://graphql.example.com/graphql',
          'API_KEY': 'prod_key_345678',
          'DEBUG': false,
          'LOG_LEVEL': 'error',
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
// 方案 D：手动初始化（更多控制）
// ============================================================
void mainManual() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 手动初始化环境管理器
  await EnvironmentManager.instance.initialize(
    loadFromEnvFiles: true,  // 尝试加载 .env 文件
    environments: [
      // 代码配置作为备用
      const EnvironmentConfig(
        name: 'Development',
        variables: {'HTTP_BASE_URL': 'https://dev-api.example.com'},
        isDefault: true,
      ),
    ],
  );
  
  // 监听环境切换
  DevPanel.environment.addListener(() {
    final newUrl = DevPanel.environment.getString('HTTP_BASE_URL');
    debugPrint('环境已切换，新的 URL: $newUrl');
    // 更新你的 HTTP 客户端...
  });
  
  // 初始化 DevPanel（不会重复初始化环境）
  await DevPanel.init(
    () => runApp(const MyApp()),
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}

// ============================================================
// 使用 --dart-define 覆盖
// ============================================================
// 运行命令：
// flutter run --dart-define=HTTP_BASE_URL=https://custom.example.com \
//             --dart-define=API_KEY=custom_key \
//             --dart-define=DEBUG=true
//
// dart-define 的值会覆盖所有环境中的同名变量

// ============================================================
// 示例应用
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Environment Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      builder: (context, child) {
        // 包装 DevPanelWrapper
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
      appBar: AppBar(
        title: const Text('Environment Configuration'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 显示当前环境
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListenableBuilder(
                  listenable: DevPanel.environment,
                  builder: (context, _) {
                    final current = DevPanel.environment.currentEnvironment;
                    final environments = DevPanel.environment.environments;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前环境: ${current?.name ?? "未配置"}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('可用环境数量: ${environments.length}'),
                        if (current != null) ...[
                          const SizedBox(height: 16),
                          const Text('环境变量:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('API URL: ${DevPanel.environment.getString("HTTP_BASE_URL") ?? "未设置"}'),
                          Text('API Key: ${DevPanel.environment.getString("API_KEY") ?? "未设置"}'),
                          Text('Debug: ${DevPanel.environment.getBool("DEBUG") ?? false}'),
                          Text('Timeout: ${DevPanel.environment.getInt("TIMEOUT") ?? 30000}ms'),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            
            // 测试按钮
            ElevatedButton(
              onPressed: () {
                // 获取环境变量的不同方式
                final url1 = DevPanel.environment.getString('HTTP_BASE_URL');
                final url2 = DevPanel.environment.getVariable<String>('HTTP_BASE_URL');
                
                final debug1 = DevPanel.environment.getBool('DEBUG');
                final debug2 = DevPanel.environment.getVariable<bool>('DEBUG');
                
                final timeout = DevPanel.environment.getInt('TIMEOUT', defaultValue: 30000);
                
                debugPrint('URL (getString): $url1');
                debugPrint('URL (getVariable): $url2');
                debugPrint('Debug (getBool): $debug1');
                debugPrint('Debug (getVariable): $debug2');
                debugPrint('Timeout: ${timeout}ms');
              },
              child: const Text('测试获取环境变量'),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '点击右下角 FAB 打开 DevPanel\n'
              '可以在面板中切换环境',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
创建以下文件在你的项目根目录：

.env:
```
HTTP_BASE_URL=https://api.example.com
API_KEY=default_key
DEBUG=true
TIMEOUT=30000
```

.env.dev:
```
HTTP_BASE_URL=https://dev-api.example.com
API_KEY=dev_key_123456
DEBUG=true
TIMEOUT=60000
LOG_LEVEL=verbose
```

.env.prod:
```
HTTP_BASE_URL=https://api.example.com
API_KEY=prod_key_345678
DEBUG=false
TIMEOUT=15000
LOG_LEVEL=error
```

然后在 pubspec.yaml 中添加：
```yaml
flutter:
  assets:
    - .env
    - .env.dev
    - .env.prod
```
*/