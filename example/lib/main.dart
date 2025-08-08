import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio();
  
  // 附加网络监控到Dio
  NetworkModule.attachToDio(dio);
  
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
  
  runApp(MyApp(dio: dio));
}

class MyApp extends StatelessWidget {
  final Dio dio;
  
  const MyApp({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dev Panel Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DevPanelWrapper(
        child: MyHomePage(dio: dio),
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

class _MyHomePageState extends State<MyHomePage> {
  String _responseText = '点击按钮发送请求';
  bool _isLoading = false;

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Flutter Dev Panel 模块化示例',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '已加载的模块:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text('✅ 网络监控模块'),
                      const Text('✅ 设备信息模块'),
                      const Text('✅ 性能监控模块'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        '打开调试面板的方式:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text('1. 点击右下角悬浮按钮'),
                      const Text('2. 摇一摇设备'),
                      const Text('3. 点击右上角调试图标'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '网络请求测试:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendRequest,
                    child: const Text('发送单个请求'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendMultipleRequests,
                    child: const Text('发送多个请求'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendErrorRequest,
                    child: const Text('发送错误请求'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}