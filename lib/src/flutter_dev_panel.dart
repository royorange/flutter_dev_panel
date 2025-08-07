import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'core/dev_panel_controller.dart';
import 'core/environment_manager.dart';
import 'core/module_manager.dart';
import 'models/dev_panel_config.dart';
import 'models/module.dart';
import 'modules/network/network_interceptor.dart';
import 'modules/network/network_monitor_controller.dart';
import 'modules/network/network_module.dart';
import 'modules/environment/environment_module.dart';
import 'modules/device_info/device_info_module.dart';
import 'modules/performance/performance_module.dart';
import 'ui/widgets/floating_button.dart';
import 'ui/widgets/shake_detector.dart';
import 'dev_panel.dart';

/// Flutter Dev Panel - 开发调试面板
class FlutterDevPanel {
  static FlutterDevPanel? _instance;
  static bool _initialized = false;
  
  FlutterDevPanel._();
  
  static FlutterDevPanel get instance {
    _instance ??= FlutterDevPanel._();
    return _instance!;
  }
  
  /// 初始化开发面板
  static Future<void> init({
    DevPanelConfig? config,
    List<DevModule>? customModules,
    bool autoStart = true,
  }) async {
    if (_initialized) return;
    
    // 仅在调试模式下启用
    if (!kDebugMode && config?.showInProduction != true) {
      return;
    }
    
    // 初始化 GetX 控制器
    Get.lazyPut(() => DevPanelController());
    Get.lazyPut(() => EnvironmentManager());
    Get.lazyPut(() => ModuleManager());
    Get.lazyPut(() => NetworkMonitorController());
    Get.lazyPut(() => DevPanelEnvironmentChangeNotifier());
    
    // 获取控制器实例
    final controller = DevPanelController.to;
    
    // 创建默认配置
    final defaultModules = <DevModule>[
      NetworkModule(),
      EnvironmentModule(),
      DeviceInfoModule(),
      PerformanceModule(),
    ];
    
    // 添加自定义模块
    if (customModules != null) {
      defaultModules.addAll(customModules);
    }
    
    // 应用配置
    final finalConfig = config ?? DevPanelConfig(
      enabled: true,
      triggerModes: {TriggerMode.fab},
      modules: defaultModules,
      environments: [],
    );
    
    await controller.initialize(finalConfig);
    
    _initialized = true;
  }
  
  /// 为 Dio 实例添加网络监控拦截器
  static void addDioInterceptor(Dio dio) {
    if (!_initialized) {
      debugPrint('[FlutterDevPanel] 警告: 请先调用 FlutterDevPanel.init() 初始化面板');
      return;
    }
    
    if (!kDebugMode) return;
    
    dio.interceptors.add(DevPanelNetworkInterceptor());
  }
  
  /// 包装应用的根组件
  static Widget wrap({
    required Widget child,
    bool enableFloatingButton = true,
    bool enableShakeDetection = true,
  }) {
    if (!_initialized) {
      debugPrint('[FlutterDevPanel] 警告: 请先调用 FlutterDevPanel.init() 初始化面板');
      return child;
    }
    
    if (!kDebugMode) {
      return child;
    }
    
    return GetBuilder<DevPanelController>(
      init: DevPanelController.to,
      builder: (controller) {
        Widget result = child;
        
        // 检查触发模式
        final config = controller.config;
        
        // 添加摇一摇检测
        if (enableShakeDetection && config.triggerModes.contains(TriggerMode.shake)) {
          result = ShakeDetector(
            child: result,
            onShake: () => controller.show(),
          );
        }
        
        // 添加悬浮按钮
        if (enableFloatingButton && config.triggerModes.contains(TriggerMode.fab)) {
          result = DevPanelFloatingButton(
            child: result,
          );
        }
        
        // 添加面板覆盖层
        result = Stack(
          children: [
            result,
            Obx(() {
              if (!controller.isVisible) {
                return const SizedBox.shrink();
              }
              
              return GestureDetector(
                onTap: () => controller.hide(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // 阻止点击事件传递到背景
                      child: const DevPanel(),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
        
        return result;
      },
    );
  }
  
  /// 手动显示开发面板
  static void show() {
    if (!_initialized) {
      debugPrint('[FlutterDevPanel] 警告: 请先调用 FlutterDevPanel.init() 初始化面板');
      return;
    }
    
    DevPanelController.to.show();
  }
  
  /// 手动隐藏开发面板
  static void hide() {
    if (!_initialized) return;
    
    DevPanelController.to.hide();
  }
  
  /// 切换开发面板显示状态
  static void toggle() {
    if (!_initialized) {
      debugPrint('[FlutterDevPanel] 警告: 请先调用 FlutterDevPanel.init() 初始化面板');
      return;
    }
    
    DevPanelController.to.toggle();
  }
  
  /// 获取当前环境配置
  static T? getEnvironmentConfig<T>(String key) {
    if (!_initialized) return null;
    
    return DevPanelController.to.environmentManager.getConfig<T>(key);
  }
  
  /// 切换环境
  static void switchEnvironment(String name) {
    if (!_initialized) return;
    
    DevPanelController.to.switchEnvironment(name);
  }
  
  /// 注册自定义模块
  static void registerModule(DevModule module) {
    if (!_initialized) {
      debugPrint('[FlutterDevPanel] 警告: 请先调用 FlutterDevPanel.init() 初始化面板');
      return;
    }
    
    DevPanelController.to.moduleManager.registerModule(module);
  }
}