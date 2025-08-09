import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Dio
  final dio = Dio();
  NetworkModule.attachToDio(dio);
  
  // 初始化GraphQL客户端
  const graphQLEndpoint = 'https://countries.trevorblades.com/';
  final graphQLClient = GraphQLClient(
    link: HttpLink(graphQLEndpoint),
    cache: GraphQLCache(),
  );
  
  // 添加GraphQL监控（会自动检测endpoint，也可以手动传入）
  final monitoredGraphQLClient = NetworkModule.attachToGraphQL(
    graphQLClient,
    endpoint: graphQLEndpoint, // 可选：手动指定以确保显示正确
  );
  
  // 初始化开发面板
  FlutterDevPanel.initialize(
    config: const DevPanelConfig(
      enabled: true,
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
      showInProduction: false,
    ),
    modules: [
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),
    ],
  );
  
  runApp(MyApp(
    dio: dio,
    graphQLClient: monitoredGraphQLClient,
  ));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  final GraphQLClient graphQLClient;
  
  const MyApp({
    super.key,
    required this.dio,
    required this.graphQLClient,
  });

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(graphQLClient),
      child: MaterialApp(
        title: 'Flutter Dev Panel Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: DevPanelWrapper(
          child: MyHomePage(dio: dio),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Dio dio;
  
  const MyHomePage({super.key, required this.dio});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _responseText = '点击按钮发送请求';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // REST API 请求方法
  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _responseText = '请求中...';
    });
    
    try {
      final response = await widget.dio.get('https://jsonplaceholder.typicode.com/posts/1');
      
      setState(() {
        _responseText = 'Success: ${response.data['title']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMultipleRequests() async {
    setState(() {
      _isLoading = true;
      _responseText = '发送多个请求...';
    });
    
    try {
      await Future.wait([
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/2'),
        widget.dio.get('https://jsonplaceholder.typicode.com/posts/3'),
        widget.dio.get('https://jsonplaceholder.typicode.com/users/1'),
        widget.dio.get('https://jsonplaceholder.typicode.com/comments/1'),
      ]);
      
      setState(() {
        _responseText = '成功发送5个请求！';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendErrorRequest() async {
    setState(() {
      _isLoading = true;
      _responseText = '发送错误请求...';
    });
    
    try {
      await widget.dio.get('https://httpstat.us/500');
      setState(() {
        _responseText = '请求成功';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseText = 'Expected Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Dev Panel Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => FlutterDevPanel.open(context),
            tooltip: '手动打开调试面板',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'REST API', icon: Icon(Icons.api)),
            Tab(text: 'GraphQL', icon: Icon(Icons.data_object)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // REST API 测试页面
          _buildRestApiTab(),
          // GraphQL 测试页面
          _buildGraphQLTab(),
        ],
      ),
    );
  }

  Widget _buildRestApiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              'REST API 测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendRequest,
                  icon: const Icon(Icons.send),
                  label: const Text('发送单个请求'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendMultipleRequests,
                  icon: const Icon(Icons.dynamic_feed),
                  label: const Text('发送多个请求'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendErrorRequest,
                  icon: const Icon(Icons.error),
                  label: const Text('发送错误请求'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResponseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphQLTab() {
    return const GraphQLTestPage();
  }

  Widget _buildResponseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '响应:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  _responseText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _responseText.startsWith('Error') 
                        ? Colors.red 
                        : Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// GraphQL 测试页面
class GraphQLTestPage extends StatefulWidget {
  const GraphQLTestPage({super.key});

  @override
  State<GraphQLTestPage> createState() => _GraphQLTestPageState();
}

class _GraphQLTestPageState extends State<GraphQLTestPage> {
  final String _countriesQuery = r'''
    query GetCountries {
      countries {
        code
        name
        emoji
        capital
        currency
      }
    }
  ''';

  final String _continentsQuery = r'''
    query GetContinents {
      continents {
        code
        name
        countries {
          name
        }
      }
    }
  ''';

  String _selectedQuery = 'countries';
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'GraphQL 测试',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '使用 countries.trevorblades.com API',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          // 查询选择器
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择查询类型:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('国家'),
                          value: 'countries',
                          groupValue: _selectedQuery,
                          onChanged: (value) {
                            setState(() {
                              _selectedQuery = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('大洲'),
                          value: 'continents',
                          groupValue: _selectedQuery,
                          onChanged: (value) {
                            setState(() {
                              _selectedQuery = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // GraphQL 查询结果
          if (_selectedQuery == 'countries')
            _buildCountriesQuery()
          else
            _buildContinentsQuery(),
        ],
      ),
    );
  }

  Widget _buildCountriesQuery() {
    return Query(
      options: QueryOptions(
        document: gql(_countriesQuery),
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: refetch,
              icon: const Icon(Icons.refresh),
              label: const Text('执行国家查询'),
            ),
            const SizedBox(height: 20),
            _buildQueryResult(result),
          ],
        );
      },
    );
  }

  Widget _buildContinentsQuery() {
    return Query(
      options: QueryOptions(
        document: gql(_continentsQuery),
      ),
      builder: (QueryResult result, {fetchMore, refetch}) {
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: refetch,
              icon: const Icon(Icons.refresh),
              label: const Text('执行大洲查询'),
            ),
            const SizedBox(height: 20),
            _buildQueryResult(result),
          ],
        );
      },
    );
  }

  Widget _buildQueryResult(QueryResult result) {
    if (result.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (result.hasException) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'GraphQL Error:\n${result.exception}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedQuery == 'countries') {
      final countries = result.data?['countries'] as List? ?? [];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '查询到 ${countries.length} 个国家:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...countries.take(5).map((country) => ListTile(
                leading: Text(
                  country['emoji'] ?? '',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(country['name'] ?? 'Unknown'),
                subtitle: Text(
                  'Code: ${country['code']}, Capital: ${country['capital'] ?? 'N/A'}',
                ),
                dense: true,
              )),
              if (countries.length > 5)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '... 更多结果请查看网络监控面板',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      final continents = result.data?['continents'] as List? ?? [];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '查询到 ${continents.length} 个大洲:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...continents.map((continent) => ListTile(
                title: Text(continent['name'] ?? 'Unknown'),
                subtitle: Text(
                  'Code: ${continent['code']}, ${(continent['countries'] as List).length} 个国家',
                ),
                dense: true,
              )),
            ],
          ),
        ),
      );
    }
  }
}

// Mutation 示例组件
class GraphQLMutationExample extends StatelessWidget {
  const GraphQLMutationExample({super.key});

  @override
  Widget build(BuildContext context) {
    // 这是一个模拟的mutation，实际API可能不支持
    final String addCountryMutation = r'''
      mutation AddCountry($name: String!, $code: String!) {
        addCountry(name: $name, code: $code) {
          name
          code
        }
      }
    ''';

    return Mutation(
      options: MutationOptions(
        document: gql(addCountryMutation),
        onCompleted: (data) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mutation completed!')),
          );
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mutation error: ${error?.graphqlErrors.first.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
      builder: (runMutation, result) {
        return ElevatedButton.icon(
          onPressed: () {
            runMutation({
              'name': 'Test Country',
              'code': 'TC',
            });
          },
          icon: result?.isLoading == true
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('执行 Mutation (模拟)'),
        );
      },
    );
  }
}