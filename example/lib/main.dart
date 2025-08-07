import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Flutter Dev Panel
  await FlutterDevPanel.init(
    config: DevPanelConfig(
      enabled: true,
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
      environments: Environment.defaultEnvironments(),
      showInProduction: false,
    ),
  );
  
  // 配置Dio网络监控
  final dio = Dio();
  FlutterDevPanel.addDioInterceptor(dio);
  
  // 将dio实例注册到GetX
  Get.put(dio);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Dev Panel Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FlutterDevPanel.wrap(
        child: const MyHomePage(),
        enableFloatingButton: true,
        enableShakeDetection: true,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
    
    final dio = Get.find<Dio>();
    
    try {
      // 使用当前环境的API URL
      final apiUrl = FlutterDevPanel.getEnvironmentConfig<String>('api_url') 
                    ?? 'https://jsonplaceholder.typicode.com';
      
      final response = await dio.get('$apiUrl/posts/1');
      
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
    final dio = Get.find<Dio>();
    final apiUrl = FlutterDevPanel.getEnvironmentConfig<String>('api_url') 
                  ?? 'https://jsonplaceholder.typicode.com';
    
    setState(() {
      _isLoading = true;
      _responseText = '发送多个请求...';
    });
    
    try {
      await Future.wait([
        dio.get('$apiUrl/posts/1'),
        dio.get('$apiUrl/posts/2'),
        dio.get('$apiUrl/posts/3'),
        dio.get('$apiUrl/users/1'),
        dio.get('$apiUrl/comments/1'),
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
    final dio = Get.find<Dio>();
    
    setState(() {
      _isLoading = true;
      _responseText = '发送错误请求...';
    });
    
    try {
      await dio.get('https://httpstat.us/500');
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
            onPressed: () => FlutterDevPanel.show(),
            tooltip: '手动打开调试面板',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Flutter Dev Panel 示例应用',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      const Text('4. 调用 FlutterDevPanel.show()'),
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
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '响应:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _responseText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _responseText.startsWith('Error') 
                              ? Colors.red 
                              : Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '提示: 打开调试面板查看更多功能',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}