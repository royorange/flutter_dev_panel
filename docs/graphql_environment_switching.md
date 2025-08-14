# GraphQL Endpoint 环境切换指南

当使用 Flutter Dev Panel 的环境管理功能时，如何动态切换 GraphQL endpoint？

## 核心思路

GraphQL 客户端的 `link` 是不可变的，所以切换 endpoint 需要重新创建客户端。

## 解决方案

### 方案 1：Service 模式（推荐）

创建一个 Service 来管理 GraphQL 客户端：

```dart
class GraphQLService extends ChangeNotifier {
  static final instance = GraphQLService._();
  GraphQLService._();
  
  GraphQLClient? _client;
  GraphQLClient get client => _client ?? _createClient();
  
  void initialize() {
    _client = _createClient();
    // 监听环境变更
    DevPanel.environment.addListener(_onEnvironmentChanged);
  }
  
  void _onEnvironmentChanged() {
    // 环境变更时重新创建客户端
    _client = _createClient();
    notifyListeners();
  }
  
  GraphQLClient _createClient() {
    // 从环境变量获取 endpoint
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    // 使用 NetworkModule 创建带监控的 Link
    final link = NetworkModule.createGraphQLLink(
      HttpLink(endpoint),
      endpoint: endpoint,
    );
    
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }
  
  @override
  void dispose() {
    DevPanel.environment.removeListener(_onEnvironmentChanged);
    super.dispose();
  }
}
```

使用：

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GraphQLService.instance,
      builder: (context, _) {
        return GraphQLProvider(
          client: ValueNotifier(GraphQLService.instance.client),
          child: MaterialApp(...),
        );
      },
    );
  }
}
```

### 方案 2：直接在 Widget 中处理

```dart
class MyApp extends StatelessWidget {
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
          child: MaterialApp(...),
        );
      },
    );
  }
}
```

### 方案 3：使用 Provider

```dart
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

// 使用
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => GraphQLClientProvider()),
  ],
  child: MyApp(),
);
```

## 环境配置示例

```dart
await DevPanel.environment.initialize(
  environments: [
    const EnvironmentConfig(
      name: 'Development',
      variables: {
        'graphql_endpoint': 'https://dev-api.example.com/graphql',
        'api_key': 'dev-key',
      },
      isDefault: true,
    ),
    const EnvironmentConfig(
      name: 'Staging',
      variables: {
        'graphql_endpoint': 'https://staging-api.example.com/graphql',
        'api_key': 'staging-key',
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
```

## Dio 对比

Dio 的处理更简单，因为可以直接修改 `BaseOptions`：

```dart
class ApiService {
  final dio = Dio();
  
  ApiService() {
    NetworkModule.attachToDio(dio); // 只需要一次
    _updateConfig();
    DevPanel.environment.addListener(_updateConfig);
  }
  
  void _updateConfig() {
    // 直接修改配置，不需要重新创建
    dio.options.baseUrl = DevPanel.environment.getString('api_url') ?? '';
    dio.options.headers['Authorization'] = 'Bearer ${DevPanel.environment.getString('api_key')}';
  }
}
```

## 关键点

1. **GraphQL 需要重新创建客户端**：因为 `link` 是不可变的
2. **Dio 可以直接修改配置**：因为 `options` 是可变的
3. **使用 ListenableBuilder**：自动响应环境变更
4. **记得清理监听器**：在 `dispose` 中移除监听器

## 最佳实践

- ✅ 使用 Service 模式管理 GraphQL 客户端
- ✅ 监听环境变更自动更新
- ✅ 使用 `NetworkModule.createGraphQLLink` 确保监控生效
- ✅ 在环境配置中定义所有 endpoint
- ❌ 避免硬编码 endpoint