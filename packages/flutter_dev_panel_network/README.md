# Flutter Dev Panel - Network Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_network.svg)](https://pub.dev/packages/flutter_dev_panel_network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

Network monitoring module for Flutter Dev Panel that provides unified request tracking across Dio, http package, and GraphQL.

## Features

- **Multi-library support** - Works with Dio, http package, and graphql_flutter
- **Persistent storage** - Request history survives app restarts
- **Real-time monitoring** - Live network activity in floating action button
- **Request/Response inspection** - View headers, body, timing, and size
- **GraphQL support** - Operation type detection and query inspection
- **Advanced filtering** - Search by URL, status code, method, and more

## Installation

```yaml
dependencies:
  flutter_dev_panel_network:
    path: ../packages/flutter_dev_panel_network
```

## Usage

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:dio/dio.dart';

void main() {
  // Initialize with network module
  DevPanel.initialize(
    modules: [NetworkModule()],
  );
  
  // Attach to Dio
  final dio = Dio();
  NetworkModule.attachToDio(dio);
  
  // Or attach to GraphQL
  final graphQLClient = NetworkModule.createGraphQLClient(
    endpoint: 'https://api.example.com/graphql',
  );
  
  runApp(MyApp());
}
```


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.