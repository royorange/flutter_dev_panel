# Flutter Dev Panel

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel.svg)](https://pub.dev/packages/flutter_dev_panel)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modular, zero-intrusion debugging panel for Flutter applications that provides real-time monitoring and debugging capabilities during development.

[中文文档](README_CN.md)

## Features

### Core Capabilities
- **Zero Intrusion**: No impact on production code
- **Modular Architecture**: Load only the modules you need
- **High Performance**: Optimized to minimize impact on app performance
- **Multiple Trigger Modes**: Floating button, shake gesture, or programmatic

### Available Modules

#### Console Module
- Real-time log capture (print, debugPrint, Logger package)
- Log level filtering (verbose, debug, info, warning, error)
- Search and filter capabilities
- Automatic ANSI color code handling
- Configurable log retention and auto-scroll

#### Network Module
- HTTP request/response monitoring
- GraphQL query and mutation tracking
- Support for Dio, http, and GraphQL packages
- Request history persistence
- Detailed request/response inspection
- JSON viewer with syntax highlighting

#### Device Module
- Device model and specifications
- Screen dimensions and PPI calculation
- Operating system information
- Platform-specific details
- App package information

#### Performance Module
- Real-time FPS monitoring
- Memory usage tracking
- Dropped frames detection
- Performance charts and trends
- Memory peak tracking

#### Environment Module
- Environment switching (Development/Production)
- Environment variable management
- Configuration persistence
- Real-time environment updates

## Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

## Quick Start

### 1. Initialize the Dev Panel

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize environment configurations
    EnvironmentManager.instance.initialize(
      environments: [
        const EnvironmentConfig(
          name: 'Development',
          variables: {
            'api_url': 'https://dev-api.example.com',
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
    
    // Initialize Flutter Dev Panel
    FlutterDevPanel.initialize(
      config: const DevPanelConfig(
        enabled: true,
        triggerModes: {TriggerMode.fab, TriggerMode.shake},
        showInProduction: false,
      ),
      modules: [
        const ConsoleModule(),
        NetworkModule(),
        const DeviceModule(),
        const PerformanceModule(),
      ],
      enableLogCapture: true,
    );
    
    runApp(MyApp());
  }, (error, stack) {
    DevLogger.instance.error('Uncaught Error', 
      error: error.toString(), 
      stackTrace: stack.toString()
    );
  });
}
```

### 2. Wrap Your App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DevPanelWrapper(
        child: YourHomePage(),
      ),
    );
  }
}
```

### 3. Configure Network Monitoring (Optional)

For Dio:
```dart
final dio = Dio();
NetworkModule.attachToDio(dio);
```

For GraphQL:
```dart
final graphQLClient = GraphQLClient(
  link: HttpLink('https://api.example.com/graphql'),
  cache: GraphQLCache(),
);
final monitoredClient = NetworkModule.attachToGraphQL(graphQLClient);
```

## Module Configuration

### Console Module
```dart
DevLogger.instance.updateConfig(
  const LogCaptureConfig(
    maxLogs: 500,
    autoScroll: true,
    combineLoggerOutput: true,  // Combine multi-line Logger package output
  ),
);

// Use predefined configurations
DevLogger.instance.updateConfig(
  const LogCaptureConfig.development(), // maxLogs: 1000, autoScroll: true
);
```

### Performance Module
The performance module automatically monitors:
- Frame rate (FPS)
- Memory usage
- Dropped frames
- Render time

No additional configuration required.

## Accessing the Dev Panel

There are three ways to open the dev panel:

1. **Floating Button**: Tap the floating debug button
2. **Shake Gesture**: Shake your device
3. **Programmatically**: 
```dart
FlutterDevPanel.open(context);
```

## Environment Management

Access environment variables in your app:

```dart
// Get current environment
final currentEnv = EnvironmentManager.instance.currentEnvironment;

// Get specific variable
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');

// Listen to environment changes
EnvironmentManager.instance.addListener(() {
  // Handle environment change
});
```

## Advanced Usage

### Custom Module Creation

Create your own custom modules by extending `DevModule`:

```dart
class CustomModule extends DevModule {
  @override
  String get name => 'Custom';
  
  @override
  IconData get icon => Icons.extension;
  
  @override
  Widget buildPage(BuildContext context) {
    return YourCustomPage();
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // Optional: Return widget to display in FAB
    return Text('Custom Info');
  }
}
```

### Production Safety

The dev panel automatically disables itself in production builds unless explicitly configured:

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    enabled: !kReleaseMode, // Automatically disable in release
    showInProduction: false, // Extra safety check
  ),
  // ...
);
```

## Architecture

The Flutter Dev Panel follows a modular architecture:

```
flutter_dev_panel/
├── lib/
│   ├── core/              # Core functionality
│   ├── modules/            # Module interfaces
│   └── ui/                 # UI components
├── packages/
│   ├── flutter_dev_panel_console/     # Console module
│   ├── flutter_dev_panel_network/     # Network module
│   ├── flutter_dev_panel_device/      # Device info module
│   └── flutter_dev_panel_performance/ # Performance module
└── example/                            # Example application
```

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Run `flutter pub get` in the root directory
3. Run the example app: `cd example && flutter run`

### Running Tests

```bash
flutter test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_dev_panel/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/flutter_dev_panel/discussions)
- **Documentation**: [API Documentation](https://pub.dev/documentation/flutter_dev_panel/latest/)

## Acknowledgments

Special thanks to all contributors who have helped make this project better.

## Roadmap

- [ ] Custom theme support
- [ ] Export/Import configurations
- [ ] Network request replay
- [ ] Performance profiling export
- [ ] WebSocket monitoring
- [ ] Database query monitoring
- [ ] State management inspection

## Related Projects

- [flutter_dev_panel_console](https://pub.dev/packages/flutter_dev_panel_console)
- [flutter_dev_panel_network](https://pub.dev/packages/flutter_dev_panel_network)
- [flutter_dev_panel_device](https://pub.dev/packages/flutter_dev_panel_device)
- [flutter_dev_panel_performance](https://pub.dev/packages/flutter_dev_panel_performance)