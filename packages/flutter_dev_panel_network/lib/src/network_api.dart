import 'network_monitor_controller.dart';
import 'models/network_request.dart';
import 'models/network_filter.dart';
import 'network_interceptor.dart';

/// Network 模块的公共 API
/// 通过 DevPanel.network 访问
class NetworkAPI {
  static NetworkAPI? _instance;
  static NetworkAPI get instance {
    _instance ??= NetworkAPI._();
    return _instance!;
  }
  
  NetworkAPI._();
  
  /// 控制器实例
  final NetworkMonitorController controller = NetworkMonitorController();
  
  // ========== 监控控制 ==========
  
  /// 暂停/恢复监控
  bool get isPaused => controller.isPaused;
  set isPaused(bool value) => controller.setPaused(value);
  void togglePause() => controller.togglePause();
  
  /// 清除所有请求
  void clearRequests() => controller.clearRequests();
  
  /// 清除单个请求
  void removeRequest(String id) => controller.removeRequest(id);
  
  // ========== 请求数据 ==========
  
  /// 获取所有请求（已过滤）
  List<NetworkRequest> get requests => controller.requests;
  
  /// 获取所有请求（未过滤）
  List<NetworkRequest> get allRequests => controller.allRequests;
  
  /// 获取请求统计
  int get totalRequests => controller.totalRequests;
  int get successCount => controller.successCount;
  int get errorCount => controller.errorCount;
  int get pendingCount => controller.pendingCount;
  
  /// 获取当前会话统计
  int get sessionRequestCount => controller.sessionRequestCount;
  int get sessionSuccessCount => controller.sessionSuccessCount;
  int get sessionErrorCount => controller.sessionErrorCount;
  
  // ========== 过滤器 ==========
  
  /// 获取当前过滤器
  NetworkFilter get filter => controller.filter;
  
  /// 设置过滤器
  void setFilter(NetworkFilter filter) {
    controller.setFilter(filter);
  }
  
  /// 更新搜索关键词
  void updateSearchQuery(String query) {
    controller.updateSearchQuery(query);
  }
  
  /// 设置方法过滤
  void setMethodFilter(RequestMethod? method) {
    controller.setMethodFilter(method);
  }
  
  /// 设置状态过滤
  void setStatusFilter(RequestStatus? status) {
    controller.setStatusFilter(status);
  }
  
  /// 清除所有过滤器
  void clearFilters() {
    controller.clearFilters();
  }
  
  // ========== 配置 ==========
  
  /// 最大请求数
  int get maxRequests => controller.maxRequests;
  set maxRequests(int value) => controller.setMaxRequests(value);
  
  // ========== 拦截器创建 ==========
  
  /// 创建 Dio 拦截器
  /// 
  /// 示例:
  /// ```dart
  /// final dio = Dio();
  /// dio.interceptors.add(DevPanel.network.createDioInterceptor());
  /// ```
  NetworkInterceptor createDioInterceptor() {
    return NetworkInterceptor(controller);
  }
  
  // ========== 便捷方法 ==========
  
  /// 获取最近的错误请求
  List<NetworkRequest> getRecentErrors({int limit = 10}) {
    return allRequests
        .where((r) => r.status == RequestStatus.error)
        .take(limit)
        .toList();
  }
  
  /// 获取慢请求（超过指定时间）
  List<NetworkRequest> getSlowRequests({int thresholdMs = 1000}) {
    return allRequests
        .where((r) => r.duration != null && r.duration!.inMilliseconds > thresholdMs)
        .toList();
  }
  
  /// 获取请求摘要
  String get summary {
    return 'Total: $totalRequests, Success: $successCount, Error: $errorCount';
  }
  
  /// 获取按域名分组的统计
  Map<String, int> getRequestsByDomain() {
    final domainCounts = <String, int>{};
    for (final request in allRequests) {
      final uri = Uri.tryParse(request.url);
      if (uri != null) {
        final domain = uri.host;
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      }
    }
    return domainCounts;
  }
  
  /// 检查是否有错误
  bool get hasErrors => errorCount > 0;
  
  /// 检查是否有待处理请求
  bool get hasPendingRequests => pendingCount > 0;
}