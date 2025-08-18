import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'network_module.dart';
import 'network_api.dart';
import 'models/network_request.dart';

/// Network 模块的便捷访问类
/// 
/// 使用示例:
/// ```dart
/// import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
/// 
/// // 使用便捷访问
/// DevPanelNetwork.clearRequests();
/// print(DevPanelNetwork.summary);
/// 
/// // 或者通过 api 属性
/// DevPanelNetwork.api?.getRecentErrors();
/// ```
class DevPanelNetwork {
  DevPanelNetwork._();
  
  /// 获取 Network 模块的 API
  static NetworkAPI? get api {
    // 检查 DevPanel 是否已初始化
    if (!DevPanel.isInitialized) {
      if (kDebugMode) {
        debugPrint('DevPanel: Not initialized. Please call DevPanel.initialize() first.');
      }
      return null;
    }
    
    // 检查模块是否已安装
    if (!DevPanel.hasModule('network')) {
      if (kDebugMode) {
        debugPrint('DevPanelNetwork: Network module not installed.\n'
            'To use network monitoring, add to pubspec.yaml:\n'
            '  flutter_dev_panel_network: ^latest_version\n'
            'And register the module:\n'
            '  DevPanel.initialize(modules: [NetworkModule()])');
      }
      return null;
    }
    
    // 获取模块
    final module = DevPanel.getModule<NetworkModule>();
    if (module == null) {
      if (kDebugMode) {
        debugPrint('DevPanelNetwork: Failed to get NetworkModule instance.');
      }
      return null;
    }
    
    // 返回 API
    return module.api;
  }
  
  // ========== 便捷方法 ==========
  
  static void clearRequests() => api?.clearRequests();
  static void togglePause() => api?.togglePause();
  
  static bool get isPaused => api?.isPaused ?? false;
  static set isPaused(bool value) {
    if (api != null) api!.isPaused = value;
  }
  
  static List<NetworkRequest> get requests => api?.requests ?? [];
  static int get totalRequests => api?.totalRequests ?? 0;
  static int get errorCount => api?.errorCount ?? 0;
  
  static String get summary => api?.summary ?? 'Network module not available';
  static bool get hasErrors => api?.hasErrors ?? false;
}