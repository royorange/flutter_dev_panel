# Flutter Dev Panel

一个功能丰富的Flutter应用开发调试面板，提供网络监控、环境切换、设备信息、性能监控等功能。

## ✨ 功能特性

- 🌐 **网络监控** - 拦截并显示所有HTTP请求，支持查看详情、搜索、过滤
- 🔄 **环境切换** - 动态切换开发、测试、生产环境配置
- 📱 **设备信息** - 显示设备型号、系统版本、屏幕信息等
- 📊 **性能监控** - 实时FPS监控，性能图表展示
- 🎯 **多种触发方式** - 悬浮按钮、摇一摇、手动调用
- 🔌 **模块化架构** - 支持自定义模块扩展
- 🎨 **Material Design 3** - 美观现代的UI设计

## 📦 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_dev_panel: ^0.0.1
```

## 🚀 快速开始

### 1. 初始化

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Flutter Dev Panel
  await FlutterDevPanel.init(
    config: DevPanelConfig(
      enabled: true,
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
      environments: Environment.defaultEnvironments(),
    ),
  );
  
  runApp(MyApp());
}
```

### 2. 包装应用

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterDevPanel.wrap(
        child: YourHomePage(),
        enableFloatingButton: true,
        enableShakeDetection: true,
      ),
    );
  }
}
```

### 3. 配置网络监控

```dart
import 'package:dio/dio.dart';

final dio = Dio();
FlutterDevPanel.addDioInterceptor(dio);
```

### 4. 使用环境配置

```dart
// 获取当前环境配置
final apiUrl = FlutterDevPanel.getEnvironmentConfig<String>('api_url');

// 切换环境
FlutterDevPanel.switchEnvironment('生产环境');
```

## 📖 详细使用

### 手动控制面板

```dart
// 显示面板
FlutterDevPanel.show();

// 隐藏面板
FlutterDevPanel.hide();

// 切换显示状态
FlutterDevPanel.toggle();
```

### 自定义模块

```dart
class CustomModule extends DevModule {
  CustomModule() : super(
    id: 'custom',
    name: '自定义模块',
    description: '自定义功能描述',
    icon: Icons.extension,
    type: ModuleType.custom,
  );

  @override
  Widget buildPage(BuildContext context) {
    return YourCustomPage();
  }
}

// 注册自定义模块
FlutterDevPanel.registerModule(CustomModule());
```

### 环境配置

```dart
// 创建环境
final env = Environment(
  name: '开发环境',
  config: {
    'api_url': 'https://dev.api.example.com',
    'timeout': 30000,
    'debug': true,
  },
);

// 使用环境配置
final apiUrl = FlutterDevPanel.getEnvironmentConfig<String>('api_url');
final timeout = FlutterDevPanel.getEnvironmentConfig<int>('timeout');
```

## 🎮 触发方式

1. **悬浮按钮** - 可拖拽的悬浮调试按钮
2. **摇一摇** - 摇动设备3次打开面板
3. **手动调用** - 代码中调用 `FlutterDevPanel.show()`

## 🔧 配置选项

```dart
DevPanelConfig(
  enabled: true,                    // 是否启用
  triggerModes: {                   // 触发方式
    TriggerMode.fab,
    TriggerMode.shake,
    TriggerMode.manual,
  },
  modules: [...],                    // 功能模块
  environments: [...],               // 环境配置
  themeConfig: ThemeConfig(...),    // 主题配置
  showInProduction: false,          // 是否在生产环境显示
)
```

## 📱 示例应用

查看 [example](./example) 目录了解完整的使用示例。

```bash
cd example
flutter run
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License - 详见 [LICENSE](./LICENSE) 文件