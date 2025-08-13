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

### 核心功能（内置）

#### 环境管理
- 环境切换（开发/生产/自定义）
- 环境变量管理
- 配置持久化
- 实时环境更新
- 支持 .env 文件
- 基于优先级的配置加载

### 可选模块

#### 控制台模块（`flutter_dev_panel_console`）
- 实时日志捕获（print、debugPrint、Logger 包）
- 日志级别过滤（verbose、debug、info、warning、error）
- 搜索和过滤功能
- 可配置的日志保留和自动滚动
- Logger 包多行输出智能合并

#### 网络模块（`flutter_dev_panel_network`）
- HTTP 请求/响应监控
- GraphQL 查询和变更跟踪
- 支持 Dio、http 和 GraphQL 包
- 请求历史持久化
- 详细的请求/响应检查
- 带语法高亮的 JSON 查看器

#### 设备模块（`flutter_dev_panel_device`）
- 设备型号和规格
- 屏幕尺寸和 PPI 计算
- 操作系统信息
- 平台特定详情
- 应用包信息

#### 性能模块（`flutter_dev_panel_performance`）
- 实时 FPS 监控
- 内存使用跟踪
- 丢帧检测
- 性能图表和趋势
- 内存峰值跟踪

## 安装

### 方案1：仅安装核心包（最小化）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
```

### 方案2：安装特定模块（推荐）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0    # 日志功能
  flutter_dev_panel_network: ^1.0.0    # 网络监控
  # 只添加您需要的模块
```

### 方案3：安装所有模块

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

### 仅在开发环境使用

如果只想在开发时使用：

```yaml
dev_dependencies:
  flutter_dev_panel: ^1.0.0
  # 添加您需要的模块
```

## 快速开始

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// 导入您需要的模块
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // 初始化环境配置
  EnvironmentManager.instance.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'api_url': 'https://dev.api.example.com',
          'debug': true,
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'debug': false,
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

如果您的应用已有主题管理，可以与开发面板同步：

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

这种方法：
- 启动时加载现有主题偏好
- 将开发面板与应用当前主题同步
- 通过开发面板更改时更新应用偏好设置
- 保持应用和开发面板主题的一致性

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

### 使用 .env 文件（推荐）

Flutter Dev Panel 支持从 `.env` 文件加载环境配置：

1. 在项目根目录创建 `.env` 文件：
   - `.env` - 默认环境
   - `.env.dev` 或 `.env.development` - 开发环境
   - `.env.prod` 或 `.env.production` - 生产环境
   - `.env.test` - 测试环境
   - `.env.local` - 本地覆盖（添加到 .gitignore）

2. 将 `.env` 文件添加到 `pubspec.yaml`：
```yaml
flutter:
  assets:
    - .env
    - .env.dev
    - .env.prod
```

3. 初始化时启用 `.env` 支持：
```dart
await EnvironmentManager.instance.initialize(
  loadFromEnvFiles: true,  // 启用 .env 文件加载
  environments: [          // 找不到 .env 文件时的回退配置
    // ... 您的代码配置
  ],
);
```

### 优先级顺序

环境配置按以下优先级加载：
1. **`.env` 文件**（最高优先级）
2. **代码配置**（在 `initialize()` 中提供）
3. **保存的配置**（来自之前的运行）

### 访问环境变量

```dart
// 获取当前环境
final currentEnv = EnvironmentManager.instance.currentEnvironment;

// 获取特定变量
final apiUrl = EnvironmentManager.instance.getVariable<String>('API_URL');

// 监听环境变化
EnvironmentManager.instance.addListener(() {
  // 处理环境变化
});
```

### 最佳实践

1. **不要提交真实的 `.env` 文件** - 将它们添加到 `.gitignore`
2. **提供 `.env.example`** - 为其他开发者提供模板
3. **使用代码回退** - 以防 `.env` 文件丢失
4. **处理缺失的环境** - 优雅地处理重命名/删除的配置

## 高级用法

### 创建自定义模块

通过扩展 `DevModule` 创建您自己的自定义模块：

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

每个模块包都依赖于核心 `flutter_dev_panel` 包，可以根据您的需求独立安装。

### 开发设置

1. 克隆仓库
2. 在根目录运行 `flutter pub get`
3. 运行示例应用：`cd example && flutter run`

### 运行测试

```bash
flutter test
```

## 许可证

该项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件。

## 包结构

### 核心包（必需）
- **flutter_dev_panel** - 核心框架，包含：
  - UI 组件（DevPanelWrapper、DevPanel、悬浮按钮）
  - 环境管理（EnvironmentManager、.env 文件支持）
  - 基础设施（模块注册、DevLogger）
  - 配置管理（DevPanelConfig、PanelSettings）

### 可选模块包
- **flutter_dev_panel_console** - 控制台/日志模块，支持高级过滤和日志捕获
- **flutter_dev_panel_network** - 网络监控，支持 Dio、HTTP 和 GraphQL
- **flutter_dev_panel_device** - 设备信息和系统详情
- **flutter_dev_panel_performance** - FPS 监控、内存跟踪和性能指标

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