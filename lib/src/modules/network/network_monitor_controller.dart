import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../models/network_request.dart';

class NetworkMonitorController extends ChangeNotifier {
  static NetworkMonitorController? _instance;
  
  static NetworkMonitorController get instance {
    _instance ??= NetworkMonitorController._();
    return _instance!;
  }
  
  NetworkMonitorController._();
  
  final List<NetworkRequest> _requests = [];
  final int _maxRequests = 100;
  String _searchQuery = '';
  NetworkRequestStatus? _selectedStatusFilter;
  
  List<NetworkRequest> get requests => _filteredRequests;
  String get searchQuery => _searchQuery;
  NetworkRequestStatus? get selectedStatusFilter => _selectedStatusFilter;
  
  List<NetworkRequest> get _filteredRequests {
    var filtered = _requests.toList();
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) => r.matchesSearch(_searchQuery)).toList();
    }
    
    // Apply status filter
    if (_selectedStatusFilter != null) {
      filtered = filtered.where((r) => r.status == _selectedStatusFilter).toList();
    }
    
    return filtered.reversed.toList(); // Show newest first
  }
  
  void addRequest(NetworkRequest request) {
    _requests.add(request);
    
    // Limit stored requests
    if (_requests.length > _maxRequests) {
      _requests.removeAt(0);
    }
    
    notifyListeners();
  }
  
  void updateRequestWithResponse(String requestId, Response response) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].updateFromResponse(response);
      notifyListeners();
    }
  }
  
  void updateRequestWithError(String requestId, DioException error) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].updateFromError(error);
      notifyListeners();
    }
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setStatusFilter(NetworkRequestStatus? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }
  
  void clearRequests() {
    _requests.clear();
    notifyListeners();
  }
  
  void removeRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }
  
  NetworkRequest? getRequest(String requestId) {
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (_) {
      return null;
    }
  }
  
  Map<String, int> getStatistics() {
    final stats = <String, int>{
      'total': _requests.length,
      'success': 0,
      'error': 0,
      'pending': 0,
      'cancelled': 0,
    };
    
    for (final request in _requests) {
      switch (request.status) {
        case NetworkRequestStatus.success:
          stats['success'] = (stats['success'] ?? 0) + 1;
          break;
        case NetworkRequestStatus.error:
          stats['error'] = (stats['error'] ?? 0) + 1;
          break;
        case NetworkRequestStatus.pending:
          stats['pending'] = (stats['pending'] ?? 0) + 1;
          break;
        case NetworkRequestStatus.cancelled:
          stats['cancelled'] = (stats['cancelled'] ?? 0) + 1;
          break;
      }
    }
    
    return stats;
  }
  
  static void reset() {
    _instance = null;
  }
}