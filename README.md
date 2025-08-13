# Flutter Dev Panel

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel.svg)](https://pub.dev/packages/flutter_dev_panel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular, zero-intrusion debugging panel for Flutter applications that provides real-time monitoring and debugging capabilities during development.

[中文文档](README_CN.md)

## Features

- **Zero Intrusion**: No impact on production code
- **Modular Architecture**: Load only the modules you need
- **High Performance**: Optimized to minimize impact on app performance
- **Multiple Trigger Modes**: Floating button, shake gesture, or programmatic
- **Environment Management**: Switch between Development/Production/Custom environments
- **Theme Support**: Light/Dark/System theme modes

## Available Modules

- **Console** (`flutter_dev_panel_console`): Real-time log capture and filtering
- **Network** (`flutter_dev_panel_network`): HTTP/GraphQL request monitoring
- **Device** (`flutter_dev_panel_device`): Device information and specifications
- **Performance** (`flutter_dev_panel_performance`): FPS and memory monitoring

## Installation

```yaml
dependencies:
  flutter_dev_panel: ^0.0.1
  
  # Add only the modules you need:
  flutter_dev_panel_console: ^0.0.1
  flutter_dev_panel_network: ^0.0.1
  flutter_dev_panel_device: ^0.0.1
  flutter_dev_panel_performance: ^0.0.1
```

## Quick Start

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// Import the modules you need
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  // Initialize environments
  EnvironmentManager.instance.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'api_url': 'https://dev.api.example.com',
          'debug': true,
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'debug': false,
        },
      ),
    ],
  );

  // Initialize dev panel with selected modules
  FlutterDevPanel.initialize(
    modules: [
      ConsoleModule(),
      NetworkModule(),
      // Add more modules as needed
    ],
  );

  runApp(
    DevPanelWrapper(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to theme changes from dev panel
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,  // Apply theme from dev panel
          home: MyHomePage(),
        );
      },
    );
  }
}
```

## Usage

### Access the Panel
- **Floating Button**: Tap the FAB (default)
- **Shake Gesture**: Shake the device
- **Programmatic**: `FlutterDevPanel.open(context)`

### Get Environment Variables
```dart
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');
final isDebug = EnvironmentManager.instance.getVariable<bool>('debug');
```

### Network Monitoring Setup

For **Dio**:
```dart
final dio = Dio();
dio.interceptors.add(NetworkInterceptor.dio());
```

For **HTTP**:
```dart
final client = NetworkInterceptor.http(http.Client());
```

For **GraphQL**:
```dart
final graphQLClient = GraphQLClient(
  link: NetworkInterceptor.graphQL(httpLink),
  cache: GraphQLCache(),
);
```

## Configuration

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    enabled: true,  // Enable/disable the panel
    showInProduction: false,  // Hide in production builds
    triggerModes: {
      TriggerMode.fab,
      TriggerMode.shake,
    },
  ),
  modules: [...],
);
```

## Theme Integration

If your app already has theme management, you can sync it with the dev panel:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  
  @override
  void initState() {
    super.initState();
    // Load your app's saved theme preference
    _themeMode = MyThemePreferences.getThemeMode();
    
    // Sync dev panel with your app's theme
    ThemeManager.instance.setThemeMode(_themeMode);
    
    // Listen to dev panel theme changes
    ThemeManager.instance.themeMode.addListener(_onThemeChanged);
  }
  
  void _onThemeChanged() {
    setState(() {
      _themeMode = ThemeManager.instance.themeMode.value;
      // Save to your app's preferences
      MyThemePreferences.saveThemeMode(_themeMode);
    });
  }
  
  @override
  void dispose() {
    ThemeManager.instance.themeMode.removeListener(_onThemeChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MyHomePage(),
    );
  }
}
```

This approach:
- Loads your existing theme preference on startup
- Syncs the dev panel with your app's current theme
- Updates your app's preferences when changed via dev panel
- Maintains consistency between your app and dev panel themes

## License

MIT License - see [LICENSE](LICENSE) file for details