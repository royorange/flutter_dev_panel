import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../models/network_request.dart';
import 'network_monitor_controller.dart';

class DevPanelNetworkInterceptor extends Interceptor {
  static DevPanelNetworkInterceptor? _instance;
  
  factory DevPanelNetworkInterceptor() {
    _instance ??= DevPanelNetworkInterceptor._();
    return _instance!;
  }
  
  DevPanelNetworkInterceptor._();
  
  NetworkMonitorController? get _controller {
    try {
      return Get.find<NetworkMonitorController>();
    } catch (_) {
      return null;
    }
  }
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final request = NetworkRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      uri: options.uri,
      method: options.method,
      requestHeaders: options.headers.cast<String, dynamic>(),
      requestBody: options.data,
      startTime: DateTime.now(),
    );
    
    // Store request ID in extra for later reference
    options.extra['dev_panel_request_id'] = request.id;
    
    _controller?.addRequest(request);
    
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestId = response.requestOptions.extra['dev_panel_request_id'] as String?;
    
    if (requestId != null) {
      _controller?.updateRequestWithResponse(requestId, response);
    }
    
    super.onResponse(response, handler);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = err.requestOptions.extra['dev_panel_request_id'] as String?;
    
    if (requestId != null) {
      _controller?.updateRequestWithError(requestId, err);
    }
    
    super.onError(err, handler);
  }
}