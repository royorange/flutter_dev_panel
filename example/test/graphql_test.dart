import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() {
  test('GraphQL 监控集成测试', () {
    // 初始化Dio
    final dio = Dio();
    NetworkModule.attachToDio(dio);
    
    // 初始化GraphQL客户端
    final graphQLClient = GraphQLClient(
      link: HttpLink('https://countries.trevorblades.com/'),
      cache: GraphQLCache(),
    );
    
    // 添加GraphQL监控
    final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);
    
    // 验证客户端不为空
    expect(monitoredClient, isNotNull);
    expect(monitoredClient.link, isNotNull);
    expect(monitoredClient.cache, isNotNull);
    
    // 验证控制器已初始化
    expect(NetworkModule.controller, isNotNull);
  });
  
  testWidgets('GraphQL 请求界面测试', (WidgetTester tester) async {
    // 初始化GraphQL客户端
    final graphQLClient = GraphQLClient(
      link: HttpLink('https://countries.trevorblades.com/'),
      cache: GraphQLCache(),
    );
    
    // 添加监控
    final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);
    
    // 创建测试应用
    await tester.pumpWidget(
      GraphQLProvider(
        client: ValueNotifier(monitoredClient),
        child: MaterialApp(
          home: Scaffold(
            body: Query(
              options: QueryOptions(
                document: gql(r'''
                  query GetCountries {
                    countries(first: 5) {
                      code
                      name
                    }
                  }
                '''),
                fetchPolicy: FetchPolicy.networkOnly,
              ),
              builder: (QueryResult result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (result.hasException) {
                  return Center(child: Text('Error: ${result.exception}'));
                }
                
                final countries = result.data?['countries'] as List? ?? [];
                return Center(
                  child: Text('Loaded ${countries.length} countries'),
                );
              },
            ),
          ),
        ),
      ),
    );
    
    // 等待加载
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // 等待请求完成（模拟）
    await tester.pump(const Duration(seconds: 3));
  });
}