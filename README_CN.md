# Flutter Dev Panel

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel.svg)](https://pub.dev/packages/flutter_dev_panel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个模块化、零侵入的 Flutter 应用调试面板，为开发阶段提供实时监控和调试功能。

[English Documentation](README.md)

## 功能特性

### 核心能力
- **零侵入**: 不影响生产代码
- **模块化架构**: 按需加载所需模块
- **高性能**: 优化以最小化对应用性能的影响
- **多种触发方式**: 悬浮按钮、摇一摇手势或程序化调用

### 内置功能

#### 环境管理
- 环境切换（开发/生产/自定义）
- 环境变量管理
- 配置持久化
- 实时环境更新
- 支持 .env 文件
- 基于优先级的配置加载（--dart-define > .env文件 > 代码配置）

#### 主题管理
- 亮色/暗色/系统主题模式
- 与应用主题双向同步
- 主题持久化

## 可选模块

### 控制台模块（`flutter_dev_panel_console`）
- 实时日志捕获（print、debugPrint、Logger 包）
- 日志级别过滤（verbose、debug、info、warning、error）
- 搜索和过滤功能
- 可配置的日志保留和自动滚动
- Logger 包多行输出智能合并

### 网络模块（`flutter_dev_panel_network`）
- HTTP 请求/响应监控
- GraphQL 查询和变更跟踪
- 支持 Dio、http 和 GraphQL 包
- 请求历史持久化
- 详细的请求/响应检查
- 带语法高亮的 JSON 查看器

### 设备模块（`flutter_dev_panel_device`）
- 设备型号和规格
- 屏幕尺寸和 PPI 计算
- 操作系统信息
- 平台特定详情
- 应用包信息

### 性能模块（`flutter_dev_panel_performance`）
- 实时 FPS 监控
- 内存使用跟踪
- 丢帧检测
- 性能图表和趋势
- 内存峰值跟踪

## 安装

### 方案 1：仅安装核心包（最小化）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
```

### 方案 2：安装特定模块（推荐）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0    # 日志功能
  flutter_dev_panel_network: ^1.0.0    # 网络监控
  # 只添加您需要的模块
```

### 方案 3：安装所有模块

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

## 快速开始

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// 导入需要的模块
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境配置
  // --dart-define 会自动覆盖匹配的键
  await EnvironmentManager.instance.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'api_url': 'https://dev.api.example.com',
          'api_key': '',  // 将被 --dart-define=api_key=xxx 覆盖
          'debug': true,
          'timeout': 30000,
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'api_key': '',  // 将被 --dart-define=api_key=xxx 覆盖
          'debug': false,
          'timeout': 10000,
        },
      ),
    ],
  );

  // 使用选定的模块初始化开发面板
  FlutterDevPanel.initialize(
    modules: [
      ConsoleModule(),
      NetworkModule(),
      // 根据需要添加更多模块
    ],
  );

  runApp(
    DevPanelWrapper(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 监听开发面板的主题变化
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,  // 应用开发面板的主题
          home: MyHomePage(),
        );
      },
    );
  }
}
```

## 使用

### 访问面板
- **悬浮按钮**: 点击 FAB（默认）
- **摇一摇手势**: 摇动设备
- **程序化调用**: `FlutterDevPanel.open(context)`

### 获取环境变量
```dart
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');
final isDebug = EnvironmentManager.instance.getVariable<bool>('debug');
```

### 网络监控设置

对于 **Dio**:
```dart
final dio = Dio();
dio.interceptors.add(NetworkInterceptor.dio());
```

对于 **HTTP**:
```dart
final client = NetworkInterceptor.http(http.Client());
```

对于 **GraphQL**:
```dart
final graphQLClient = GraphQLClient(
  link: NetworkInterceptor.graphQL(httpLink),
  cache: GraphQLCache(),
);
```

## 配置

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    enabled: true,  // 启用/禁用面板
    showInProduction: false,  // 在生产构建中隐藏
    triggerModes: {
      TriggerMode.fab,
      TriggerMode.shake,
    },
  ),
  modules: [...],
);
```

## 主题集成

如果应用已有主题管理，可以与开发面板同步， 以下为参考代码：

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  
  @override
  void initState() {
    super.initState();
    // 加载应用保存的主题偏好
    _themeMode = MyThemePreferences.getThemeMode();
    
    // 将开发面板与应用主题同步
    ThemeManager.instance.setThemeMode(_themeMode);
    
    // 监听开发面板主题变化
    ThemeManager.instance.themeMode.addListener(_onThemeChanged);
  }
  
  void _onThemeChanged() {
    setState(() {
      _themeMode = ThemeManager.instance.themeMode.value;
      // 保存到应用偏好设置
      MyThemePreferences.saveThemeMode(_themeMode);
    });
  }
  
  @override
  void dispose() {
    ThemeManager.instance.themeMode.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MyHomePage(),
    );
  }
}
```

## 模块配置

### 控制台模块
```dart
DevLogger.instance.updateConfig(
  const LogCaptureConfig(
    maxLogs: 500,
    autoScroll: true,
    combineLoggerOutput: true,  // 合并 Logger 包的多行输出
  ),
);

// 使用预定义配置
DevLogger.instance.updateConfig(
  const LogCaptureConfig.development(), // maxLogs: 1000, autoScroll: true
);
```

### 性能模块
性能模块自动监控：
- 帧率（FPS）
- 内存使用
- 丢帧
- 渲染时间

无需额外配置。


## 环境管理

### 配置优先级
环境变量按以下优先级加载（从高到低）：
1. **--dart-define** - 命令行参数（自动检测）
2. **.env 文件** - 环境特定文件（如果存在）
3. **代码配置** - `initialize()` 中的默认值
4. **保存的配置** - 之前运行时的值

**工作原理：**
- 系统自动从您的配置中发现所有键
- 通过 --dart-define 传递的匹配键将覆盖其他来源
- 键匹配不区分大小写，支持格式变体（snake_case、dash-case）

### 推荐设置

1. **创建环境文件：**
```bash
# .env.example (提交到 git - 模板文件)
API_URL=https://api.example.com
API_KEY=your-key-here
ENABLE_ANALYTICS=false

# .env.development (提交到 git - 安全的默认值)
API_URL=https://dev.api.example.com
ENABLE_ANALYTICS=false

# .env.production (提交到 git - 非敏感配置)
API_URL=https://api.example.com
ENABLE_ANALYTICS=true
# 敏感数据通过 CI/CD 中的 --dart-define 注入
```

2. **添加到 pubspec.yaml（用于生产构建）：**
```yaml
flutter:
  assets:
    - .env.production  # 发布版本所需
```

3. **添加到 .gitignore（仅本地覆盖文件）：**
```gitignore
.env
.env.local
.env.*.local
!.env.example
!.env.development
!.env.production
```

4. **构建命令：**
```bash
# 开发环境（使用 .env.development）
flutter run

# 生产环境，从 CI/CD 注入密钥
flutter build apk \
  --dart-define=API_KEY=$SECRET_API_KEY \
  --dart-define=DB_PASSWORD=$SECRET_DB_PASSWORD

# CI/CD 示例
flutter build ios \
  --dart-define=API_KEY=${{ secrets.API_KEY }} \
  --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
```

### 配置策略

**提交到 Git：**
- `.env.development` - 开发环境 URL 和非敏感配置
- `.env.production` - 生产环境 URL 和非敏感配置
- `.env.example` - 包含所有变量说明的模板

**通过 CI/CD 注入（--dart-define）：**
- API 密钥、令牌、密码
- 第三方服务凭证
- 任何敏感配置
- 环境特定的覆盖值

**优势：**
- 非敏感配置受版本控制
- 敏感数据永不接触代码库
- CI/CD 可覆盖配置中定义的任何值
- 开发者无需手动配置即可运行应用
- 无需维护硬编码的键列表

### --dart-define 工作方式

1. **在环境配置中定义键和默认值：**
```dart
const EnvironmentConfig(
  name: 'Production',
  variables: {
    'api_url': 'https://api.example.com',
    'api_key': '',  // 空默认值，将被注入
    'sentry_dsn': '',  // 空默认值，将被注入
  },
)
```

2. **在 CI/CD 中通过 --dart-define 覆盖：**
```bash
flutter build apk \
  --dart-define=api_key=${{ secrets.API_KEY }} \
  --dart-define=sentry_dsn=${{ secrets.SENTRY_DSN }}
```

系统会自动检测并应用这些覆盖值。


## 高级用法

### 创建自定义模块

通过扩展 `DevModule` 创建自定义模块：

```dart
class CustomModule extends DevModule {
  @override
  String get name => '自定义';
  
  @override
  IconData get icon => Icons.extension;
  
  @override
  Widget buildPage(BuildContext context) {
    return YourCustomPage();
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // 可选：返回要在 FAB 中显示的 widget
    return Text('自定义信息');
  }
}
```

### 生产环境安全

开发面板会在生产构建中自动禁用，除非明确配置：

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    enabled: !kReleaseMode, // 在发布版本中自动禁用
    showInProduction: false, // 额外的安全检查
  ),
  // ...
);
```

## 架构

Flutter Dev Panel 遵循模块化架构：

```
flutter_dev_panel/              # 核心框架（必需）
├── lib/
│   └── src/
│       ├── core/               # 核心功能
│       ├── models/             # 数据模型
│       └── ui/                 # UI 组件
├── packages/                   # 可选模块
│   ├── flutter_dev_panel_console/     # 控制台/日志模块
│   ├── flutter_dev_panel_network/     # 网络监控模块
│   ├── flutter_dev_panel_device/      # 设备信息模块
│   └── flutter_dev_panel_performance/ # 性能监控模块
└── example/                    # 示例应用
```

每个模块包都依赖于核心 `flutter_dev_panel` 包，可以根据需求独立安装。

### 开发设置

1. 克隆仓库
2. 在根目录运行 `flutter pub get`
3. 运行示例应用：`cd example && flutter run`

### 运行测试

```bash
flutter test
```

## 测试

```bash
# 运行所有测试
flutter test

# 测试单个模块
flutter test packages/flutter_dev_panel_console/test
flutter test packages/flutter_dev_panel_network/test
flutter test packages/flutter_dev_panel_device/test
flutter test packages/flutter_dev_panel_performance/test

# 运行示例应用
cd example
flutter run
```

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE) 文件