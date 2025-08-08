# Flutter Dev Panel - Network Module

网络监控模块，支持多种HTTP客户端库的集成。

## 特性

- ✅ 支持Dio、http包等多种HTTP库
- ✅ 请求历史持久化存储
- ✅ 实时监控请求状态
- ✅ 详细的请求/响应信息查看
- ✅ 请求过滤和搜索
- ✅ FAB实时显示网络状态

## 使用方法

### 1. Dio 集成

```dart
import 'package:dio/dio.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

// 方式1：单个Dio实例
final dio = Dio();
NetworkModule.attachToDio(dio);

// 方式2：多个Dio实例
NetworkModule.attachToMultipleDio([dio1, dio2, dio3]);
```

### 2. http 包集成

```dart
import 'package:http/http.dart' as http;
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

// 方式1：创建新的客户端
final client = NetworkModule.createHttpClient();

// 方式2：包装现有客户端
final existingClient = http.Client();
final monitoredClient = NetworkModule.wrapHttpClient(existingClient);
```

### 3. 自定义HTTP库集成

对于其他HTTP库，可以使用基础拦截器手动集成。

## 数据持久化

网络请求会自动保存到本地存储，应用重启后可以查看历史记录。
