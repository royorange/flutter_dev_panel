import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';

// Create a global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.none,
  ),
);

void main() async {
  // Run the entire app in a Zone that intercepts print
  runZonedGuarded(() async {
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

    // Initialize environment configurations
    EnvironmentManager.instance.initialize(
      environments: [
        const EnvironmentConfig(
          name: 'Development',
          variables: {
            'api_url': 'https://dev-api.example.com',
            'socket_url': 'wss://dev-socket.example.com',
            'graphql_endpoint': 'https://countries.trevorblades.com/',
            'debug': true,
            'log_level': 'verbose',
            'timeout': 30000,
          },
          isDefault: true,
        ),
        const EnvironmentConfig(
          name: 'Production',
          variables: {
            'api_url': 'https://api.example.com',
            'socket_url': 'wss://socket.example.com',
            'graphql_endpoint': 'https://graphql.example.com/',
            'debug': false,
            'log_level': 'error',
            'timeout': 15000,
          },
        ),
      ],
      defaultEnvironment: 'Development',
    );

    // Initialize Flutter Dev Panel with log capture
    FlutterDevPanel.initialize(
      config: const DevPanelConfig(
        enabled: true,
        triggerModes: {TriggerMode.fab, TriggerMode.shake},
        showInProduction: false,
      ),
      modules: [
        const ConsoleModule(), // Console 第一个显示
        NetworkModule(),
        const DeviceModule(),
        const PerformanceModule(),
      ],
      enableLogCapture: true,
    );
    
    // 配置日志捕获（可选，默认使用 development 模式）
    DevLogger.instance.updateConfig(
      const LogCaptureConfig.development(), // 开发模式：捕获应用和库日志
    );

    runApp(MyApp(
      dio: dio,
      graphQLClient: monitoredGraphQLClient,
    ));
  }, (error, stack) {
    // Errors will be captured by DevLogger
    DevLogger.instance.error(
      'Uncaught Error in Zone',
      error: error.toString(),
      stackTrace: stack.toString(),
    );
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      // Capture print statements
      DevLogger.instance.info(line);
      // Still print to console
      parent.print(zone, line);
    },
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
    // Listen to theme changes
    return ListenableBuilder(
      listenable: ThemeManager.instance,
      builder: (context, _) {
        final themeManager = ThemeManager.instance;
        
        return GraphQLProvider(
          client: ValueNotifier(graphQLClient),
          child: MaterialApp(
            title: 'Flutter Dev Panel Example',
            // Theme configuration from ThemeManager
            themeMode: themeManager.currentTheme.mode,
            theme: themeManager.getThemeData(
              context,
              baseTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
              ),
            ) ?? ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: DevPanelWrapper(
              child: MyHomePage(dio: dio),
            ),
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Dio dio;

  const MyHomePage({super.key, required this.dio});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _responseText = 'Click button to send request';
  bool _isLoading = false;
  
  // Environment variables
  String _currentEnv = '';
  String _apiUrl = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize environment values
    _updateEnvironmentValues();
    
    // Listen to environment changes
    EnvironmentManager.instance.addListener(_updateEnvironmentValues);
  }
  
  void _updateEnvironmentValues() {
    setState(() {
      _currentEnv = EnvironmentManager.instance.currentEnvironment?.name ?? 'None';
      _apiUrl = EnvironmentManager.instance.getVariable<String>('api_url') ?? 'Not configured';
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    EnvironmentManager.instance.removeListener(_updateEnvironmentValues);
    super.dispose();
  }

  // REST API 请求方法
  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Sending request...';
    });

    try {
      final response =
          await widget.dio.get('https://jsonplaceholder.typicode.com/posts/1');

      setState(() {
        _responseText = 'Request successful!';
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
      _responseText = 'Sending multiple requests...';
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
        _responseText = 'Successfully sent 5 requests!';
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
      _responseText = 'Sending error request...';
    });

    try {
      await widget.dio.get('https://httpstat.us/500');
      setState(() {
        _responseText = 'Request successful';
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
            tooltip: 'Open Dev Panel',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Network', icon: Icon(Icons.cloud)),
            Tab(text: 'Modules', icon: Icon(Icons.dashboard)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Network testing page (includes REST API and GraphQL)
          _buildNetworkTab(),
          // Modules showcase page
          _buildModulesTab(),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Network module header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.network_check,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Network Monitor Module',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Test HTTP requests, GraphQL queries, and monitor network traffic',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const TabBar(
              tabs: [
                Tab(text: 'REST API'),
                Tab(text: 'GraphQL'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRestApiSection(),
                const GraphQLTestPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestApiSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),
            const Text(
              'REST API Testing',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendRequest,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Single Request'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendMultipleRequests,
                  icon: const Icon(Icons.dynamic_feed),
                  label: const Text('Send Multiple Requests'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendErrorRequest,
                  icon: const Icon(Icons.error),
                  label: const Text('Send Error Request'),
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

  Widget _buildModulesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Flutter Dev Panel Modules',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Explore all available debugging modules',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 30),
          
          // Network Module Card
          _buildModuleCard(
            icon: Icons.network_check,
            title: 'Network Monitor',
            description: 'Track HTTP requests, GraphQL queries, and WebSocket connections',
            features: [
              'Real-time request tracking',
              'Request/Response inspection',
              'GraphQL support',
              'Error monitoring',
            ],
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          // Device Module Card
          _buildModuleCard(
            icon: Icons.phone_android,
            title: 'Device Information',
            description: 'View device specifications and system information',
            features: [
              'Device model & OS version',
              'Screen dimensions & PPI',
              'Platform information',
              'App package details',
            ],
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          // Performance Module Card
          _buildModuleCard(
            icon: Icons.speed,
            title: 'Performance Monitor',
            description: 'Monitor app performance metrics in real-time',
            features: [
              'FPS monitoring',
              'Memory usage tracking',
              'Battery consumption',
              'Frame rendering analysis',
            ],
            color: Colors.orange,
          ),
          
          const SizedBox(height: 16),
          
          // Console Module Card
          _buildModuleCard(
            icon: Icons.terminal,
            title: 'Console / Logs',
            description: 'View and filter application logs and errors',
            features: [
              'Real-time log capture',
              'Log level filtering',
              'Search functionality',
              'Error tracking',
            ],
            color: Colors.purple,
          ),
          
          const SizedBox(height: 20),
          
          // Console Test Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Console Test Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          DevLogger.instance.verbose('Verbose log message');
                          DevLogger.instance.debug('Debug information');
                          DevLogger.instance.info('Info: Action completed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logs added')),
                          );
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Normal Logs'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          DevLogger.instance.warning('Warning: Resource usage high');
                          DevLogger.instance.error(
                            'Error: Failed to load resource',
                            error: 'FileNotFoundException',
                            stackTrace: 'at loadFile() line 42',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Errors added')),
                          );
                        },
                        icon: const Icon(Icons.error_outline, size: 16),
                        label: const Text('Add Errors'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ConsoleModule.addTestLogs();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Test logs added')),
                          );
                        },
                        icon: const Icon(Icons.text_snippet, size: 16),
                        label: const Text('Add Test Logs'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Test print interception
                          print('This is a print statement');
                          print('Debug: User clicked test button');
                          print('Info: Testing print interception');
                          debugPrint('This is a debugPrint statement');
                          
                          // Test developer.log
                          developer.log('Developer log message', name: 'TestApp');
                          developer.log('Complex object', error: {'key': 'value'});
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Print statements captured')),
                          );
                        },
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Test Print'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Test Logger package
                          logger.t('Trace log from Logger package');
                          logger.d('Debug log from Logger package');
                          logger.i('Info log from Logger package');
                          logger.w('Warning log from Logger package');
                          logger.e('Error log from Logger package', 
                            error: Exception('Test exception'),
                            stackTrace: StackTrace.current,
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logger package logs sent')),
                          );
                        },
                        icon: const Icon(Icons.library_books, size: 16),
                        label: const Text('Test Logger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Test error throwing
                          try {
                            throw Exception('Test exception for console');
                          } catch (e, stack) {
                            DevLogger.instance.error(
                              'Caught exception',
                              error: e.toString(),
                              stackTrace: stack.toString(),
                            );
                          }
                          
                          // Test async error
                          Future.delayed(const Duration(milliseconds: 100), () {
                            // This will be caught by the Zone error handler
                            DevLogger.instance.warning('Simulating async error...');
                            // Uncomment to test actual error catching:
                            // throw StateError('Async error test');
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Errors thrown and caught')),
                          );
                        },
                        icon: const Icon(Icons.warning, size: 16),
                        label: const Text('Test Errors'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Current Environment Info
          Card(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Current Environment: $_currentEnv',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API URL: $_apiUrl',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This value updates automatically when you switch environments in Dev Panel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // How to use section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'How to Access Dev Panel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAccessMethod(
                    icon: Icons.touch_app,
                    method: 'Floating Button',
                    description: 'Tap the floating debug button',
                  ),
                  const SizedBox(height: 8),
                  _buildAccessMethod(
                    icon: Icons.vibration,
                    method: 'Shake Device',
                    description: 'Shake your device to open',
                  ),
                  const SizedBox(height: 8),
                  _buildAccessMethod(
                    icon: Icons.code,
                    method: 'Programmatically',
                    description: 'Call FlutterDevPanel.open(context)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModuleCard({
    required IconData icon,
    required String title,
    required String description,
    required List<String> features,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Features:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccessMethod({
    required IconData icon,
    required String method,
    required String description,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        color: isDark 
          ? theme.colorScheme.surfaceContainerHighest
          : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Response:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
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
                        ? theme.colorScheme.error
                        : Colors.green.shade700,
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
  bool _isLoading = false;
  QueryResult? _queryResult;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'GraphQL Testing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Using countries.trevorblades.com API',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 查询选择器
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Query Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Countries', style: TextStyle(fontSize: 14)),
                          value: 'countries',
                          groupValue: _selectedQuery,
                          onChanged: (value) {
                            setState(() {
                              _selectedQuery = value!;
                              _queryResult = null; // Clear previous result when switching
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Text('Continents', style: TextStyle(fontSize: 14)),
                          value: 'continents',
                          groupValue: _selectedQuery,
                          onChanged: (value) {
                            setState(() {
                              _selectedQuery = value!;
                              _queryResult = null; // Clear previous result when switching
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

          // Execute button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _executeQuery,
            icon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
            label: Text(
              _isLoading 
                ? 'Loading...' 
                : 'Execute ${_selectedQuery == 'countries' ? 'Countries' : 'Continents'} Query'
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Query result
          if (_queryResult != null)
            _buildQueryResult(_queryResult!),
        ],
      ),
    );
  }

  Future<void> _executeQuery() async {
    setState(() {
      _isLoading = true;
      _queryResult = null;
    });
    
    try {
      final client = GraphQLProvider.of(context).value;
      final QueryOptions options = QueryOptions(
        document: gql(_selectedQuery == 'countries' ? _countriesQuery : _continentsQuery),
        fetchPolicy: FetchPolicy.noCache,
      );
      
      final result = await client.query(options);
      
      setState(() {
        _queryResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('GraphQL query error: $e');
    }
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
      final theme = Theme.of(context);
      return Card(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.error, 
                color: theme.colorScheme.error, 
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'GraphQL Error:\n${result.exception}',
                style: TextStyle(color: theme.colorScheme.error),
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
                'Found ${countries.length} countries:',
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
                    '... More results in Network Monitor panel',
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
                'Found ${continents.length} continents:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...continents.map((continent) => ListTile(
                    title: Text(continent['name'] ?? 'Unknown'),
                    subtitle: Text(
                      'Code: ${continent['code']}, ${(continent['countries'] as List).length} countries',
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
    const String addCountryMutation = r'''
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
              content:
                  Text('Mutation error: ${error?.graphqlErrors.first.message}'),
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
          label: const Text('Execute Mutation (Mock)'),
        );
      },
    );
  }
}
