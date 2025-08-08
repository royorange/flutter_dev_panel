# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 项目介绍
- 功能介绍：这是一个 flutter 的插件库，用于实现一个 flutter用的 dev 开发面板
- 库名称： flutter_dev_panel
- 主要功能：
    - 网络监控
        - 支持多种HTTP库：Dio、http包、GraphQL（graphql_flutter）
        - 显示当前请求详细信息和状态，并可以点击请求查看详细信息
        - 支持请求/响应数据查看、搜索、过滤功能
        - 请求历史持久化存储，应用重启后可查看
        - FAB实时显示：pending请求数、成功/错误统计、最慢响应时间、流量统计
    - 动态切换
        - 通过配置切换不同的环境，比如开发环境、测试环境、生产环境以及对应的参数（如 api_url 等，可以自定义）
        - 切换主题：系统、暗色、亮色
        - 切换语言：中文、英文等等
    - 设备信息
        - 显示当前设备信息，包括设备型号、屏幕尺寸、系统版本、内存使用情况等
    - 性能监控
        - 显示当前性能指标，包括帧率、内存使用情况、电池使用情况等
        - 参考并使用 flutter_fps 库
        - 显示当前性能指标，包括帧率、内存使用情况、电池使用情况等
    - 上述各功能可配置以模块的方式配置，可以由使用者决定使用哪些模块
    - 可以配置启动方式
        - 调用方法弹出面板
        - 摇一摇弹出面板
        - 通过可以在顶层拖拽的 fab 按钮，点击弹出面板（默认选项）

### pubspec核心依赖：
    # 核心依赖
    get  # 状态管理和路由
    logger  # 日志工具

    # 网络监控
    dio  # HTTP 客户端库，用于拦截器实现
    intl  # 时间格式化

    # 设备信息
    device_info_plus  # 获取设备信息
    package_info_plus  # 获取应用包信息

    # 性能监控
    # 需要寻找合适的FPS监控库或自行实现

    # 存储
    shared_preferences  # 本地存储

    # UI 组件
    flutter_slidable  # 滑动操作组件
    shimmer  # 闪光加载效果

    # 传感器
    sensors_plus  # 传感器数据（摇一摇功能）

#### 高级特性：

  1. 插件化架构 - 支持自定义模块
  2. 主题定制 - 支持自定义颜色和样式
  3. 数据持久化 - 记住用户的调试设置
  4. 导出功能 - 导出日志和网络请求
  5. 远程调试 - 通过 WebSocket 远程查看日志

#### 要求：
  1. 零侵入 - 不影响生产代码
  2. 模块化 - 按需加载功能
  3. 可扩展 - 轻松添加新功能
  4. 可复用 - 多项目共享
  5. 社区驱动 - 开源贡献
  6. 使用 flutter 标准的代码风格和规范，命名准确，易于维护

## 项目结构

```
packages/
├── flutter_dev_panel_core/         # 核心包
│   └── lib/
│       ├── flutter_dev_panel_core.dart  # 主入口
│       └── src/
│           ├── core/                # 核心功能
│           │   ├── dev_panel_controller.dart     # 面板控制器
│           │   ├── module_registry.dart          # 模块注册中心
│           │   └── monitoring_data_provider.dart # 中央数据提供者
│           ├── models/              # 数据模型
│           │   ├── dev_module.dart  # 模块基类
│           │   └── dev_panel_config.dart # 配置
│           └── ui/                  # UI组件
│               ├── dev_panel.dart   # 主面板
│               ├── dev_panel_wrapper.dart # 包装器
│               └── widgets/
│                   ├── modular_monitoring_fab.dart # 模块化FAB
│                   └── shake_detector.dart # 摇一摇检测
│
├── flutter_dev_panel_network/      # 网络监控模块
│   └── lib/src/
│       ├── network_module.dart     # 网络模块实现
│       ├── network_monitor_controller.dart # 控制器（含会话统计）
│       ├── storage/
│       │   └── network_storage.dart # 持久化存储
│       └── interceptors/           # 多库支持
│           ├── base_interceptor.dart
│           ├── network_interceptor.dart     # Dio
│           ├── http_client_interceptor.dart # http包
│           └── graphql_interceptor.dart     # GraphQL
│
└── flutter_dev_panel_performance/  # 性能监控模块
    └── lib/src/
        ├── performance_module.dart # 性能模块实现
        └── performance_monitor_controller.dart
```

## 核心架构机制

### 1. 模块化插件机制

每个功能模块继承自`DevModule`基类：

```dart
abstract class DevModule {
  // 构建页面内容
  Widget buildPage(BuildContext context);
  
  // 构建FAB内容（可选，返回null则不显示）
  Widget? buildFabContent(BuildContext context) => null;
  
  // FAB显示优先级（数字越小优先级越高）
  int get fabPriority => 50;
}
```

### 2. 数据订阅更新机制

#### MonitoringDataProvider（中央数据提供者）

```dart
class MonitoringDataProvider extends ChangeNotifier {
  // 性能数据
  double? fps;
  double? memory;
  
  // 网络数据（会话统计）
  int totalRequests;
  int errorRequests;
  int pendingRequests;
  
  // 更新并通知
  void updatePerformanceData({...}) {
    notifyListeners();
  }
}
```

#### 数据流向

```
模块Controller → MonitoringDataProvider → FAB/通知系统
     ↓                    ↓                      ↓
  产生数据            通知监听者            更新显示
```

### 3. FAB显示机制

#### ModularMonitoringFab工作流程

1. **监听MonitoringDataProvider变化**
2. **数据变化时查询各模块的buildFabContent()**
3. **自动展开/收起逻辑**
   - 有内容自动展开
   - 无内容自动收起
   - 用户手动操作后保持状态（_isManuallyCollapsed标志）

### 4. 网络监控特殊机制

#### 会话统计与历史数据分离

```dart
class NetworkMonitorController {
  // 所有请求（包含历史）
  List<NetworkRequest> _requests;
  
  // 当前会话统计（用于FAB显示）
  int _sessionRequestCount;    // 本次会话总请求
  int _sessionPendingCount;    // 进行中
  int _sessionSuccessCount;    // 成功
  int _sessionErrorCount;      // 错误
  
  // FAB只在有会话活动时显示
  bool get hasSessionActivity => _sessionRequestCount > 0;
}
```

应用重启后：
- 历史记录加载到_requests（可在列表查看）
- 会话统计归零（FAB不显示历史数据）

### 5. 多HTTP库支持

```
BaseNetworkInterceptor（统一接口）
        ↓
┌───────┼───────┬────────────┐
Dio   HTTP   GraphQL    Custom

使用方式：
NetworkModule.attachToDio(dio);
NetworkModule.createHttpClient();
NetworkModule.createGraphQLClient(endpoint: '...');
```

## 开发命令

```bash
# 获取依赖
flutter pub get

# 运行测试
flutter test

# 分析代码
flutter analyze

# 格式化代码
flutter format lib/

# 构建示例应用
cd example && flutter run
```

## 设计原则

1. **Material Design 3** - 使用最新的Material Design规范，确保界面美观现代
2. **性能优先** - 调试面板本身不应影响应用性能
3. **易于集成** - 简单的API，最少的配置
4. **可扩展性** - 支持自定义面板和功能扩展
5. **生产安全** - 自动在生产环境禁用
6. **模块化设计** - 每个功能独立成模块，可按需加载

## 关键实现要点

### FAB更新时机
- 模块数据变化时通过MonitoringDataProvider通知
- FAB监听到通知后调用各模块的buildFabContent()
- 模块返回null表示不显示，返回Widget表示要显示的内容

### 数据持久化
- NetworkModule使用SharedPreferences保存请求历史
- 应用重启后自动加载，但不触发FAB显示（会话统计归零）

### 模块注册
```dart
// 在main.dart中注册模块
FlutterDevPanel.registerModule(NetworkModule());
FlutterDevPanel.registerModule(PerformanceModule());

// 包装应用
FlutterDevPanel.wrap(child: MyApp())
```