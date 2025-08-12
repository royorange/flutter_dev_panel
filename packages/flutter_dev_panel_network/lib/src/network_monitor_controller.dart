import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/src/core/monitoring_data_provider.dart';
import 'models/network_request.dart';
import 'models/network_filter.dart';
import 'storage/network_storage.dart';

class NetworkMonitorController extends ChangeNotifier {
  final List<NetworkRequest> _requests = [];
  NetworkFilter _filter = const NetworkFilter();
  int _maxRequests;
  bool _isPaused = false;
  bool _isInitialized = false;
  
  // 当前会话的统计（不包括历史记录）
  int _sessionRequestCount = 0;
  int _sessionSuccessCount = 0;
  int _sessionErrorCount = 0;
  int _sessionPendingCount = 0;

  NetworkMonitorController({int maxRequests = 100}) : _maxRequests = maxRequests {
    _initialize();
  }
  
  /// 初始化，加载历史记录
  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // 加载保存的最大请求数
    _maxRequests = await NetworkStorage.loadMaxRequests();
    
    // 加载历史请求记录
    final savedRequests = await NetworkStorage.loadRequests();
    if (savedRequests.isNotEmpty) {
      // 过滤掉pending状态的请求（这些是异常中断的）
      final completedRequests = savedRequests
          .where((r) => r.status != RequestStatus.pending)
          .take(_maxRequests)
          .toList();
      
      if (completedRequests.isNotEmpty) {
        _requests.addAll(completedRequests);
        notifyListeners();
      }
    }
    
    // 初始化时不更新MonitoringDataProvider，因为这些都是历史数据
  }

  List<NetworkRequest> get requests => _filteredRequests;
  
  List<NetworkRequest> get _filteredRequests {
    return _requests.where((request) => _filter.matches(request)).toList();
  }

  List<NetworkRequest> get allRequests => List.unmodifiable(_requests);

  NetworkFilter get filter => _filter;

  bool get isPaused => _isPaused;

  int get maxRequests => _maxRequests;

  int get totalRequests => _requests.length;

  int get successCount => _requests.where((r) => r.isSuccess).length;

  int get errorCount => _requests.where((r) => r.isError).length;

  int get pendingCount => _requests.where((r) => r.status == RequestStatus.pending).length;
  
  // 当前会话的统计（用于FAB显示）
  int get sessionRequestCount => _sessionRequestCount;
  int get sessionSuccessCount => _sessionSuccessCount;
  int get sessionErrorCount => _sessionErrorCount;
  int get sessionPendingCount => _sessionPendingCount;
  bool get hasSessionActivity => _sessionRequestCount > 0 || _sessionPendingCount > 0;

  void addRequest(NetworkRequest request) {
    if (_isPaused) return;
    
    _requests.insert(0, request);
    
    if (_requests.length > _maxRequests) {
      _requests.removeLast();
    }
    
    // 更新会话统计
    _sessionRequestCount++;
    _sessionPendingCount++;
    
    // 保存到本地存储
    _saveRequests();
    
    // 更新全局监控数据
    MonitoringDataProvider.instance.onRequestStart();
    
    notifyListeners();
  }
  
  /// 保存请求到本地存储
  Future<void> _saveRequests() async {
    try {
      await NetworkStorage.saveRequests(_requests);
    } catch (e) {
      // 忽略存储错误
    }
  }

  void updateRequest(
    String id, {
    dynamic responseBody,
    int? statusCode,
    String? statusMessage,
    DateTime? endTime,
    RequestStatus? status,
    String? error,
    Map<String, dynamic>? responseHeaders,
    int? responseSize,
  }) {
    if (_isPaused) return;
    
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        responseBody: responseBody,
        statusCode: statusCode,
        statusMessage: statusMessage,
        endTime: endTime,
        status: status,
        error: error,
        responseHeaders: responseHeaders,
        responseSize: responseSize,
      );
      
      // 更新会话统计
      if (status == RequestStatus.success) {
        if (_sessionPendingCount > 0) _sessionPendingCount--;
        _sessionSuccessCount++;
      } else if (status == RequestStatus.error) {
        if (_sessionPendingCount > 0) _sessionPendingCount--;
        _sessionErrorCount++;
      }
      
      // 保存到本地存储
      _saveRequests();
      
      // 更新全局监控数据
      if (status == RequestStatus.success || status == RequestStatus.error) {
        MonitoringDataProvider.instance.onRequestComplete(status == RequestStatus.error || error != null);
      }
      
      // 更新统计 - 使用会话统计
      MonitoringDataProvider.instance.updateNetworkData(
        totalRequests: _sessionRequestCount,
        errorRequests: _sessionErrorCount,
        pendingRequests: _sessionPendingCount,
      );
      
      notifyListeners();
    }
  }

  void clearRequests() {
    _requests.clear();
    // 重置会话统计
    _sessionRequestCount = 0;
    _sessionSuccessCount = 0;
    _sessionErrorCount = 0;
    _sessionPendingCount = 0;
    NetworkStorage.clearRequests(); // 清除本地存储
    notifyListeners();
  }

  void removeRequest(String id) {
    _requests.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void setFilter(NetworkFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setMethodFilter(RequestMethod? method) {
    _filter = _filter.copyWith(method: method);
    notifyListeners();
  }

  void setStatusFilter(RequestStatus? status) {
    _filter = _filter.copyWith(status: status);
    notifyListeners();
  }

  void setShowOnlyErrors(bool showOnlyErrors) {
    _filter = _filter.copyWith(showOnlyErrors: showOnlyErrors);
    notifyListeners();
  }

  void clearFilters() {
    _filter = _filter.clearFilters();
    notifyListeners();
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void setMaxRequests(int max) {
    _maxRequests = max;
    while (_requests.length > _maxRequests) {
      _requests.removeLast();
    }
    NetworkStorage.saveMaxRequests(max); // 保存设置
    _saveRequests(); // 保存调整后的请求列表
    notifyListeners();
  }

  NetworkRequest? getRequestById(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _requests.clear();
    super.dispose();
  }
}