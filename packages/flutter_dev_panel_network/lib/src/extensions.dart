import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'network_module.dart';
import 'network_api.dart';

/// Network 模块的扩展
/// 为 DevPanelAPI 添加 network 属性
extension NetworkExtension on DevPanelAPI {
  /// 获取 Network API
  /// 
  /// 使用示例:
  /// ```dart
  /// // 需要先获取 DevPanel 实例
  /// DevPanel.instance.network?.clearRequests();
  /// 
  /// // 或者通过 get() 方法（更简洁）
  /// DevPanel.get().network?.clearRequests();
  /// ```
  NetworkAPI? get network {
    if (!DevPanel.isInitialized) {
      if (kDebugMode) {
        debugPrint('DevPanel: Not initialized. Call DevPanel.initialize() first.');
      }
      return null;
    }
    
    final module = DevPanel.getModule<NetworkModule>();
    if (module == null) {
      if (kDebugMode) {
        debugPrint('Network module not installed. Add flutter_dev_panel_network to pubspec.yaml');
      }
      return null;
    }
    
    return module.api;
  }
}