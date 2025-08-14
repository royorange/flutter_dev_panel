# Flutter Dev Panel

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel.svg)](https://pub.dev/packages/flutter_dev_panel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个模块化、零侵入的 Flutter 应用调试面板，提供实时监控和调试功能。

[English Documentation](README.md)

## 特性

### 核心能力
- **零侵入**：不影响生产代码
- **模块化架构**：按需加载所需模块
- **高性能**：优化以最小化对应用性能的影响
- **多种触发方式**：悬浮按钮、摇一摇手势或程序化调用

### 内置功能

#### 环境管理
- 环境切换（开发/生产/自定义）
- 环境变量管理
- 配置持久化
- 实时环境更新
- .env 文件支持
- 优先级配置加载（--dart-define > .env 文件 > 代码配置）

#### 主题管理
- 明亮/暗黑/跟随系统主题模式
- 与应用主题双向同步
- 主题持久化

## 可用模块

### Console 模块 (`flutter_dev_panel_console`)
- 实时日志捕获（print、debugPrint、Logger 包）
- 日志级别过滤（verbose、debug、info、warning、error）
- 搜索和过滤功能
- 可配置的日志保留和自动滚动
- 智能合并 Logger 包的多行输出

### Network 模块 (`flutter_dev_panel_network`)
- HTTP 请求/响应监控
- GraphQL 查询和变更跟踪
- 支持 Dio、http 和 GraphQL 包
- 请求历史持久化
- 详细的请求/响应检查
- 带语法高亮的 JSON 查看器

### Device 模块 (`flutter_dev_panel_device`)
- 设备型号和规格
- 屏幕尺寸和 PPI 计算
- 操作系统信息
- 平台特定详情
- 应用包信息

### Performance 模块 (`flutter_dev_panel_performance`)
- 实时 FPS 监控
- 内存使用跟踪
- 帧丢失检测
- 性能图表和趋势
- 内存峰值跟踪

## 安装

### 选项 1：仅核心包（最小化）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
```

### 选项 2：包含特定模块（推荐）

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0    # 日志功能
  flutter_dev_panel_network: ^1.0.0    # 网络监控
  # 仅添加需要的模块
```

### 选项 3：所有模块

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

## 快速开始

> **重要**：根据需求选择正确的初始化方法：
> - **方法 1**：自动设置并完整捕获日志 ✅（推荐）
> - **方法 2**：自定义 Zone 设置以与其他工具集成 🔧
> - **方法 3**：传统初始化，无 print 拦截 ⚠️

### 方法 1：使用 FlutterDevPanel.init（推荐）

自动设置 Zone 来拦截 print 语句，使 Logger 包集成自动化。

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// 导入需要的模块
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化代码...
  await initServices();
  
  // 使用 FlutterDevPanel.init 与 appRunner
  await FlutterDevPanel.init(
    () => runApp(const MyApp()),
    modules: [
      ConsoleModule(),
      NetworkModule(),
      DeviceModule(),
      PerformanceModule(),
      // 根据需要添加更多模块
    ],
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
      // enableLogCapture: true,  // 拦截 print 语句（默认）
    ),
  );
}
```

### 方法 2：自定义 Zone 设置（与 Sentry/Crashlytics 集成）

用于与错误跟踪服务（如 Sentry 或 Firebase Crashlytics）集成。

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // 初始化服务
    await initServices();
    
    // 初始化 Dev Panel
    FlutterDevPanel.initialize(
      modules: [ConsoleModule(), NetworkModule()],
    );
    
    runApp(const MyApp());
  }, (error, stack) {
    // 发送到多个服务
    FlutterDevPanel.logError('Uncaught error', error: error, stackTrace: stack);
    Sentry.captureException(error, stackTrace: stack);
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      FlutterDevPanel.log(line);  // 捕获到 Dev Panel
      parent.print(zone, line);    // 仍然打印到控制台
    },
  ));
}
```

### 方法 3：传统初始化（简单设置）

**注意**：此方法不会自动捕获 print 语句。Console 模块只会显示直接调用 `FlutterDevPanel.log()` 的日志。

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// 导入需要的模块
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境
  // --dart-define 自动覆盖匹配的键
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

  // 使用选定的模块初始化 dev panel
  FlutterDevPanel.initialize(
    modules: [
      NetworkModule(),
      // 根据需要添加更多模块
    ],
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 监听 dev panel 的主题变化
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,  // 应用 dev panel 的主题
          builder: (context, child) {
            return DevPanelWrapper(
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: MyHomePage(),
        );
      },
    );
  }
}
```

## 使用

### 访问面板
- **悬浮按钮**：点击 FAB（默认）
- **摇一摇手势**：摇动设备（仅限移动设备）
- **程序化调用**：`FlutterDevPanel.open(context)`

### 日志记录

Flutter Dev Panel 提供统一的日志 API：

```dart
// 简单日志记录
FlutterDevPanel.log('User action');
FlutterDevPanel.logInfo('Request completed');
FlutterDevPanel.logWarning('Low memory');
FlutterDevPanel.logError('Failed to load', error: e, stackTrace: s);

// 自动 print 拦截（使用 FlutterDevPanel.init 时）
print('This will be captured automatically');
debugPrint('This too');

// Logger 包也会被自动捕获
final logger = Logger();
logger.i('Info from Logger package');
```

详细的日志功能，请参阅 [Console 模块文档](https://pub.dev/packages/flutter_dev_panel_console)。

### 集成方法

#### 使用 Builder 模式（推荐）
```dart
// 适用于 MaterialApp、GetMaterialApp 等
MaterialApp(
  builder: (context, child) {
    return DevPanelWrapper(
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: MyHomePage(),
)
```

Builder 模式适用于：
- GetX (`GetMaterialApp`)
- Auto Route 导航
- 复杂导航设置的应用
- 全局覆盖需求

## 高级功能

### 环境变量访问
```dart
// 获取环境变量（自动从 --dart-define 注入）
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');
final isDebug = EnvironmentManager.instance.getVariable<bool>('debug');
```

### 网络监控设置

对于 **Dio**（推荐）：
```dart
final dio = Dio();
NetworkModule.attachToDio(dio);  // 直接修改 dio
// 正常使用 dio
```

对于 **GraphQL**（推荐）：
```dart
final graphQLClient = GraphQLClient(
  link: HttpLink('https://api.example.com/graphql'),
  cache: GraphQLCache(),
);

// 重要：attachToGraphQL 返回包装后的 client
final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);

// 对所有 GraphQL 操作使用返回的 monitoredClient
Query(
  options: QueryOptions(...),
  builder: (result, {...}) {
    // UI 代码
  },
  client: monitoredClient,  // 使用包装后的 client
);
```

对于 **HTTP**（替代方案）：
```dart
// 使用拦截器模式
final client = NetworkInterceptor.http(http.Client());
```

## 环境管理

### 配置优先级
环境变量按以下优先级顺序加载（从高到低）：
1. **--dart-define** - 命令行参数（自动检测）
2. **.env 文件** - 环境特定文件（如果存在）
3. **代码配置** - `initialize()` 中的默认值
4. **保存的配置** - 之前运行时的值

**工作原理：**
- 系统自动从配置中发现所有键
- 通过 --dart-define 传递的任何匹配键将覆盖其他源
- 键匹配不区分大小写，支持格式变化（snake_case、dash-case）

### 推荐设置

1. **创建环境文件：**
```bash
# .env.example（提交到 git - 模板）
API_URL=https://api.example.com
API_KEY=your-key-here
ENABLE_ANALYTICS=false

# .env.development（提交到 git - 安全默认值）
API_URL=https://dev.api.example.com
ENABLE_ANALYTICS=false

# .env.production（提交到 git - 非敏感配置）
API_URL=https://api.example.com
ENABLE_ANALYTICS=true
# 敏感值通过 CI/CD 中的 --dart-define 注入
```

2. **添加到 pubspec.yaml（用于生产构建）：**
```yaml
flutter:
  assets:
    - .env.production  # 发布构建需要
```

3. **添加到 .gitignore（仅本地覆盖）：**
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
# 开发（使用 .env.development）
flutter run

# 生产构建，从 CI/CD 获取密钥
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
- `.env.development` - 开发 URL 和非敏感配置
- `.env.production` - 生产 URL 和非敏感配置
- `.env.example` - 包含所有变量文档的模板

**通过 CI/CD 注入（--dart-define）：**
- API 密钥、令牌、密码
- 第三方服务凭据
- 任何敏感配置
- 环境特定覆盖

**优势：**
- 敏感数据永不接触代码库
- 灵活的部署配置
- 轻松的本地开发设置

## 面板配置

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    triggerModes: {
      TriggerMode.fab,
      TriggerMode.shake,
    },
    enableLogCapture: true,  // 捕获 print 语句（默认：true）
  ),
  modules: [...],
);
```

## 主题集成

如果应用已有主题管理，可以与 dev panel 同步，以下是示例代码：

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
    
    // 将 dev panel 与应用主题同步
    ThemeManager.instance.setThemeMode(_themeMode);
    
    // 监听 dev panel 主题变化
    ThemeManager.instance.themeMode.addListener(_onThemeChanged);
  }
  
  void _onThemeChanged() {
    setState(() {
      _themeMode = ThemeManager.instance.themeMode.value;
      // 保存到应用偏好
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
- 在启动时加载现有的主题偏好
- 将 dev panel 与应用当前主题同步
- 通过 dev panel 更改时更新应用偏好
- 保持应用和 dev panel 主题之间的一致性

## 模块配置

### Console 模块
```dart
// 通过模块初始化配置
ConsoleModule(
  logConfig: const LogCaptureConfig(
    maxLogs: 1000,              // 保留的最大日志数（默认：1000）
    autoScroll: true,           // 自动滚动到最新日志（默认：true）
    combineLoggerOutput: true,  // 合并 Logger 包多行输出（默认：true）
  ),
)

// 默认配置通常足够
ConsoleModule()  // 使用默认值：maxLogs=1000, autoScroll=true, combineLoggerOutput=true
```

### Performance 模块
性能模块自动监控：
- 帧率（FPS）
- 内存使用和峰值
- 帧丢失检测
- 实时性能图表

### Device 模块
设备模块显示：
- 设备信息（型号、操作系统、版本）
- 屏幕详情（尺寸、分辨率、PPI）
- 应用信息（包名、版本、构建号）

## 生产安全

面板为生产构建提供多层保护：

### 1. 默认行为
- **调试模式**：自动启用
- **发布模式**：自动禁用（代码被 tree shaking 优化）

### 2. 在生产环境强制启用
对于内部测试版本，可以在发布模式下启用面板：

```bash
# 构建时启用开发面板
flutter build apk --release --dart-define=FORCE_DEV_PANEL=true

# CI/CD 示例
flutter build ios --release \
  --dart-define=FORCE_DEV_PANEL=true \
  --dart-define=API_KEY=${{ secrets.API_KEY }}
```

### 3. API 保护
所有公共 API 使用编译时常量检查：
- API 在发布模式下变成空操作（除非 `FORCE_DEV_PANEL=true`）
- Tree-shaking 自动移除未使用代码
- 生产环境零运行时开销

### 4. 生产环境零开销
当未强制启用时：
- 不渲染 UI 组件
- 不捕获日志
- 不进行性能监控
- 代码被 tree-shaking 完全移除
- 不影响应用大小和性能

## 贡献

欢迎贡献！请随时提交 Pull Request。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 [LICENSE](LICENSE) 文件。