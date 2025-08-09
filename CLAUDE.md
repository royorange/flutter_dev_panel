# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Flutter Dev Panel - 模块化Flutter调试面板

## 项目概述
一个零侵入、模块化的Flutter调试面板插件，开发者可按需加载功能模块。

## 核心功能模块

### 1. Console/Logs 日志监控
- 自动捕获：print、Logger包、Flutter错误
- 日志级别过滤和搜索
- Logger多行输出智能合并
- 设置持久化（maxLogs、autoScroll等）
- FAB显示错误/警告计数

### 2. Network 网络监控  
- 支持Dio、http、GraphQL
- 请求历史持久化
- 会话统计（当前应用生命周期）
- FAB显示pending/成功/错误统计

### 3. Environment 环境管理
- Development/Production环境切换
- 环境变量管理（api_url等）
- 配置持久化到SharedPreferences
- 支持监听环境变化（ChangeNotifier）

### 4. Device Info 设备信息
- 设备型号、屏幕尺寸、系统版本
- PPI计算和显示
- 内存使用情况

### 5. Performance 性能监控
- FPS监控（使用flutter_fps）
- 内存和电池使用情况
- 实时图表展示

## 设计原则
- **零侵入** - 不影响生产代码
- **模块化** - 按需加载功能  
- **高性能** - 调试面板不影响应用性能
- **标准化** - Flutter标准代码风格

## 项目结构
```
packages/
├── flutter_dev_panel_core/         # 核心包
│   ├── dev_logger.dart            # 日志捕获管理
│   ├── environment_manager.dart   # 环境管理
│   └── module_registry.dart       # 模块注册
├── flutter_dev_panel_console/     # 日志模块
├── flutter_dev_panel_network/     # 网络模块  
├── flutter_dev_panel_device/      # 设备模块
└── flutter_dev_panel_performance/ # 性能模块
```

## 核心机制

### 1. 模块系统
每个模块继承 `DevModule` 基类，提供：
- `buildPage()` - 构建页面内容
- `buildFabContent()` - FAB显示内容（可选）
- `fabPriority` - 显示优先级

### 2. 日志捕获（DevLogger）
```dart
// Zone拦截print
runZonedGuarded(() => runApp(MyApp()), 
  (error, stack) => DevLogger.instance.error(...),
  zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) => DevLogger.instance.info(line)
  )
);
```

特性：
- Logger包多行智能合并
- ANSI转义序列清理
- 配置持久化（maxLogs、autoScroll）
- 暂停状态不持久化

### 3. 环境管理（EnvironmentManager）
```dart
// 初始化
EnvironmentManager.instance.initialize(
  environments: [dev, prod],
  defaultEnvironment: 'Development'
);

// 监听变化
EnvironmentManager.instance.addListener(_updateConfig);

// 获取变量
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');
```

### 4. 网络监控
- 会话统计：当前应用生命周期的请求
- 历史数据：持久化到SharedPreferences
- 多库支持：Dio、http、GraphQL统一接口

### 5. FAB机制
- 监听 `MonitoringDataProvider` 变化
- 查询各模块 `buildFabContent()`
- 自动展开/收起（用户操作后保持状态）

## 使用方式

```dart
// 1. 初始化环境
EnvironmentManager.instance.initialize(environments: [...]);

// 2. 初始化面板
FlutterDevPanel.initialize(
  config: DevPanelConfig(...),
  modules: [ConsoleModule(), NetworkModule(), ...],
  enableLogCapture: true,
);

// 3. 包装应用
runZonedGuarded(
  () => runApp(DevPanelWrapper(child: MyApp())),
  (error, stack) => DevLogger.instance.error(...)
);
```

## 注意事项
- 插件库不应包含mock数据或示例URL
- 环境配置由使用者定义，不内置默认值
- UI文案使用英文
- 避免使用外部状态管理库（如GetX）以防冲突