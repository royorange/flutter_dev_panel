import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

/// 演示如何根据环境变量动态切换 GraphQL endpoint
class GraphQLService extends ChangeNotifier {
  static final GraphQLService instance = GraphQLService._();
  GraphQLService._();
  
  GraphQLClient? _client;
  GraphQLClient get client => _client ?? _createClient();
  
  /// 初始化并监听环境变更
  void initialize() {
    _client = _createClient();
    
    // 监听环境变更
    DevPanel.environment.addListener(_onEnvironmentChanged);
  }
  
  /// 环境变更时重新创建客户端
  void _onEnvironmentChanged() {
    _client = _createClient();
    notifyListeners(); // 通知 UI 更新
  }
  
  /// 根据当前环境创建 GraphQL 客户端
  GraphQLClient _createClient() {
    // 从环境变量获取 endpoint
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    // 创建带监控的 Link
    final link = NetworkModule.createGraphQLLink(
      HttpLink(endpoint),
      endpoint: endpoint,
    );
    
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }
  
  void dispose() {
    DevPanel.environment.removeListener(_onEnvironmentChanged);
    super.dispose();
  }
}

/// 使用示例 - 方式1：使用 Service 模式
class GraphQLWithEnvironmentExample extends StatefulWidget {
  @override
  _GraphQLWithEnvironmentExampleState createState() => _GraphQLWithEnvironmentExampleState();
}

class _GraphQLWithEnvironmentExampleState extends State<GraphQLWithEnvironmentExample> {
  @override
  void initState() {
    super.initState();
    GraphQLService.instance.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GraphQLService.instance,
      builder: (context, _) {
        return GraphQLProvider(
          client: ValueNotifier(GraphQLService.instance.client),
          child: Scaffold(
            appBar: AppBar(
              title: Text('GraphQL with Environment'),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => DevPanel.open(context),
                ),
              ],
            ),
            body: Column(
              children: [
                // 显示当前环境
                Container(
                  padding: EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: ListenableBuilder(
                    listenable: DevPanel.environment,
                    builder: (context, _) {
                      final env = DevPanel.environment.currentEnvironment?.name ?? 'None';
                      final endpoint = DevPanel.environment.getString('graphql_endpoint') ?? 'Not set';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Environment: $env', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('GraphQL Endpoint: $endpoint', style: TextStyle(fontSize: 12)),
                        ],
                      );
                    },
                  ),
                ),
                
                // GraphQL Query
                Expanded(
                  child: Query(
                    options: QueryOptions(
                      document: gql(r'''
                        query GetData {
                          data {
                            id
                            name
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error: ${result.exception}'),
                              ElevatedButton(
                                onPressed: refetch,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: result.data?['data']?.length ?? 0,
                        itemBuilder: (context, index) {
                          final item = result.data!['data'][index];
                          return ListTile(
                            title: Text(item['name']),
                            subtitle: Text('ID: ${item['id']}'),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // 切换环境按钮
                Padding(
                  padding: EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      final current = DevPanel.environment.currentEnvironment?.name;
                      final newEnv = current == 'Development' ? 'Production' : 'Development';
                      DevPanel.environment.switchEnvironment(newEnv);
                      // GraphQL 客户端会自动重新创建
                    },
                    child: Text('Switch Environment'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    GraphQLService.instance.dispose();
    super.dispose();
  }
}

/// 使用示例 - 方式2：直接在 Widget 中管理
class SimpleGraphQLWithEnvironment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DevPanel.environment,
      builder: (context, _) {
        // 每次环境变更时重新创建客户端
        final endpoint = DevPanel.environment.getString('graphql_endpoint') 
            ?? 'https://api.example.com/graphql';
        
        final link = NetworkModule.createGraphQLLink(
          HttpLink(endpoint),
          endpoint: endpoint,
        );
        
        final client = GraphQLClient(
          link: link,
          cache: GraphQLCache(),
        );
        
        return GraphQLProvider(
          client: ValueNotifier(client),
          child: Scaffold(
            appBar: AppBar(title: Text('GraphQL Example')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Endpoint: $endpoint'),
                  // GraphQL queries here...
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 使用示例 - 方式3：使用 Provider/Riverpod
class GraphQLClientProvider extends ChangeNotifier {
  late GraphQLClient _client;
  GraphQLClient get client => _client;
  
  GraphQLClientProvider() {
    _updateClient();
    DevPanel.environment.addListener(_updateClient);
  }
  
  void _updateClient() {
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    final link = NetworkModule.createGraphQLLink(
      HttpLink(endpoint),
      endpoint: endpoint,
    );
    
    _client = GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    DevPanel.environment.removeListener(_updateClient);
    super.dispose();
  }
}

/// 配置示例
void setupEnvironments() async {
  await DevPanel.environment.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'graphql_endpoint': 'https://dev-api.example.com/graphql',
          'api_key': 'dev-key-123',
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Staging',
        variables: {
          'graphql_endpoint': 'https://staging-api.example.com/graphql',
          'api_key': 'staging-key-456',
        },
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'graphql_endpoint': 'https://api.example.com/graphql',
          'api_key': '', // 通过 --dart-define 注入
        },
      ),
    ],
  );
}