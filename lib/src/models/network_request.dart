import 'package:dio/dio.dart';

enum NetworkRequestStatus {
  pending,
  success,
  error,
  cancelled,
}

class NetworkRequest {
  final String id;
  final Uri uri;
  final String method;
  final Map<String, dynamic>? requestHeaders;
  final dynamic requestBody;
  final DateTime startTime;
  DateTime? endTime;
  
  int? statusCode;
  String? statusMessage;
  Map<String, dynamic>? responseHeaders;
  dynamic responseBody;
  String? error;
  NetworkRequestStatus status;
  
  Duration get duration => endTime != null 
      ? endTime!.difference(startTime) 
      : DateTime.now().difference(startTime);
  
  int? get requestSize => _calculateSize(requestBody);
  int? get responseSize => _calculateSize(responseBody);
  
  NetworkRequest({
    required this.id,
    required this.uri,
    required this.method,
    this.requestHeaders,
    this.requestBody,
    required this.startTime,
    this.endTime,
    this.statusCode,
    this.statusMessage,
    this.responseHeaders,
    this.responseBody,
    this.error,
    this.status = NetworkRequestStatus.pending,
  });
  
  void updateFromResponse(Response response) {
    endTime = DateTime.now();
    statusCode = response.statusCode;
    statusMessage = response.statusMessage;
    responseHeaders = response.headers.map;
    responseBody = response.data;
    status = NetworkRequestStatus.success;
  }
  
  void updateFromError(DioException error) {
    endTime = DateTime.now();
    this.error = error.toString();
    statusCode = error.response?.statusCode;
    statusMessage = error.response?.statusMessage;
    responseHeaders = error.response?.headers.map;
    responseBody = error.response?.data;
    status = NetworkRequestStatus.error;
  }
  
  int? _calculateSize(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is String) {
        return data.length;
      } else if (data is List) {
        return data.toString().length;
      } else if (data is Map) {
        return data.toString().length;
      }
      return data.toString().length;
    } catch (_) {
      return null;
    }
  }
  
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return uri.toString().toLowerCase().contains(lowerQuery) ||
           method.toLowerCase().contains(lowerQuery) ||
           statusCode?.toString().contains(query) == true;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uri': uri.toString(),
      'method': method,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'responseHeaders': responseHeaders,
      'responseBody': responseBody,
      'error': error,
      'status': status.name,
    };
  }
}