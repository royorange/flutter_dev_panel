import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../models/network_request.dart';

class NetworkMonitorController extends GetxController {
  final _requests = <NetworkRequest>[].obs;
  final _maxRequests = 100;
  final _searchQuery = ''.obs;
  final _selectedStatusFilter = Rxn<NetworkRequestStatus>();
  
  List<NetworkRequest> get requests => _filteredRequests;
  String get searchQuery => _searchQuery.value;
  NetworkRequestStatus? get selectedStatusFilter => _selectedStatusFilter.value;
  
  List<NetworkRequest> get _filteredRequests {
    var filtered = _requests.toList();
    
    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      filtered = filtered.where((r) => r.matchesSearch(_searchQuery.value)).toList();
    }
    
    // Apply status filter
    if (_selectedStatusFilter.value != null) {
      filtered = filtered.where((r) => r.status == _selectedStatusFilter.value).toList();
    }
    
    return filtered.reversed.toList(); // Show newest first
  }
  
  void addRequest(NetworkRequest request) {
    _requests.add(request);
    
    // Limit stored requests
    if (_requests.length > _maxRequests) {
      _requests.removeAt(0);
    }
  }
  
  void updateRequestWithResponse(String requestId, Response response) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].updateFromResponse(response);
      _requests.refresh();
    }
  }
  
  void updateRequestWithError(String requestId, DioException error) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].updateFromError(error);
      _requests.refresh();
    }
  }
  
  void setSearchQuery(String query) {
    _searchQuery.value = query;
  }
  
  void setStatusFilter(NetworkRequestStatus? status) {
    _selectedStatusFilter.value = status;
  }
  
  void clearRequests() {
    _requests.clear();
  }
  
  void removeRequest(String requestId) {
    _requests.removeWhere((r) => r.id == requestId);
  }
  
  NetworkRequest? getRequest(String requestId) {
    return _requests.firstWhereOrNull((r) => r.id == requestId);
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
}