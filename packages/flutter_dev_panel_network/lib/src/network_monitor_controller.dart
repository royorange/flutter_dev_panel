import 'package:flutter/foundation.dart';
import 'models/network_request.dart';
import 'models/network_filter.dart';

class NetworkMonitorController extends ChangeNotifier {
  final List<NetworkRequest> _requests = [];
  NetworkFilter _filter = const NetworkFilter();
  int _maxRequests;
  bool _isPaused = false;

  NetworkMonitorController({int maxRequests = 100}) : _maxRequests = maxRequests;

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

  void addRequest(NetworkRequest request) {
    if (_isPaused) return;
    
    _requests.insert(0, request);
    
    if (_requests.length > _maxRequests) {
      _requests.removeLast();
    }
    
    notifyListeners();
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
      notifyListeners();
    }
  }

  void clearRequests() {
    _requests.clear();
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