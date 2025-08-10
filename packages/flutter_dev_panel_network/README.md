# Flutter Dev Panel - Network Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_network.svg)](https://pub.dev/packages/flutter_dev_panel_network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

A comprehensive network monitoring module for Flutter Dev Panel that provides unified request tracking and debugging capabilities across multiple HTTP client libraries including Dio, http package, and GraphQL.

## Features

### Core Capabilities
- **Multi-library support** - Seamless integration with Dio, http package, and graphql_flutter
- **Persistent storage** - Request history automatically saved and survives app restarts
- **Real-time monitoring** - Live network activity displayed in floating action button
- **Advanced filtering** - Search by URL, status code, method, and more
- **Session isolation** - Distinguish between historical and current session requests
- **Material Design 3** - Modern UI with full dark mode support

### Network Monitoring
- **Request/Response inspection** - View headers, body, timing, and size
- **Error tracking** - Detailed error messages and stack traces
- **Performance metrics** - Request duration and response size tracking
- **GraphQL support** - Operation type detection, query/mutation inspection
- **WebSocket support** - Monitor GraphQL subscriptions and WebSocket connections

### FAB Display
The floating action button provides real-time network statistics:
- **Pending requests** - Animated counter with spinner
- **Success count** - Green badge for successful requests
- **Error count** - Red highlight for failed requests
- **Performance** - Slowest request time (>1s)
- **Data usage** - Total download size

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_dev_panel_network:
    git:
      url: https://github.com/yourusername/flutter_dev_panel
      path: packages/flutter_dev_panel_network
```

Or if using a local path:

```yaml
dependencies:
  flutter_dev_panel_network:
    path: ../packages/flutter_dev_panel_network
```

## Usage

### Basic Setup

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // Register network monitoring module
  FlutterDevPanel.initialize(
    modules: [
      NetworkModule(),
      // Add other modules as needed
    ],
  );
  
  runApp(MyApp());
}
```

### Dio Integration

```dart
import 'package:dio/dio.dart';

// Simple one-line setup
final dio = Dio();
NetworkModule.attachToDio(dio);

// Multiple Dio instances
NetworkModule.attachToMultipleDio([dio1, dio2, dio3]);

// Manual interceptor addition
dio.interceptors.add(NetworkModule.createInterceptor());

// Using the Dio instance
final response = await dio.get('https://api.example.com/data');
```

### GraphQL Integration

```dart
import 'package:graphql_flutter/graphql_flutter.dart';

// Method 1: Attach to existing client (recommended)
final originalClient = GraphQLClient(
  link: HttpLink('https://api.example.com/graphql'),
  cache: GraphQLCache(),
);

final monitoredClient = NetworkModule.attachToGraphQL(originalClient);

// Method 2: Create new monitored client
final client = NetworkModule.createGraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  subscriptionEndpoint: 'wss://api.example.com/graphql', // Optional
  defaultHeaders: {'Authorization': 'Bearer $token'},
);

// Method 3: Link-level integration
final monitoringLink = NetworkModule.createGraphQLInterceptor();
final link = Link.from([
  monitoringLink,  // Place monitoring first
  authLink,
  httpLink,
]);

// Use with GraphQLProvider
GraphQLProvider(
  client: ValueNotifier(monitoredClient),
  child: MyApp(),
);
```

### HTTP Package Integration

```dart
import 'package:http/http.dart' as http;

// Create monitored client
final client = NetworkModule.createHttpClient();

// Wrap existing client
final wrappedClient = NetworkModule.wrapHttpClient(existingClient);

// Use as normal
final response = await client.get(Uri.parse('https://api.example.com'));
final data = await client.post(
  Uri.parse('https://api.example.com/data'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'key': 'value'}),
);
```

### Custom HTTP Library Integration

For custom HTTP implementations or libraries not directly supported:

```dart
// Get the base interceptor
final interceptor = NetworkModule.getBaseInterceptor();

// Before making request
final requestId = interceptor.recordRequest(
  url: 'https://api.example.com/data',
  method: 'GET',
  headers: headers,
  body: requestBody,
);

// After receiving response
interceptor.recordResponse(
  requestId: requestId,
  statusCode: 200,
  body: responseData,
  responseSize: bytes.length,
);

// On error
interceptor.recordError(
  requestId: requestId,
  error: 'Connection timeout',
);
```

## API Reference

### NetworkModule

The main module class:

```dart
class NetworkModule extends DevModule {
  // Dio integration
  static void attachToDio(Dio dio);
  static void attachToMultipleDio(List<Dio> dioInstances);
  static Interceptor createInterceptor();
  
  // GraphQL integration
  static GraphQLClient attachToGraphQL(GraphQLClient client);
  static GraphQLClient createGraphQLClient({
    required String endpoint,
    String? subscriptionEndpoint,
    Map<String, String>? defaultHeaders,
  });
  static Link createGraphQLInterceptor();
  
  // HTTP package integration
  static http.Client createHttpClient();
  static http.Client wrapHttpClient(http.Client client);
  
  // Custom integration
  static BaseInterceptor getBaseInterceptor();
  
  // Controller access
  static NetworkMonitorController get controller;
}
```

### NetworkMonitorController

Controls network monitoring behavior:

```dart
class NetworkMonitorController {
  // Configuration
  void setMaxRequests(int max);
  void setPaused(bool paused);
  void togglePause();
  
  // Data management
  void clearRequests();
  Stream<List<NetworkRequest>> get requestsStream;
  List<NetworkRequest> get requests;
  
  // Session management
  bool get hasSessionActivity;
  int get sessionRequestCount;
  int get sessionErrorCount;
}
```

### NetworkRequest

Represents a captured network request:

```dart
class NetworkRequest {
  final String id;
  final String method;
  final String url;
  final Map<String, dynamic>? headers;
  final dynamic requestBody;
  final int? statusCode;
  final dynamic responseBody;
  final DateTime timestamp;
  final Duration? duration;
  final int? responseSize;
  final String? error;
  final RequestStatus status;
  
  // GraphQL specific
  final String? operationType;
  final String? operationName;
  final Map<String, dynamic>? variables;
}
```

## Configuration

### Setting Maximum Requests

```dart
// Default is 100
NetworkModule.controller.setMaxRequests(200);
```

### Pause/Resume Monitoring

```dart
// Pause monitoring
NetworkModule.controller.setPaused(true);

// Resume monitoring
NetworkModule.controller.setPaused(false);

// Toggle state
NetworkModule.controller.togglePause();
```

### Clear History

```dart
// Clear all stored requests
NetworkModule.controller.clearRequests();
```

## GraphQL Features

### Operation Type Detection

The module automatically detects and displays:
- **QUERY** - Data fetching operations
- **MUTATION** - Data modification operations
- **SUBSCRIPTION** - Real-time data subscriptions

### Request Details

For GraphQL requests, additional information is captured:
- Operation name
- Query/Mutation string
- Variables
- GraphQL-specific errors (even with HTTP 200 status)

### WebSocket Subscriptions

```dart
final client = NetworkModule.createGraphQLClient(
  endpoint: 'https://api.example.com/graphql',
  subscriptionEndpoint: 'wss://api.example.com/graphql',
);

// Subscriptions are automatically monitored
final subscription = client.subscribe(
  SubscriptionOptions(
    document: gql(subscriptionDocument),
    variables: variables,
  ),
);

subscription.listen((result) {
  // Real-time updates
});
```

## Data Persistence

### Storage Behavior
- Requests automatically saved to SharedPreferences
- History survives app restarts
- Storage limit matches maxRequests setting
- Oldest requests auto-deleted when limit reached

### Session Management
- **Historical data** - Displayed in request list, searchable
- **Session data** - Triggers FAB updates and statistics
- Session resets on app restart
- FAB only shows current session activity

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // Initialize Dev Panel with network module
  FlutterDevPanel.initialize(
    modules: [NetworkModule()],
  );
  
  // Setup Dio
  final dio = Dio();
  NetworkModule.attachToDio(dio);
  
  // Setup GraphQL
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
  
  const MyApp({
    Key? key,
    required this.dio,
    required this.graphQLClient,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: ValueNotifier(graphQLClient),
      child: FlutterDevPanel.wrap(
        child: MaterialApp(
          title: 'Network Monitor Demo',
          home: NetworkDemoPage(dio: dio),
        ),
      ),
    );
  }
}
```

## Performance Considerations

1. **Request limit** - Keep maxRequests reasonable (default 100)
2. **Body size** - Large request/response bodies may impact memory
3. **Production builds** - Consider disabling in release mode
4. **Sensitive data** - Be aware that headers and bodies are stored

## Troubleshooting

### FAB not showing network activity
- Verify module is registered with FlutterDevPanel
- Check if monitoring is paused
- Ensure interceptors are properly attached
- Note that historical requests don't trigger FAB

### Requests not being captured
- Confirm interceptor is added to HTTP client
- Check if monitoring is paused
- For GraphQL, ensure using wrapped client
- Verify network permissions on device

### Storage issues
- Check SharedPreferences permissions
- Verify storage isn't full
- Look for storage-related errors in console

## Best Practices

1. **Security** - Disable in production to prevent data leakage
2. **Privacy** - Be mindful of sensitive data in headers/bodies
3. **Performance** - Adjust maxRequests based on app needs
4. **Testing** - Use network module to verify API integration
5. **Debugging** - Enable full request/response logging during development

## Contributing

We welcome contributions! Please see our contributing guidelines for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please file an issue on the [GitHub repository](https://github.com/yourusername/flutter_dev_panel/issues).