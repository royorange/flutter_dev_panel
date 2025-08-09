# Flutter Dev Panel Console Module

Console 模块为 Flutter Dev Panel 提供完整的日志捕获和查看功能。

## 功能特性

### 日志捕获
- ✅ 自动捕获 `print` 和 `debugPrint` 语句
- ✅ 自动捕获 `Logger` 包输出（无需配置）
- ✅ 捕获 Flutter 框架错误和异常
- ✅ 捕获未处理的异步错误
- ✅ 智能识别日志级别和来源

### 日志查看
- 🔍 实时搜索和过滤
- 📊 按日志级别过滤（Verbose、Debug、Info、Warning、Error）
- 🎨 颜色编码的日志级别
- ⏰ 时间戳显示
- ⏸️ 暂停/继续接收新日志
- 📜 自动滚动到最新日志
- 📋 点击查看详细信息和堆栈跟踪

### 灵活配置
- ⚙️ 可配置的日志捕获选项
- 🎯 三种预设模式：最小、开发、完整
- 🔧 详细的自定义配置

## 使用方法

### 基本使用

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';

void main() {
  runZonedGuarded(() async {
    FlutterDevPanel.initialize(
      modules: [
        const ConsoleModule(),
        // 其他模块...
      ],
      enableLogCapture: true,
    );
    
    runApp(MyApp());
  }, (error, stack) {
    // 错误会被自动捕获
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      DevLogger.instance.info('[Print] $line');
      parent.print(zone, line);
    },
  ));
}
```

### 配置日志捕获

```dart
// 使用预设配置
DevLogger.instance.updateConfig(
  const LogCaptureConfig.minimal(),     // 最小模式：仅应用日志和错误
  // const LogCaptureConfig.development(), // 开发模式：应用、库和网络日志（默认）
  // const LogCaptureConfig.full(),       // 完整模式：捕获所有日志
);

// 自定义配置
DevLogger.instance.updateConfig(
  const LogCaptureConfig(
    captureFrameworkLogs: false,  // Flutter 框架日志
    captureNetworkLogs: true,     // 网络请求日志
    captureSystemLogs: false,     // 系统平台日志
    captureLibraryLogs: true,     // 第三方库日志
    captureVerbose: true,         // Verbose 级别日志
    captureAllErrors: true,       // 所有错误（推荐开启）
    maxLogs: 1000,               // 最大日志数量
  ),
);
```

### 在 Console UI 中配置

用户可以通过 Console 页面右上角的设置按钮动态调整日志捕获配置：

1. **快速预设**：一键切换最小、开发、完整模式
2. **详细设置**：分别开关各类日志捕获
3. **实时生效**：配置更改立即生效，无需重启

## 日志来源识别

Console 模块会自动识别并标记日志来源：

- `[Print]` - print 语句
- `[Debug]` - debugPrint 语句
- `[Logger]` - Logger 包输出
- `[Flutter]` - Flutter 框架日志
- `[Network]` - 网络请求日志
- `[System]` - 系统平台日志

## 与 Logger 包集成

无需任何配置，Console 模块会自动捕获 Logger 包的输出：

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// 这些都会被自动捕获
logger.t('Trace message');
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: exception, stackTrace: stack);
```

## 性能考虑

- **最小模式**：性能影响最小，仅捕获必要日志
- **开发模式**：平衡性能和功能，适合日常开发
- **完整模式**：捕获所有日志，可能影响性能，适合调试复杂问题

## 配置建议

| 场景 | 推荐配置 | 说明 |
|-----|---------|-----|
| 日常开发 | `LogCaptureConfig.development()` | 默认配置，平衡性能和功能 |
| 性能调试 | `LogCaptureConfig.minimal()` | 最小化日志，减少性能影响 |
| 问题排查 | `LogCaptureConfig.full()` | 捕获所有日志，帮助定位问题 |
| 生产环境 | 禁用或使用 `minimal` | 减少性能开销 |

## 注意事项

1. 日志捕获仅在非 Release 模式下工作
2. 捕获更多日志会增加内存使用和性能开销
3. 默认最多保存 1000 条日志，可通过配置调整
4. Flutter 框架内部日志（如 "Reloaded" 等）默认不捕获，可通过配置开启