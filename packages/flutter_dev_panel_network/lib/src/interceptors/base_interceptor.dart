import '../models/network_request.dart';
import '../network_monitor_controller.dart';

/// 网络拦截器基类，可以被不同的HTTP库实现
abstract class BaseNetworkInterceptor {
  final NetworkMonitorController controller;
  
  BaseNetworkInterceptor(this.controller);
  
  /// 记录请求开始
  String recordRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    dynamic body,
    int? requestSize,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final request = NetworkRequest(
      id: id,
      url: url,
      method: _parseMethod(method),
      headers: headers ?? {},
      requestBody: body,
      startTime: DateTime.now(),
      status: RequestStatus.pending,
      requestSize: requestSize,
    );
    
    controller.addRequest(request);
    return id;
  }
  
  /// 记录响应成功
  void recordResponse({
    required String requestId,
    required int statusCode,
    String? statusMessage,
    Map<String, dynamic>? headers,
    dynamic body,
    int? responseSize,
  }) {
    controller.updateRequest(
      requestId,
      statusCode: statusCode,
      statusMessage: statusMessage,
      responseBody: body,
      responseHeaders: headers ?? {},
      responseSize: responseSize,
      endTime: DateTime.now(),
      status: statusCode >= 200 && statusCode < 300 
          ? RequestStatus.success 
          : RequestStatus.error,
    );
  }
  
  /// 记录请求错误
  void recordError({
    required String requestId,
    required String error,
    int? statusCode,
  }) {
    controller.updateRequest(
      requestId,
      error: error,
      statusCode: statusCode,
      endTime: DateTime.now(),
      status: RequestStatus.error,
    );
  }
  
  /// 解析请求方法
  RequestMethod _parseMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return RequestMethod.get;
      case 'POST':
        return RequestMethod.post;
      case 'PUT':
        return RequestMethod.put;
      case 'DELETE':
        return RequestMethod.delete;
      case 'PATCH':
        return RequestMethod.patch;
      case 'HEAD':
        return RequestMethod.head;
      case 'OPTIONS':
        return RequestMethod.options;
      default:
        return RequestMethod.get;
    }
  }
}