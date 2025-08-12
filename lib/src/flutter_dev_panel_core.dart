import 'package:flutter/material.dart';
import 'core/dev_panel_controller.dart';
import 'core/module_registry.dart';
import 'core/dev_logger.dart';
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
    bool enableLogCapture = true,
  }) {
    controller.initialize(config: config);
    moduleRegistry.registerModules(modules);
    
    // Initialize DevLogger to capture logs
    if (enableLogCapture) {
      DevLogger.instance; // Initialize singleton
      DevLogger.enablePrintInterception();
    }
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
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const DevPanel(),
            ),
          ),
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