import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// 完整的 GraphQL + 鉴权 + 监控 + 环境切换示例
class GraphQLWithAuthExample {
  
  /// 方案 1：监控所有请求（包括鉴权后的）
  static GraphQLClient createClientWithFullMonitoring() {
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    // 1. 创建基础 HttpLink
    final httpLink = HttpLink(endpoint);
    
    // 2. 创建鉴权 Link
    final authLink = AuthLink(
      getToken: () async {
        // 从存储或环境变量获取 token
        final token = DevPanel.environment.getString('auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );
    
    // 3. 组合 Links（鉴权在前，HTTP 在后）
    final combinedLink = Link.from([authLink, httpLink]);
    
    // 4. 添加监控（监控整个链路）
    final monitoredLink = NetworkModule.createGraphQLLink(
      combinedLink,
      endpoint: endpoint,
    );
    
    // 5. 创建客户端
    return GraphQLClient(
      link: monitoredLink,
      cache: GraphQLCache(),
    );
  }
  
  /// 方案 2：只监控 HTTP 请求（不包括鉴权过程）
  static GraphQLClient createClientWithHttpMonitoring() {
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    // 1. 创建基础 HttpLink 并添加监控
    final httpLink = HttpLink(endpoint);
    final monitoredHttpLink = NetworkModule.createGraphQLLink(
      httpLink,
      endpoint: endpoint,
    );
    
    // 2. 创建鉴权 Link
    final authLink = AuthLink(
      getToken: () async {
        final token = DevPanel.environment.getString('auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );
    
    // 3. 组合：鉴权在前，监控的 HTTP 在后
    final link = Link.from([authLink, monitoredHttpLink]);
    
    // 4. 创建客户端
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }
  
  /// 方案 3：使用多个 Links（错误处理 + 鉴权 + 监控）
  static GraphQLClient createClientWithMultipleLinks() {
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    // 1. 基础 HttpLink
    final httpLink = HttpLink(endpoint);
    
    // 2. 鉴权 Link
    final authLink = AuthLink(
      getToken: () async {
        final token = DevPanel.environment.getString('auth_token');
        return token != null ? 'Bearer $token' : null;
      },
    );
    
    // 3. 错误处理 Link
    final errorLink = ErrorLink(
      onGraphQLError: (request, forward, response) {
        // 处理 GraphQL 错误
        if (response.errors != null) {
          for (final error in response.errors!) {
            debugPrint('GraphQL Error: ${error.message}');
            
            // 如果是认证错误，可以触发重新登录
            if (error.message.contains('Unauthorized')) {
              // 触发重新登录逻辑
            }
          }
        }
        return null;
      },
      onException: (request, forward, exception) {
        // 处理网络异常
        debugPrint('Network Exception: $exception');
        return null;
      },
    );
    
    // 4. 组合所有 Links（顺序很重要！）
    final allLinks = Link.from([
      errorLink,      // 错误处理在最前
      authLink,       // 然后是鉴权
      httpLink,       // 最后是 HTTP 请求
    ]);
    
    // 5. 添加监控到整个链路
    final monitoredLink = NetworkModule.createGraphQLLink(
      allLinks,
      endpoint: endpoint,
    );
    
    // 6. 创建客户端
    return GraphQLClient(
      link: monitoredLink,
      cache: GraphQLCache(),
    );
  }
}

/// Link 执行顺序说明
class LinkOrderExplanation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GraphQL Link Chain')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link 执行顺序',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            _buildLinkFlow(
              'Link.from([authLink, httpLink])',
              [
                '1. 请求: authLink 添加 token',
                '2. 请求: httpLink 发送到服务器',
                '3. 响应: httpLink 接收响应',
                '4. 响应: authLink 处理响应',
              ],
            ),
            
            SizedBox(height: 24),
            
            _buildLinkFlow(
              'NetworkModule.createGraphQLLink(combinedLink)',
              [
                '1. 请求: GraphQLInterceptor 记录请求开始',
                '2. 请求: authLink 添加 token',
                '3. 请求: httpLink 发送到服务器',
                '4. 响应: httpLink 接收响应',
                '5. 响应: authLink 处理响应',
                '6. 响应: GraphQLInterceptor 记录响应结果',
              ],
            ),
            
            SizedBox(height: 24),
            
            Text(
              '最佳实践',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            _buildTip('监控位置', '将监控 Link 放在最外层，可以记录完整的请求/响应时间'),
            _buildTip('错误处理', 'ErrorLink 应该在 AuthLink 之前，以便捕获认证错误'),
            _buildTip('缓存', 'CacheLink 通常在最前面，避免不必要的网络请求'),
            _buildTip('顺序重要', 'Links 按顺序执行，顺序错误可能导致功能失效'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLinkFlow(String title, List<String> steps) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            ...steps.map((step) => Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(child: Text(step, style: TextStyle(fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTip(String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 实际使用示例
class MyGraphQLApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 使用带鉴权和监控的客户端
    final client = GraphQLWithAuthExample.createClientWithFullMonitoring();
    
    return GraphQLProvider(
      client: ValueNotifier(client),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('GraphQL with Auth')),
          body: Query(
            options: QueryOptions(
              document: gql(r'''
                query GetUserProfile {
                  me {
                    id
                    name
                    email
                  }
                }
              '''),
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (result.hasException) {
                return Center(
                  child: Text('Error: ${result.exception}'),
                );
              }
              
              final user = result.data?['me'];
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('User: ${user?['name'] ?? 'Unknown'}'),
                    Text('Email: ${user?['email'] ?? 'Unknown'}'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}