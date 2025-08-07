import 'package:dio/dio.dart';
import 'models/network_request.dart';
import 'network_monitor_controller.dart';

class NetworkInterceptor extends Interceptor {
  final NetworkMonitorController controller;

  NetworkInterceptor(this.controller);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    
    final request = NetworkRequest(
      id: requestId,
      url: options.uri.toString(),
      method: _parseMethod(options.method),
      headers: options.headers.map((k, v) => MapEntry(k, v.toString())),
      requestBody: options.data,
      startTime: DateTime.now(),
      status: RequestStatus.pending,
      requestSize: _calculateSize(options.data),
    );

    options.extra['requestId'] = requestId;
    controller.addRequest(request);
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestId = response.requestOptions.extra['requestId'] as String?;
    
    if (requestId != null) {
      controller.updateRequest(
        requestId,
        responseBody: response.data,
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        endTime: DateTime.now(),
        status: RequestStatus.success,
        responseHeaders: response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
        responseSize: _calculateSize(response.data),
      );
    }
    
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.extra['requestId'] as String?;
    
    if (requestId != null) {
      controller.updateRequest(
        requestId,
        responseBody: err.response?.data,
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage ?? err.message,
        endTime: DateTime.now(),
        status: RequestStatus.error,
        error: err.toString(),
        responseHeaders: err.response?.headers.map.map((k, v) => MapEntry(k, v.join(', '))) ?? {},
        responseSize: _calculateSize(err.response?.data),
      );
    }
    
    super.onError(err, handler);
  }

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

  int? _calculateSize(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.length;
    if (data is List) return data.toString().length;
    if (data is Map) return data.toString().length;
    return data.toString().length;
  }
}