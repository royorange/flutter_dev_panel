# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Flutter Dev Panel - 模块化Flutter调试面板

## 项目概述
一个零侵入、模块化的Flutter调试面板插件，开发者可按需加载功能模块。遵循Firebase等行业标准的模块化架构模式。

## 架构设计

### 包结构（重要：已重构）
```
flutter_dev_panel/              # 核心包（必需）
├── lib/
│   └── src/
│       ├── core/               # 核心功能
│       │   ├── dev_logger.dart            # 日志捕获管理
│       │   ├── environment_manager.dart   # 环境管理（内置功能）
│       │   ├── module_registry.dart       # 模块注册
│       │   └── dev_panel_controller.dart  # 面板控制器
│       ├── models/             # 数据模型
│       │   ├── dev_module.dart            # 模块基类
│       │   ├── dev_panel_config.dart      # 配置类
│       │   └── environment_config.dart    # 环境配置
│       └── ui/                 # UI组件
│           ├── dev_panel_wrapper.dart     # 包装器（提供FAB和手势）
│           ├── dev_panel.dart             # 主面板UI
│           └── widgets/                    # 通用组件
└── packages/                   # 可选模块（独立包）
    ├── flutter_dev_panel_console/     # 日志模块
    ├── flutter_dev_panel_network/     # 网络模块  
    ├── flutter_dev_panel_device/      # 设备模块
    └── flutter_dev_panel_performance/ # 性能模块
```

**注意**：flutter_dev_panel_core 已合并到主包，环境管理是核心包的内置功能，不是独立模块。

## 核心机制

### 1. 模块系统
每个模块继承 `DevModule` 基类：
```dart
abstract class DevModule {
  final String id;           // 唯一标识
  final String name;          // 显示名称
  final IconData icon;        // 图标
  final int order;           // 排序优先级
  
  Widget buildPage(BuildContext context);           // 构建页面
  Widget? buildFabContent(BuildContext context);    // FAB内容（可选）
  int get fabPriority => 0;                        // FAB显示优先级
}
```

### 2. DevPanelWrapper 机制
- **作用**：零侵入式集成，只需包装根Widget
- **功能**：
  - 自动管理FAB显示/隐藏
  - 提供摇一摇手势检测
  - Modal Bottom Sheet展示面板
  - 生产环境自动禁用
  - 监听配置变化实时更新

### 3. 日志捕获（DevLogger）
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
- Logger包多行智能合并（通过_flushLoggerBuffer处理）
- ANSI转义序列自动清理（不显示颜色，只保留文本）
- 配置持久化（maxLogs、autoScroll）
- 暂停状态不持久化
- 清除日志时触发FAB更新

### 4. 环境管理（EnvironmentManager）
**优先级**：.env文件 > 代码配置 > 保存的配置

```dart
// 初始化
await EnvironmentManager.instance.initialize(
  loadFromEnvFiles: true,     // 启用.env文件
  environments: [...],         // 代码配置（回退）
  defaultEnvironment: 'Development'
);

// 获取变量（支持默认值）
final apiUrl = EnvironmentManager.instance.getVariable<String>(
  'api_url',
  defaultValue: 'https://api.example.com'
);

// 切换环境
EnvironmentManager.instance.switchEnvironment('Production');

// 监听变化
EnvironmentManager.instance.addListener(_updateConfig);
```

### 5. 网络监控
- **会话统计**：当前应用生命周期的请求
- **历史数据**：持久化到SharedPreferences
- **多库支持**：
  ```dart
  // Dio
  NetworkModule.attachToDio(dio);
  
  // GraphQL
  final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);
  
  // http包
  final client = NetworkModule.createHttpClient();
  ```

### 6. FAB机制
- 监听 `MonitoringDataProvider` 变化
- 查询各模块 `buildFabContent()`
- 自动展开/收起（3秒后收起，用户操作后保持）
- 各模块FAB显示内容：
  - Console: 错误/警告计数
  - Network: 请求统计（pending/成功/错误）
  - Performance: FPS、内存、瞬时丢帧警告

### 7. 生产环境安全
```dart
// 在initialize中自动处理
static void initialize(...) {
  if (kDebugMode) {  // 只在Debug模式执行
    // 初始化逻辑
  }
}
```

## 创建新模块指南

### 1. 创建模块包
```bash
# 在packages目录下创建
flutter create --template=package flutter_dev_panel_xxx
```

### 2. 添加依赖
```yaml
dependencies:
  flutter_dev_panel:
    path: ../..
```

### 3. 实现模块类
```dart
class XxxModule extends DevModule {
  const XxxModule() : super(
    id: 'xxx',
    name: 'Xxx',
    icon: Icons.xxx,
    order: 30,
  );

  @override
  Widget buildPage(BuildContext context) {
    return XxxPage();
  }

  @override
  Widget? buildFabContent(BuildContext context) {
    // 可选：返回FAB显示内容
    return hasData ? Text('数据') : null;
  }
}
```

### 4. 实现持久化（如需要）
```dart
class XxxStorage {
  static Future<void> saveData(data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('xxx_data', jsonEncode(data));
    } catch (e) {
      // 优雅降级
    }
  }
}
```

## 测试要求

### 1. 单元测试规范
- 每个模块必须有独立的测试文件
- 测试文件放在 `test/` 目录
- SharedPreferences警告是预期的，可忽略

### 2. 测试覆盖要求
```dart
// 模块注册测试
test('Module registers correctly', () {
  final module = XxxModule();
  expect(module.name, 'Xxx');
  expect(module.icon, Icons.xxx);
});

// 功能测试
test('Core functionality works', () {
  // 测试核心功能
});

// 持久化测试（如有）
test('Storage handles errors gracefully', () {
  // 测试优雅降级
});
```

### 3. 运行测试
```bash
# 运行所有测试
./test/run_all_tests.sh

# 单独测试模块
flutter test packages/flutter_dev_panel_xxx/test
```

### 4. 测试注意事项
- SharedPreferences在测试环境不可用是正常的
- 使用 `TestWidgetsFlutterBinding.ensureInitialized()` 初始化
- 避免测试依赖真实的平台插件
- 确保测试可独立运行

## 代码规范

### 1. 命名规范
- 模块ID：小写下划线（`network_monitor`）
- 类名：大驼峰（`NetworkModule`）
- 文件名：小写下划线（`network_module.dart`）

### 2. 错误处理
```dart
try {
  // 可能失败的操作
} catch (e) {
  debugPrint('Error: $e');
  // 返回默认值或空状态，不要崩溃
}
```

### 3. 性能考虑
- 避免在build方法中进行耗时操作
- 使用 `const` 构造函数
- 合理使用 `setState`，避免不必要的重建

### 4. UI规范
- 遵循Material Design
- 支持亮色/暗色主题
- 文案使用英文
- 提供适当的loading和empty状态

## 注意事项

### 必须遵守
- ✅ 零侵入原则：不修改用户业务代码
- ✅ 生产安全：使用 `kDebugMode` 而非 `assert`
- ✅ 优雅降级：插件不可用时不崩溃
- ✅ 模块独立：模块间不直接依赖

### 避免
- ❌ 包含mock数据或示例URL
- ❌ 环境配置内置默认值（由用户定义）
- ❌ 使用外部状态管理库（如GetX）
- ❌ 在生产代码中使用 `print`

### 最佳实践
- 使用 `debugPrint` 而非 `print`
- 持久化数据时处理异常
- 提供配置选项而非硬编码
- 文档注释说明公共API

## 发布检查清单
- [ ] 所有测试通过
- [ ] 移除调试代码
- [ ] 更新版本号
- [ ] 更新CHANGELOG
- [ ] 检查生产环境安全
- [ ] 文档完整准确