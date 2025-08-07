import 'package:flutter/material.dart';
import 'core/dev_panel_controller.dart';
import 'core/module_registry.dart';
import 'models/dev_module.dart';
import 'models/dev_panel_config.dart';
import 'ui/dev_panel.dart';

/// Flutter开发面板核心类
class FlutterDevPanelCore {
  static final FlutterDevPanelCore _instance = FlutterDevPanelCore._();
  static FlutterDevPanelCore get instance => _instance;
  
  FlutterDevPanelCore._();

  DevPanelController get controller => DevPanelController.instance;
  ModuleRegistry get moduleRegistry => ModuleRegistry.instance;

  /// 初始化开发面板
  void initialize({
    DevPanelConfig config = const DevPanelConfig(),
    List<DevModule> modules = const [],
  }) {
    controller.initialize(config: config);
    moduleRegistry.registerModules(modules);
  }

  /// 注册模块
  void registerModule(DevModule module) {
    moduleRegistry.registerModule(module);
  }

  /// 注册多个模块
  void registerModules(List<DevModule> modules) {
    moduleRegistry.registerModules(modules);
  }

  /// 打开面板
  void open(BuildContext context) {
    if (!controller.shouldShowInProduction()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const DevPanel(),
              ),
            );
          },
        );
      },
    );
  }

  /// 关闭面板
  void close() {
    controller.close();
  }

  /// 销毁
  void dispose() {
    controller.dispose();
  }

  /// 重置
  void reset() {
    DevPanelController.reset();
  }
}