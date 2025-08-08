import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  group('GraphQL Integration Tests', () {
    test('attachToGraphQL should wrap client correctly', () {
      // 创建原始客户端
      final originalClient = GraphQLClient(
        link: HttpLink('https://api.example.com/graphql'),
        cache: GraphQLCache(),
      );
      
      // 添加监控
      final monitoredClient = NetworkModule.attachToGraphQL(
        originalClient,
        endpoint: 'https://api.example.com/graphql',
      );
      
      // 验证客户端已被包装
      expect(monitoredClient, isNotNull);
      expect(monitoredClient.link, isNotNull);
      expect(monitoredClient.cache, same(originalClient.cache));
    });
    
    test('NetworkModule controller should be initialized', () {
      expect(NetworkModule.controller, isNotNull);
    });
    
    test('GraphQL interceptor should handle dynamic endpoints', () {
      // 不传入endpoint，让拦截器自动检测
      final client = GraphQLClient(
        link: HttpLink('https://countries.trevorblades.com/'),
        cache: GraphQLCache(),
      );
      
      final monitoredClient = NetworkModule.attachToGraphQL(client);
      
      expect(monitoredClient, isNotNull);
      // 拦截器应该能自动检测endpoint
    });
  });
}