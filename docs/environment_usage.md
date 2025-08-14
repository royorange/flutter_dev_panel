# 环境变量使用指南

Flutter Dev Panel 提供了强大的环境管理功能，支持多种方式获取和监听环境变量。

## 便捷方法（推荐）

无需指定泛型，代码更简洁：

```dart
// 获取字符串
final apiUrl = DevPanel.environment.getString('api_url');
final apiUrl = DevPanel.environment.getString('api_url', defaultValue: 'https://api.example.com');

// 获取布尔值
final isDebug = DevPanel.environment.getBool('debug');
final isDebug = DevPanel.environment.getBool('debug', defaultValue: false);

// 获取整数（支持从字符串解析）
final timeout = DevPanel.environment.getInt('timeout');
final timeout = DevPanel.environment.getInt('timeout', defaultValue: 30000);

// 获取浮点数（支持从整数转换）
final version = DevPanel.environment.getDouble('version');
final version = DevPanel.environment.getDouble('version', defaultValue: 1.0);

// 获取列表
final servers = DevPanel.environment.getList<String>('servers');
final servers = DevPanel.environment.getList<String>('servers', defaultValue: ['server1']);

// 获取 Map
final config = DevPanel.environment.getMap('database');
final config = DevPanel.environment.getMap('database', defaultValue: {'host': 'localhost'});
```

## 泛型方法（灵活）

当需要获取特殊类型时使用：

```dart
// 泛型方法
final apiUrl = DevPanel.environment.getVariable<String>('api_url');
final timeout = DevPanel.environment.getVariable<int>('timeout', defaultValue: 10000);
final customObject = DevPanel.environment.getVariable<MyConfig>('config');
```

## 监听环境变更

### 方法1：使用 addListener

```dart
class _MyScreenState extends State<MyScreen> {
  String _apiUrl = '';
  
  @override
  void initState() {
    super.initState();
    _updateConfig();
    DevPanel.environment.addListener(_updateConfig);
  }
  
  void _updateConfig() {
    setState(() {
      _apiUrl = DevPanel.environment.getString('api_url') ?? '';
    });
  }
  
  @override
  void dispose() {
    DevPanel.environment.removeListener(_updateConfig);
    super.dispose();
  }
}
```

### 方法2：使用 ListenableBuilder

```dart
@override
Widget build(BuildContext context) {
  return ListenableBuilder(
    listenable: DevPanel.environment,
    builder: (context, _) {
      final apiUrl = DevPanel.environment.getString('api_url');
      final isDebug = DevPanel.environment.getBool('debug') ?? false;
      
      return Column(
        children: [
          Text('API: $apiUrl'),
          if (isDebug) Text('Debug Mode'),
        ],
      );
    },
  );
}
```

## 实际使用示例

### 配置服务

```dart
class AppConfig {
  // 使用便捷方法，代码更简洁
  static String get apiUrl => 
    DevPanel.environment.getString('api_url') ?? 'https://api.example.com';
  
  static String get apiKey => 
    DevPanel.environment.getString('api_key') ?? '';
  
  static bool get isDebugMode => 
    DevPanel.environment.getBool('debug') ?? false;
  
  static int get requestTimeout => 
    DevPanel.environment.getInt('timeout') ?? 10000;
  
  static List<String> get servers => 
    DevPanel.environment.getList<String>('servers') ?? [];
  
  static Map<String, dynamic> get databaseConfig => 
    DevPanel.environment.getMap('database') ?? {
      'host': 'localhost',
      'port': 5432,
      'name': 'default_db',
    };
}
```

### Dio 配置示例

```dart
class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio();
    _updateDioConfig();
    
    // 监听环境变更，自动更新配置
    DevPanel.environment.addListener(_updateDioConfig);
  }
  
  void _updateDioConfig() {
    final apiUrl = DevPanel.environment.getString('api_url');
    final timeout = DevPanel.environment.getInt('timeout') ?? 10000;
    final apiKey = DevPanel.environment.getString('api_key');
    
    _dio.options = BaseOptions(
      baseUrl: apiUrl ?? 'https://api.example.com',
      connectTimeout: Duration(milliseconds: timeout),
      headers: {
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      },
    );
  }
}
```

### 完整应用示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境配置
  await DevPanel.environment.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'api_url': 'https://dev-api.example.com',
          'api_key': 'dev-key-123',
          'debug': true,
          'timeout': 30000,
          'theme_mode': 'dark',
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'api_key': '', // 通过 --dart-define 注入
          'debug': false,
          'timeout': 10000,
          'theme_mode': 'light',
        },
      ),
    ],
  );
  
  DevPanel.initialize(modules: []);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DevPanel.environment,
      builder: (context, _) {
        // 根据环境变量动态调整应用行为
        final isDarkMode = DevPanel.environment.getString('theme_mode') == 'dark';
        final appTitle = DevPanel.environment.currentEnvironment?.name ?? 'App';
        
        return MaterialApp(
          title: appTitle,
          theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: DevPanelWrapper(child: HomePage()),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Environment Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => DevPanel.open(context),
          ),
        ],
      ),
      body: Center(
        child: ListenableBuilder(
          listenable: DevPanel.environment,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('环境: ${DevPanel.environment.currentEnvironment?.name}'),
                Text('API: ${DevPanel.environment.getString('api_url')}'),
                Text('Debug: ${DevPanel.environment.getBool('debug')}'),
                Text('Timeout: ${DevPanel.environment.getInt('timeout')}ms'),
                
                SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    // 切换环境
                    final current = DevPanel.environment.currentEnvironment?.name;
                    final newEnv = current == 'Development' ? 'Production' : 'Development';
                    DevPanel.environment.switchEnvironment(newEnv);
                  },
                  child: Text('切换环境'),
                ),
                
                if (DevPanel.environment.getBool('debug') ?? false)
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    padding: EdgeInsets.all(10),
                    color: Colors.yellow.withOpacity(0.3),
                    child: Text('调试模式已启用'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

## 类型转换

便捷方法支持智能类型转换：

### getInt 转换规则
- `int` → 直接返回
- `String` → 尝试解析（"123" → 123）
- `double` → 转为整数（10.5 → 10）

### getDouble 转换规则
- `double` → 直接返回
- `int` → 转为浮点数（10 → 10.0）
- `String` → 尝试解析（"10.5" → 10.5）

### getBool 转换规则
- `bool` → 直接返回
- 其他类型 → 返回默认值

## API 参考

### 便捷方法
```dart
String? getString(String key, {String? defaultValue})
bool? getBool(String key, {bool? defaultValue})
int? getInt(String key, {int? defaultValue})
double? getDouble(String key, {double? defaultValue})
List<T>? getList<T>(String key, {List<T>? defaultValue})
Map<String, dynamic>? getMap(String key, {Map<String, dynamic>? defaultValue})
```

### 泛型方法
```dart
T? getVariable<T>(String key, {T? defaultValue})
```

### 环境管理
```dart
// 获取当前环境
EnvironmentConfig? get currentEnvironment

// 切换环境
void switchEnvironment(String name)

// 更新变量
void updateVariable(String key, dynamic value)

// 监听变更
void addListener(VoidCallback listener)
void removeListener(VoidCallback listener)
```

## 最佳实践

1. **使用便捷方法**：优先使用 `getString`、`getBool` 等便捷方法，代码更简洁
2. **提供默认值**：始终提供合理的默认值，避免空值异常
3. **监听变更**：使用 `ListenableBuilder` 自动响应环境变更
4. **生命周期管理**：记得在 `dispose()` 中移除监听器
5. **类型安全**：使用具体的类型方法而不是 `dynamic`