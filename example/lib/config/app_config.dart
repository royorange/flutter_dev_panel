/// 应用配置管理示例
/// 这是用户应用的配置，不是 flutter_dev_panel 的一部分
/// 用户可以根据自己的需求实现
class AppConfig {
  static final AppConfig instance = AppConfig._();
  AppConfig._();
  
  late String _apiUrl;
  late String _environment;
  late bool _debugMode;
  
  /// 初始化应用配置
  /// 这个方法做了以下事情：
  /// 1. 从编译时常量读取环境变量
  /// 2. 根据环境设置不同的默认值
  /// 3. 应用业务逻辑配置
  void initialize() {
    // 1. 读取编译时的环境变量
    _environment = const String.fromEnvironment(
      'ENV',
      defaultValue: 'production',
    );
    
    // 2. 根据环境设置不同的配置
    switch (_environment) {
      case 'development':
        _apiUrl = const String.fromEnvironment(
          'API_URL',
          defaultValue: 'http://localhost:3000',
        );
        _debugMode = true;
        break;
        
      case 'staging':
        _apiUrl = const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://staging-api.example.com',
        );
        _debugMode = false;
        break;
        
      case 'production':
      default:
        _apiUrl = const String.fromEnvironment(
          'API_URL',
          defaultValue: 'https://api.example.com',
        );
        _debugMode = false;
        break;
    }
  }
  
  // Getters
  String get apiUrl => _apiUrl;
  String get environment => _environment;
  bool get debugMode => _debugMode;
  
  // 环境判断
  bool get isProduction => _environment == 'production';
  bool get isDevelopment => _environment == 'development';
  bool get isStaging => _environment == 'staging';
  
  // 动态更新配置（仅用于开发调试）
  void updateApiUrl(String newUrl) {
    assert(() {
      _apiUrl = newUrl;
      print('API URL updated to: $newUrl');
      return true;
    }());
  }
}