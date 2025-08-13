import 'dart:convert';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql/ast.dart' show OperationDefinitionNode, OperationType;
import 'package:gql/language.dart' show printNode;
import '../models/network_request.dart';
import '../network_monitor_controller.dart';
import 'base_interceptor.dart';

/// GraphQL请求拦截器，专门为graphql_flutter优化
class GraphQLInterceptor extends Link {
  final NetworkMonitorController controller;
  final BaseNetworkInterceptor _interceptor;
  String? _endpoint; // 存储endpoint
  static final Map<int, String> _linkEndpoints = {}; // 存储Link和endpoint的映射
  
  GraphQLInterceptor({NetworkMonitorController? controller, String? endpoint}) 
    : controller = controller ?? NetworkMonitorController(),
      _interceptor = _GraphQLInterceptorImpl(controller ?? NetworkMonitorController()),
      _endpoint = endpoint;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    if (forward == null) {
      throw Exception('GraphQLInterceptor: forward link is required');
    }

    // 解析GraphQL请求信息
    final operation = request.operation;
    final variables = request.variables;
    final context = request.context;
    
    // 尝试从context动态获取endpoint
    String endpoint = _endpoint ?? _extractEndpoint(context, forward) ?? 'GraphQL';
    
    // 构建请求URL（包含操作名称）
    String url = endpoint;
    if (operation.operationName != null && operation.operationName!.isNotEmpty) {
      url = '$endpoint#${operation.operationName}';
    } else {
      // 尝试从查询中提取操作名
      final operationType = _getOperationType(operation);
      url = '$endpoint#$operationType';
    }
    
    // 获取请求体
    // 使用 gql 包的 printNode 方法来正确序列化 DocumentNode
    String? queryString;
    String? operationName = operation.operationName;
    
    try {
      // 使用 printNode 来序列化 DocumentNode
      queryString = printNode(operation.document);
      
      // 如果 operationName 为空，尝试从 document 中提取
      if ((operationName == null || operationName.isEmpty) && 
          operation.document.definitions.isNotEmpty) {
        final firstDef = operation.document.definitions.first;
        if (firstDef is OperationDefinitionNode) {
          operationName = firstDef.name?.value;
        }
      }
    } catch (e) {
      // 如果 printNode 失败，尝试备用方法
      try {
        queryString = operation.document.span?.text;
      } catch (_) {
        queryString = 'GraphQL ${_getOperationType(operation)} (unable to serialize)';
      }
    }
    
    final requestBody = {
      'operationName': operationName,
      'query': queryString ?? 'Unknown Query',
      'variables': variables,
    };
    
    // 计算请求大小
    final requestSize = utf8.encode(json.encode(requestBody)).length;
    
    // 记录请求开始
    final requestId = _interceptor.recordRequest(
      url: url,
      method: _getOperationType(operation),
      headers: _extractHeaders(context),
      body: requestBody,
      requestSize: requestSize,
    );
    
    
    try {
      // 执行请求
      await for (final response in forward(request)) {
        
        // 安全地构建可序列化的响应体
        Map<String, dynamic> responseBody;
        try {
          // 尝试构建响应体
          final errors = response.errors?.map((e) {
            // 安全地提取错误信息
            try {
              return {
                'message': e.message,
                'path': e.path?.toString(),
                'extensions': e.extensions is Map ? Map<String, dynamic>.from(e.extensions as Map) : null,
              };
            } catch (_) {
              return {'message': e.toString()};
            }
          }).toList();
          
          responseBody = {
            'data': response.data,
            'errors': errors,
          };
        } catch (e) {
          // 如果构建失败，使用简化的响应
          responseBody = {
            'data': response.data,
            'error': 'Failed to parse GraphQL errors: ${e.toString()}',
          };
        }
        
        // 计算响应大小
        int responseSize = 0;
        try {
          responseSize = utf8.encode(json.encode(responseBody)).length;
        } catch (_) {
          // 如果序列化失败，使用估算值
          responseSize = responseBody.toString().length;
        }
        
        // 判断是否有错误
        final hasErrors = response.errors != null && response.errors!.isNotEmpty;
        
        // 记录响应（使用已经构建好的 responseBody）
        _interceptor.recordResponse(
          requestId: requestId,
          statusCode: hasErrors ? 400 : 200, // GraphQL错误通常返回200，这里用400标识
          statusMessage: hasErrors ? 'GraphQL Error' : 'OK',
          headers: _extractResponseHeaders(response),
          body: responseBody,
          responseSize: responseSize,
        );
        
        yield response;
      }
    } catch (error) {
      // 记录错误，处理可能的 LinkException
      String errorMessage = error.toString();
      
      // 特殊处理 LinkException，它可能包含不可序列化的内容
      if (error.runtimeType.toString().contains('Exception')) {
        try {
          errorMessage = error.toString();
        } catch (_) {
          errorMessage = 'GraphQL Link Error';
        }
      }
      
      _interceptor.recordError(
        requestId: requestId,
        error: errorMessage,
      );
      rethrow;
    }
  }
  
  /// 尝试从链路中提取endpoint
  String? _extractEndpoint(Context context, NextLink? forward) {
    try {
      // 检查是否已经缓存了这个Link的endpoint
      if (forward != null) {
        final cachedEndpoint = _linkEndpoints[forward.hashCode];
        if (cachedEndpoint != null) {
          return cachedEndpoint;
        }
      }
      
      // 尝试从forward链路获取
      if (forward is HttpLink) {
        // 不能直接访问 uri，需要其他方法
        // HttpLink 的 toString 可能包含 URI 信息
        final linkStr = forward.toString();
        final match = RegExp(r'https?://[^\s\)]+').firstMatch(linkStr);
        if (match != null) {
          final endpoint = match.group(0);
          if (forward != null && endpoint != null) {
            _linkEndpoints[forward.hashCode] = endpoint;
          }
          return endpoint;
        }
      }
      
    } catch (_) {
      // 忽略错误，返回null
    }
    return null;
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
    if (httpHeaders != null) {
      headers.addAll(httpHeaders.headers ?? {});
    }
    
    return headers;
  }
  
  /// 提取响应头
  Map<String, dynamic> _extractResponseHeaders(Response response) {
    final headers = <String, dynamic>{};
    
    // 从context中提取响应信息
    final context = response.context;
    final httpResponse = context.entry<HttpLinkResponseContext>();
    if (httpResponse != null) {
      headers.addAll(httpResponse.headers ?? {});
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
    GraphQLCache? cache,
  }) {
    final httpLink = HttpLink(
      endpoint,
      defaultHeaders: defaultHeaders ?? {},
    );
    
    // 添加监控拦截器，传入endpoint
    final interceptorLink = GraphQLInterceptor(
      controller: controller,
      endpoint: endpoint,
    );
    
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
    );
  }
}

