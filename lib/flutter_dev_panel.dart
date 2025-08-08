library flutter_dev_panel;

import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart' as core;

// 导出核心功能，使用更简洁的命名
export 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart' 
    hide FlutterDevPanelCore;
export 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
export 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';
export 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

/// Flutter开发面板的主入口类
/// 提供更简洁的API访问方式
class FlutterDevPanel {
  FlutterDevPanel._();
  
  /// 获取单例实例
  static core.FlutterDevPanelCore get instance => core.FlutterDevPanelCore.instance;
  
  /// 初始化开发面板
  static void initialize({
    core.DevPanelConfig config = const core.DevPanelConfig(),
    List<core.DevModule> modules = const [],
  }) {
    core.FlutterDevPanelCore.instance.initialize(
      config: config,
      modules: modules,
    );
  }
  
  /// 打开开发面板（需要BuildContext）
  static void open(BuildContext context) {
    core.FlutterDevPanelCore.instance.open(context);
  }
  
  /// 关闭开发面板
  static void close() {
    core.FlutterDevPanelCore.instance.close();
  }
  
  /// 重置开发面板
  static void reset() {
    core.FlutterDevPanelCore.instance.reset();
  }
}