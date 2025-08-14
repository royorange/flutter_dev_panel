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
    
    // 使用提供的 endpoint 或默认值
    // 注意：由于 GraphQL Flutter 的设计限制，无法可靠地自动获取实际的 endpoint
    // 建议在创建监控时显式传递 endpoint 参数
    String endpoint = _endpoint ?? 'GraphQL';
    
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
      method: 'POST',
      url: url,
      headers: _extractRequestHeaders(request),
      body: requestBody,
      requestSize: requestSize,
    );
    
    try {
      // 转发请求并监控响应
      await for (final response in forward(request)) {
        // 记录响应
        final responseData = response.data;
        final errors = response.errors;
        
        // 构建响应体
        Map<String, dynamic> responseBody = {};
        if (responseData != null) {
          responseBody['data'] = responseData;
        }
        if (errors != null && errors.isNotEmpty) {
          responseBody['errors'] = errors.map((e) => {
            'message': e.message,
            'path': e.path,
            'extensions': e.extensions,
          }).toList();
        }
        
        // 计算响应大小
        final responseSize = utf8.encode(json.encode(responseBody)).length;
        
        // 记录响应
        _interceptor.recordResponse(
          requestId: requestId,
          statusCode: errors?.isNotEmpty == true ? 400 : 200,
          statusMessage: errors?.isNotEmpty == true ? 'GraphQL Error' : 'OK',
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
  
  /// 获取操作类型
  String _getOperationType(Operation operation) {
    final type = operation.document.definitions.first;
    if (type is OperationDefinitionNode) {
      switch (type.type) {
        case OperationType.query:
          return 'query';
        case OperationType.mutation:
          return 'mutation';
        case OperationType.subscription:
          return 'subscription';
      }
    }
    return 'query';
  }
  
  /// 提取请求头
  Map<String, String> _extractRequestHeaders(Request request) {
    final headers = <String, String>{};
    // GraphQL请求通常通过POST发送，Content-Type为application/json
    headers['Content-Type'] = 'application/json';
    
    // 从context中提取自定义头
    final httpConfig = request.context.entry<HttpLinkHeaders>();
    if (httpConfig != null && httpConfig.headers != null) {
      headers.addAll(httpConfig.headers!);
    }
    
    return headers;
  }
  
  /// 提取响应头（GraphQL响应通常不包含有用的头信息）
  Map<String, String> _extractResponseHeaders(Response response) {
    final headers = <String, String>{};
    headers['Content-Type'] = 'application/json';
    
    // 从context中提取响应头（如果有）
    final httpResponse = response.context.entry<HttpLinkResponseContext>();
    if (httpResponse != null && httpResponse.headers != null) {
      headers.addAll(httpResponse.headers!);
    }
    
    return headers;
  }
}

/// GraphQL拦截器实现
class _GraphQLInterceptorImpl extends BaseNetworkInterceptor {
  _GraphQLInterceptorImpl(NetworkMonitorController controller) : super(controller);
  
  String getUrlPath(String url) {
    // 对于GraphQL，URL通常包含操作名称作为锚点
    final uri = Uri.tryParse(url);
    if (uri != null) {
      // 如果有锚点（操作名），包含在路径中
      if (uri.fragment.isNotEmpty) {
        return '${uri.path}#${uri.fragment}';
      }
      return uri.path;
    }
    return url;
  }
  
  String getHost(String url) {
    // 去掉锚点部分再解析
    final cleanUrl = url.split('#').first;
    final uri = Uri.tryParse(cleanUrl);
    return uri?.host ?? 'GraphQL';
  }
}

/// 创建预配置的GraphQL客户端
class MonitoredGraphQLClient {
  /// 创建带监控的GraphQL客户端
  static GraphQLClient create({
    required String endpoint,
    String? subscriptionEndpoint,
    Map<String, String>? defaultHeaders,
    GraphQLCache? cache,
  }) {
    HttpLink httpLink = HttpLink(
      endpoint,
      defaultHeaders: defaultHeaders ?? {},
    );
    
    Link link = httpLink;
    
    // 如果提供了WebSocket端点，添加WebSocket支持
    if (subscriptionEndpoint != null) {
      final wsLink = WebSocketLink(subscriptionEndpoint);
      link = Link.split((request) => request.isSubscription, wsLink, httpLink);
    }
    
    // 创建拦截器链
    final interceptor = GraphQLInterceptor(endpoint: endpoint);
    link = Link.from([interceptor, link]);
    
    return GraphQLClient(
      link: link,
      cache: cache ?? GraphQLCache(),
    );
  }
}