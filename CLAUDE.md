# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 项目介绍
- 功能介绍：这是一个 flutter 的插件库，用于实现一个 flutter用的 dev 开发面板
- 库名称： flutter_dev_panel
- 主要功能：
    - 网络监控
        - 参考并使用 alice 库
        - 显示当前请求详细信息和状态，并可以点击请求查看详细信息
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
    get: ^4.6.6
    logger: ^2.0.2

    # 网络监控
    alice: ^0.4.2  # HTTP 请求监控

    # 设备信息
    device_info_plus: ^10.1.0
    package_info_plus: ^5.0.1

    # 性能监控
    flutter_fps: ^2.0.0

    # 存储
    shared_preferences: ^2.2.2

    # UI 组件
    flutter_slidable: ^3.0.1
    shimmer: ^3.0.0

    # 传感器（摇一摇）
    sensors_plus: ^4.0.2

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
lib/
├── flutter_dev_panel.dart          # 主入口文件
└── src/
    ├── core/                        # 核心功能
    │   ├── dev_panel_controller.dart  # 面板控制器
    │   ├── environment_manager.dart   # 环境管理器
    │   ├── module_manager.dart        # 模块管理器
    │   └── storage.dart               # 持久化存储
    ├── models/                      # 数据模型
    │   ├── environment.dart         # 环境配置模型
    │   ├── module.dart              # 模块定义
    │   └── theme_config.dart        # 主题配置
    ├── modules/                     # 功能模块
    │   ├── network/                 # 网络监控模块
    │   ├── performance/             # 性能监控模块
    │   ├── device_info/             # 设备信息模块
    │   └── environment/             # 环境切换模块
    ├── ui/                          # UI组件
    │   ├── dev_panel.dart           # 主面板
    │   ├── widgets/                 # 通用组件
    │   │   ├── floating_button.dart
    │   │   └── shake_detector.dart
    │   └── pages/                   # 页面
    └── utils/                       # 工具类
        ├── extensions.dart
        └── constants.dart
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