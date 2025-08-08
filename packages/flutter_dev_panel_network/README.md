# Flutter Dev Panel - Network Module

网络监控模块，支持 Dio、HTTP、GraphQL 等多种网络库，提供统一的请求监控和调试功能。

## ✨ 核心特性

- 🔌 **多库支持** - Dio、http包、graphql_flutter 无缝集成
- 💾 **持久化存储** - 请求历史自动保存，应用重启后可查看
- 📊 **实时监控** - FAB 悬浮窗实时显示网络活动
- 🔍 **强大搜索** - 支持 URL、状态码、方法等多维度过滤
- 📱 **会话隔离** - 区分历史数据和当前会话，FAB 只显示活动请求
- 🎨 **优雅UI** - Material Design 3，支持暗黑模式

## 📦 安装

```yaml
dependencies:
  flutter_dev_panel_network:
    path: packages/flutter_dev_panel_network
```

## 🚀 快速开始

### 注册模块

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // 注册网络监控模块
  FlutterDevPanel.registerModule(NetworkModule());
  
  runApp(MyApp());
}
```

## 📡 HTTP 库集成

### Dio 集成（最流行）

```dart
import 'package:dio/dio.dart';

// 最简单 - 一行代码
final dio = Dio();
NetworkModule.attachToDio(dio);

// 多实例
NetworkModule.attachToMultipleDio([dio1, dio2, dio3]);

// 手动添加拦截器
dio.interceptors.add(NetworkModule.createInterceptor());
```

### GraphQL 集成（graphql_flutter）

```dart
import 'package:graphql_flutter/graphql_flutter.dart';

// 方式1：最简单 - 附加到现有客户端（推荐）
final originalClient = GraphQLClient(
  link: HttpLink('https://api.example.com/graphql'),
  cache: GraphQLCache(),
);

// 一行代码添加监控
final monitoredClient = NetworkModule.attachToGraphQL(originalClient);

// 方式2：创建新客户端
final client = NetworkModule.createGraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  subscriptionEndpoint: 'wss://api.example.com/graphql', // 可选
  defaultHeaders: {'Authorization': 'Bearer $token'},
);

// 方式3：Link 层集成
final monitoringLink = NetworkModule.createGraphQLInterceptor();
final link = Link.from([
  monitoringLink,  // 监控放最前
  authLink,
  httpLink,
]);
```

### HTTP 包集成

```dart
import 'package:http/http.dart' as http;

// 创建监控客户端
final client = NetworkModule.createHttpClient();

// 包装现有客户端
final wrapped = NetworkModule.wrapHttpClient(existingClient);

// 使用
final response = await client.get(Uri.parse('https://api.example.com'));
```

### 自定义 HTTP 库

```dart
// 获取基础拦截器
final interceptor = NetworkModule.getBaseInterceptor();

// 请求前
final requestId = interceptor.recordRequest(
  url: 'https://api.example.com/data',
  method: 'GET',
  headers: headers,
  body: requestBody,
);

// 响应后
interceptor.recordResponse(
  requestId: requestId,
  statusCode: 200,
  body: responseData,
  responseSize: bytes.length,
);

// 或记录错误
interceptor.recordError(
  requestId: requestId,
  error: 'Timeout',
);
```

## 📊 FAB 实时显示

悬浮按钮会实时显示网络活动：

- 🔄 **进行中** - 旋转动画 + 数量（`↻3`）
- ✅ **成功** - 绿色计数
- ❌ **错误** - 红色高亮（`/2`）
- ⚡ **性能** - 最慢请求时间（>1s 显示）
- 📥 **流量** - 下载数据量（`↓2.3M`）

### 显示规则

- 只显示当前会话的请求（应用重启后历史不触发 FAB）
- 数字过大自动格式化（1000→1k）
- 自动防溢出（Flexible + ellipsis）

## 🔧 配置选项

### 设置最大请求数

```dart
// 默认保存 100 条
NetworkModule.controller.setMaxRequests(200);
```

### 暂停/恢复监控

```dart
// 暂停
NetworkModule.controller.setPaused(true);

// 恢复
NetworkModule.controller.setPaused(false);

// 切换
NetworkModule.controller.togglePause();
```

### 清除历史

```dart
NetworkModule.controller.clearRequests();
```

## 🎯 GraphQL 特定功能

### 操作类型识别

自动识别并标记：
- QUERY
- MUTATION
- SUBSCRIPTION

### 请求详情

- Operation 名称
- GraphQL 查询语句
- Variables 变量
- GraphQL 错误（即使 HTTP 200 也会标记）

### WebSocket 订阅

```dart
final client = NetworkModule.createGraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  subscriptionEndpoint: 'wss://api.example.com/graphql',
);

// 订阅会被正确监控
subscription.listen((result) {
  // 实时数据
});
```

## 💾 数据持久化

- 自动保存请求历史到 SharedPreferences
- 应用重启后自动加载
- 保存数量与 maxRequests 设置一致
- 超出限制自动删除最早记录

### 会话隔离

- **历史数据** - 显示在列表中，可查看详情
- **会话数据** - 触发 FAB 显示和统计
- 重启应用后会话统计归零，FAB 不显示历史

## 📱 完整示例

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // 注册网络模块
  FlutterDevPanel.registerModule(NetworkModule());
  
  // Dio 集成
  final dio = Dio();
  NetworkModule.attachToDio(dio);
  
  // GraphQL 集成
  final graphQLClient = NetworkModule.createGraphQLClient(
    endpoint: 'https://countries.trevorblades.com/',
  );
  
  runApp(MyApp(
    dio: dio,
    graphQLClient: graphQLClient,
  ));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  final GraphQLClient graphQLClient;
  
  MyApp({required this.dio, required this.graphQLClient});
  
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(graphQLClient),
      child: FlutterDevPanel.wrap(
        child: MaterialApp(
          home: NetworkDemoPage(dio: dio),
        ),
      ),
    );
  }
}

class NetworkDemoPage extends StatelessWidget {
  final Dio dio;
  
  NetworkDemoPage({required this.dio});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Demo')),
      body: Column(
        children: [
          // REST API 请求
          ElevatedButton(
            onPressed: () async {
              await dio.get('https://jsonplaceholder.typicode.com/posts/1');
            },
            child: Text('REST Request'),
          ),
          
          // GraphQL 查询
          Query(
            options: QueryOptions(
              document: gql(r'''
                query GetCountries {
                  countries {
                    name
                    emoji
                  }
                }
              '''),
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) return CircularProgressIndicator();
              
              final countries = result.data?['countries'] ?? [];
              return Text('Loaded ${countries.length} countries');
            },
          ),
        ],
      ),
    );
  }
}
```

## ⚠️ 注意事项

1. **生产环境** - 建议在生产环境禁用，避免敏感数据泄露
2. **性能影响** - 大量请求时可能影响性能，可调整 maxRequests
3. **隐私数据** - 注意请求头中的 token 等敏感信息会被记录
4. **GraphQL 大查询** - 大型查询结果可能占用较多内存

## 🛠 故障排除

### FAB 不显示
- 检查是否有活动请求（历史请求不触发）
- 确认模块已正确注册
- 查看 `hasSessionActivity` 状态

### 请求未记录
- 确认拦截器已正确添加
- 检查是否暂停了监控
- GraphQL 需要使用包装后的客户端

### 历史丢失
- 检查 SharedPreferences 权限
- 确认未调用 clearRequests()
- 查看控制台是否有存储错误

## 📄 许可证

MIT License - 详见 LICENSE 文件