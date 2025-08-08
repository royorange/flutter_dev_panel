import 'dart:convert';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/network_request.dart';
import '../network_monitor_controller.dart';
import 'base_interceptor.dart';

/// GraphQL请求拦截器，专门为graphql_flutter优化
class GraphQLInterceptor extends Link {
  final NetworkMonitorController controller;
  final BaseNetworkInterceptor _interceptor;
  
  GraphQLInterceptor({NetworkMonitorController? controller}) 
    : controller = controller ?? NetworkMonitorController(),
      _interceptor = _GraphQLInterceptorImpl(controller ?? NetworkMonitorController());

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    if (forward == null) {
      throw Exception('GraphQLInterceptor: forward link is required');
    }

    // 解析GraphQL请求信息
    final operation = request.operation;
    final variables = request.variables;
    final context = request.context;
    
    // 构建请求URL（从context中获取endpoint）
    String endpoint = 'GraphQL';
    try {
      // 尝试从context获取URI
      final httpLink = context.entry<HttpLinkHeaders>();
      if (httpLink != null) {
        endpoint = 'GraphQL Request'; // HttpLinkHeaders不直接包含URI
      }
    } catch (_) {
      // 忽略错误，使用默认值
    }
    
    // 获取请求体
    final requestBody = {
      'operationName': operation.operationName,
      'query': operation.document.span?.text ?? operation.document.toString(),
      'variables': variables,
    };
    
    // 计算请求大小
    final requestSize = utf8.encode(json.encode(requestBody)).length;
    
    // 记录请求开始
    final requestId = _interceptor.recordRequest(
      url: endpoint,
      method: _getOperationType(operation),
      headers: _extractHeaders(context),
      body: requestBody,
      requestSize: requestSize,
    );
    
    
    try {
      // 执行请求
      await for (final response in forward(request)) {
        
        // 计算响应大小
        final responseBody = response.data ?? response.errors;
        final responseSize = utf8.encode(json.encode(responseBody)).length;
        
        // 判断是否有错误
        final hasErrors = response.errors != null && response.errors!.isNotEmpty;
        
        // 记录响应
        _interceptor.recordResponse(
          requestId: requestId,
          statusCode: hasErrors ? 400 : 200, // GraphQL错误通常返回200，这里用400标识
          statusMessage: hasErrors ? 'GraphQL Error' : 'OK',
          headers: _extractResponseHeaders(response),
          body: {
            'data': response.data,
            'errors': response.errors?.map((e) => {
              'message': e.message,
              'path': e.path,
              'extensions': e.extensions,
            }).toList(),
          },
          responseSize: responseSize,
        );
        
        yield response;
      }
    } catch (error) {
      // 记录错误
      _interceptor.recordError(
        requestId: requestId,
        error: error.toString(),
      );
      rethrow;
    }
  }
  
  /// 获取操作类型
  String _getOperationType(Operation operation) {
    final type = operation.document.definitions.first;
    if (type is OperationDefinitionNode) {
      switch (type.type) {
        case OperationType.query:
          return 'QUERY';
        case OperationType.mutation:
          return 'MUTATION';
        case OperationType.subscription:
          return 'SUBSCRIPTION';
      }
    }
    return 'QUERY';
  }
  
  /// 提取请求头
  Map<String, dynamic> _extractHeaders(Context context) {
    final headers = <String, dynamic>{};
    
    // 尝试从HttpLinkHeaders提取
    final httpHeaders = context.entry<HttpLinkHeaders>();
    if (httpHeaders != null && httpHeaders.headers != null) {
      headers.addAll(httpHeaders.headers!);
    }
    
    return headers;
  }
  
  /// 提取响应头
  Map<String, dynamic> _extractResponseHeaders(Response response) {
    final headers = <String, dynamic>{};
    
    // 从context中提取响应信息
    final context = response.context;
    if (context != null) {
      final httpResponse = context.entry<HttpLinkResponseContext>();
      if (httpResponse != null && httpResponse.headers != null) {
        headers.addAll(httpResponse.headers!);
      }
    }
    
    return headers;
  }
}

/// GraphQL拦截器实现
class _GraphQLInterceptorImpl extends BaseNetworkInterceptor {
  _GraphQLInterceptorImpl(NetworkMonitorController controller) : super(controller);
}

/// 便捷的GraphQL客户端创建方法
class MonitoredGraphQLClient {
  /// 创建带监控的GraphQL客户端
  static GraphQLClient create({
    required String endpoint,
    NetworkMonitorController? controller,
    String? subscriptionEndpoint,
    Map<String, String>? defaultHeaders,
    Cache? cache,
  }) {
    final httpLink = HttpLink(
      endpoint,
      defaultHeaders: defaultHeaders,
    );
    
    // 添加监控拦截器
    final interceptorLink = GraphQLInterceptor(controller: controller);
    
    Link link = Link.from([interceptorLink, httpLink]);
    
    // 如果有WebSocket订阅
    if (subscriptionEndpoint != null) {
      final wsLink = WebSocketLink(
        subscriptionEndpoint,
        config: SocketClientConfig(
          autoReconnect: true,
        ),
      );
      
      // 根据操作类型选择链接
      link = Link.split(
        (request) => request.isSubscription,
        wsLink,
        link,
      );
    }
    
    return GraphQLClient(
      link: link,
      cache: cache ?? GraphQLCache(),
    );
  }
  
  /// 包装现有的Link
  static Link wrapLink(Link existingLink, {NetworkMonitorController? controller}) {
    final interceptor = GraphQLInterceptor(controller: controller);
    return Link.from([interceptor, existingLink]);
  }
  
  /// 为现有客户端添加监控
  static GraphQLClient wrapClient(
    GraphQLClient client, {
    NetworkMonitorController? controller,
  }) {
    final interceptor = GraphQLInterceptor(controller: controller);
    final wrappedLink = Link.from([interceptor, client.link]);
    
    return GraphQLClient(
      link: wrappedLink,
      cache: client.cache,
      defaultPolicies: client.defaultPolicies,
      queryRequestTimeout: client.queryRequestTimeout,
    );
  }
}

