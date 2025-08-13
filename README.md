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

### Built-in Features

#### Environment Management
- Environment switching (Development/Production/Custom)
- Environment variable management
- Configuration persistence
- Real-time environment updates
- .env file support
- Priority-based configuration loading (--dart-define > .env files > code config)

#### Theme Management
- Light/Dark/System theme modes
- Bidirectional sync with app theme
- Theme persistence

## Available Modules

### Console Module (`flutter_dev_panel_console`)
- Real-time log capture (print, debugPrint, Logger package)
- Log level filtering (verbose, debug, info, warning, error)
- Search and filter functionality
- Configurable log retention and auto-scroll
- Smart merging of Logger package multi-line output

### Network Module (`flutter_dev_panel_network`)
- HTTP request/response monitoring
- GraphQL query and mutation tracking
- Support for Dio, http, and GraphQL packages
- Request history persistence
- Detailed request/response inspection
- JSON viewer with syntax highlighting

### Device Module (`flutter_dev_panel_device`)  
- Device model and specifications
- Screen dimensions and PPI calculation
- Operating system information
- Platform-specific details
- App package information

### Performance Module (`flutter_dev_panel_performance`)
- Real-time FPS monitoring
- Memory usage tracking
- Frame drop detection
- Performance charts and trends
- Memory peak tracking

## Installation

### Option 1: Core Package Only (Minimal)

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
```

### Option 2: With Specific Modules (Recommended)

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0    # Logging features
  flutter_dev_panel_network: ^1.0.0    # Network monitoring
  # Add only the modules you need
```

### Option 3: All Modules

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
  flutter_dev_panel_console: ^1.0.0
  flutter_dev_panel_network: ^1.0.0
  flutter_dev_panel_device: ^1.0.0
  flutter_dev_panel_performance: ^1.0.0
```

## Quick Start

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// Import the modules you need
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environments
  // --dart-define automatically overrides matching keys
  await EnvironmentManager.instance.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {
          'api_url': 'https://dev.api.example.com',
          'api_key': '',  // Will be overridden by --dart-define=api_key=xxx
          'debug': true,
          'timeout': 30000,
        },
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'api_key': '',  // Will be overridden by --dart-define=api_key=xxx
          'debug': false,
          'timeout': 10000,
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

## Environment Management

### Configuration Priority
Environment variables are loaded in the following priority order (highest to lowest):
1. **--dart-define** - Command line arguments (automatically detected)
2. **.env files** - Environment-specific files (if present)
3. **Code configuration** - Defaults in `initialize()`
4. **Saved configuration** - Previous runtime values

**How it works:**
- The system automatically discovers all keys from your configurations
- Any matching key passed via --dart-define will override other sources
- Keys are matched case-insensitively and with format variations (snake_case, dash-case)

### Recommended Setup

1. **Create environment files:**
```bash
# .env.example (commit to git - template)
API_URL=https://api.example.com
API_KEY=your-key-here
ENABLE_ANALYTICS=false

# .env.development (commit to git - safe defaults)
API_URL=https://dev.api.example.com
ENABLE_ANALYTICS=false

# .env.production (commit to git - non-sensitive configs)
API_URL=https://api.example.com
ENABLE_ANALYTICS=true
# Sensitive values injected via --dart-define in CI/CD
```

2. **Add to pubspec.yaml (for production builds):**
```yaml
flutter:
  assets:
    - .env.production  # Required for release builds
```

3. **Add to .gitignore (only local overrides):**
```gitignore
.env
.env.local
.env.*.local
!.env.example
!.env.development
!.env.production
```

4. **Build commands:**
```bash
# Development (uses .env.development)
flutter run

# Production with secrets from CI/CD
flutter build apk \
  --dart-define=API_KEY=$SECRET_API_KEY \
  --dart-define=DB_PASSWORD=$SECRET_DB_PASSWORD

# CI/CD example
flutter build ios \
  --dart-define=API_KEY=${{ secrets.API_KEY }} \
  --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
```

### Configuration Strategy

**Commit to Git:**
- `.env.development` - Development URLs and non-sensitive configs
- `.env.production` - Production URLs and non-sensitive configs
- `.env.example` - Template with all variables documented

**Inject via CI/CD (--dart-define):**
- API keys, tokens, passwords
- Third-party service credentials
- Any sensitive configuration
- Environment-specific overrides

**Benefits:**
- Non-sensitive configs are version controlled
- Sensitive data never touches the repository
- CI/CD can override any value defined in your config
- Developers can run the app without manual setup
- No need to maintain a hardcoded list of keys

### How --dart-define Works

1. **Define keys in your environment config** with default values:
```dart
const EnvironmentConfig(
  name: 'Production',
  variables: {
    'api_url': 'https://api.example.com',
    'api_key': '',  // Empty default, will be injected
    'sentry_dsn': '',  // Empty default, will be injected
  },
)
```

2. **Override via --dart-define** in CI/CD:
```bash
flutter build apk \
  --dart-define=api_key=${{ secrets.API_KEY }} \
  --dart-define=sentry_dsn=${{ secrets.SENTRY_DSN }}
```

The system automatically detects and applies these overrides.

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

If your app already has theme management, you can sync it with the dev panel, this is an example code:

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

## Module Configuration

### Console Module
```dart
DevLogger.instance.updateConfig(
  const LogCaptureConfig(
    maxLogs: 500,
    autoScroll: true,
    combineLoggerOutput: true,  // Merge Logger package multi-line output
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
- Frame drops
- Render time

No additional configuration required.

## Advanced Usage

### Creating Custom Modules

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
    // Optional: Return a widget to display in FAB
    return Text('Custom Info');
  }
}
```

### Production Safety

The dev panel automatically disables itself in production builds unless explicitly configured:

```dart
FlutterDevPanel.initialize(
  config: const DevPanelConfig(
    enabled: !kReleaseMode, // Automatically disabled in release builds
    showInProduction: false, // Additional safety check
  ),
  // ...
);
```

## Architecture

Flutter Dev Panel follows a modular architecture:

```
flutter_dev_panel/              # Core framework (required)
├── lib/
│   └── src/
│       ├── core/               # Core functionality
│       ├── models/             # Data models
│       └── ui/                 # UI components
├── packages/                   # Optional modules
│   ├── flutter_dev_panel_console/     # Console/logging module
│   ├── flutter_dev_panel_network/     # Network monitoring module
│   ├── flutter_dev_panel_device/      # Device info module
│   └── flutter_dev_panel_performance/ # Performance monitoring module
└── example/                    # Example app
```

Each module package depends on the core `flutter_dev_panel` package and can be independently installed.

## Testing

```bash
# Run all tests
flutter test

# Test individual modules
flutter test packages/flutter_dev_panel_console/test
flutter test packages/flutter_dev_panel_network/test
flutter test packages/flutter_dev_panel_device/test
flutter test packages/flutter_dev_panel_performance/test

# Run example app
cd example
flutter run
```

## License

MIT License - see [LICENSE](LICENSE) file for details