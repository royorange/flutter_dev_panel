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

### 可用模块

#### 控制台模块
- 实时日志捕获（print、debugPrint、Logger 包）
- 日志级别过滤（verbose、debug、info、warning、error）
- 搜索和过滤功能
- 自动 ANSI 颜色代码处理
- 可配置的日志保留和自动滚动

#### 网络模块
- HTTP 请求/响应监控
- GraphQL 查询和变更跟踪
- 支持 Dio、http 和 GraphQL 包
- 请求历史持久化
- 详细的请求/响应检查
- 带语法高亮的 JSON 查看器

#### 设备模块
- 设备型号和规格
- 屏幕尺寸和 PPI 计算
- 操作系统信息
- 平台特定详情
- 应用包信息

#### 性能模块
- 实时 FPS 监控
- 内存使用跟踪
- 丢帧检测
- 性能图表和趋势
- 内存峰值跟踪

#### 环境模块
- 环境切换（开发/生产）
- 环境变量管理
- 配置持久化
- 实时环境更新

## 安装

在 `pubspec.yaml` 中添加以下依赖：

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

## 快速开始

### 1. 初始化开发面板

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 初始化环境配置
    EnvironmentManager.instance.initialize(
      environments: [
        const EnvironmentConfig(
          name: 'Development',
          variables: {
            'api_url': 'https://dev-api.example.com',
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
    
    // 初始化 Flutter Dev Panel
    FlutterDevPanel.initialize(
      config: const DevPanelConfig(
        enabled: true,
        triggerModes: {TriggerMode.fab, TriggerMode.shake},
        showInProduction: false,
      ),
      modules: [
        const ConsoleModule(),
        NetworkModule(),
        const DeviceModule(),
        const PerformanceModule(),
      ],
      enableLogCapture: true,
    );
    
    runApp(MyApp());
  }, (error, stack) {
    DevLogger.instance.error('未捕获的错误', 
      error: error.toString(), 
      stackTrace: stack.toString()
    );
  });
}
```

### 2. 包装您的应用

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DevPanelWrapper(
        child: YourHomePage(),
      ),
    );
  }
}
```

### 3. 配置网络监控（可选）

对于 Dio：
```dart
final dio = Dio();
NetworkModule.attachToDio(dio);
```

对于 GraphQL：
```dart
final graphQLClient = GraphQLClient(
  link: HttpLink('https://api.example.com/graphql'),
  cache: GraphQLCache(),
);
final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);
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

## 访问开发面板

有三种方式打开开发面板：

1. **悬浮按钮**: 点击悬浮调试按钮
2. **摇一摇手势**: 摇动您的设备
3. **程序化调用**: 
```dart
FlutterDevPanel.open(context);
```

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
flutter_dev_panel/
├── lib/
│   ├── core/              # 核心功能
│   ├── modules/            # 模块接口
│   └── ui/                 # UI 组件
├── packages/
│   ├── flutter_dev_panel_console/     # 控制台模块
│   ├── flutter_dev_panel_network/     # 网络模块
│   ├── flutter_dev_panel_device/      # 设备信息模块
│   └── flutter_dev_panel_performance/ # 性能模块
└── example/                            # 示例应用
```

## 贡献

我们欢迎贡献！详情请参阅我们的[贡献指南](CONTRIBUTING.md)。

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

## 支持

- **问题反馈**: [GitHub Issues](https://github.com/yourusername/flutter_dev_panel/issues)
- **讨论**: [GitHub Discussions](https://github.com/yourusername/flutter_dev_panel/discussions)
- **文档**: [API 文档](https://pub.dev/documentation/flutter_dev_panel/latest/)

## 致谢

特别感谢所有帮助改进此项目的贡献者。

## 路线图

- [ ] 自定义主题支持
- [ ] 导出/导入配置
- [ ] 网络请求重放
- [ ] 性能分析导出
- [ ] WebSocket 监控
- [ ] 数据库查询监控
- [ ] 状态管理检查

## 相关项目

- [flutter_dev_panel_console](https://pub.dev/packages/flutter_dev_panel_console)
- [flutter_dev_panel_network](https://pub.dev/packages/flutter_dev_panel_network)
- [flutter_dev_panel_device](https://pub.dev/packages/flutter_dev_panel_device)
- [flutter_dev_panel_performance](https://pub.dev/packages/flutter_dev_panel_performance)