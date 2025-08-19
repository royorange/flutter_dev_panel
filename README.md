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
- Real-time FPS monitoring with visual charts
- Memory usage tracking and leak detection
- Automatic Timer tracking via Zone API
- Resource leak detection (Timers & StreamSubscriptions)
- Interactive performance analysis with actionable advice
- 📖 [View full documentation →](./packages/flutter_dev_panel_performance/)

## Architecture

Flutter Dev Panel uses a **fully modular architecture** that ensures:
- ✅ **Zero overhead in production** - Unused code is completely removed by tree shaking
- ✅ **Pay for what you use** - Only imported modules are included in your app
- ✅ **Production safe** - Compile-time constants ensure automatic disabling in release builds

### How It Works

1. **Compile-time optimization**: All debug code is wrapped in `if (kDebugMode || _forceDevPanel)` checks
2. **Tree shaking**: In release builds, the Dart compiler removes all unreachable code
3. **Modular imports**: Each module is a separate package that users explicitly import
4. **No runtime overhead**: When not enabled, there's zero performance impact

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

> **Important**: Choose the right initialization method based on your needs:
> - **Method 1**: Automatic setup with full features ✅ (Recommended)
>   - Auto-captures print/debugPrint for Console module
>   - Auto-tracks Timers for Performance module
>   - Handles all Zone setup automatically
> - **Method 2**: Custom Zone setup for integration with other tools 🔧
>   - Use when integrating with Sentry/Crashlytics
>   - Requires manual Zone configuration
> - **Method 3**: Traditional initialization with limited features ⚠️
>   - No automatic print capture
>   - No automatic Timer tracking
>   - Only for compatibility with existing codebases

### Method 1: Using DevPanel.init (Recommended)

Automatically sets up Zone to intercept print statements and handles all initialization properly. **No need to call `WidgetsFlutterBinding.ensureInitialized()` manually**.

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// Import the modules you need
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  await DevPanel.init(
    () => runApp(const MyApp()),
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      const DeviceModule(),
      const PerformanceModule(),  // Automatically tracks Timers when in Zone
    ],
  );
}

// Or with custom initialization
void main() async {
  await DevPanel.init(
    () async {
      // DevPanel.init automatically calls WidgetsFlutterBinding.ensureInitialized()
      // You don't need to call it manually
      
      // Your initialization code
      await initServices();
      await setupDependencies();
      
      // Listen to environment changes
      DevPanel.environment.addListener(() {
        final apiUrl = DevPanel.environment.getString('API_URL');
        // Update your services with new URL
      });
      
      runApp(const MyApp());
    },
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
      loadFromEnvFiles: true,  // Auto-load .env files (default: true)
    ),
    modules: [
      const ConsoleModule(),
      NetworkModule(),
    ],
  );
}
```

### Method 2: Custom Zone Setup (With Sentry/Crashlytics)

For integration with error tracking services like Sentry or Firebase Crashlytics.

```dart
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize your services
    await initServices();
    
    // Initialize Dev Panel
    DevPanel.initialize(
      modules: [ConsoleModule(), NetworkModule()],
    );
    
    runApp(const MyApp());
  }, (error, stack) {
    // Send to multiple services
    DevPanel.logError('Uncaught error', error: error, stackTrace: stack);
    Sentry.captureException(error, stackTrace: stack);
  }, zoneSpecification: ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      DevPanel.log(line);  // Capture to Dev Panel
      parent.print(zone, line);    // Still print to console
    },
  ));
}
```

### Method 3: Traditional Initialization (Limited Features)

**⚠️ Warning**: This method has significant limitations:
- ❌ Does NOT capture print/debugPrint statements (Console module)
- ❌ Does NOT auto-track Timers (Performance module)
- ❌ Requires manual Zone setup for full functionality
- ⚠️ Only use if you cannot modify your app's entry point

**Note**: Console module will only show logs from direct `DevPanel.log()` calls, and Performance module cannot auto-track Timers.

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
// Import the modules you need
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dev panel with selected modules
  DevPanel.initialize(
    modules: [
      const ConsoleModule(),
      NetworkModule(),
      // Add more modules as needed
    ],
  );
  
  // Initialize environments (optional - .env files are loaded automatically)
  // You only need this if you want to provide fallback configurations
  await DevPanel.environment.initialize(
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

  runApp(MyApp());
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
          builder: (context, child) {
            return DevPanelWrapper(
              child: child ?? const SizedBox.shrink(),
            );
          },
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
- **Shake Gesture**: Shake the device (mobile only)
- **Programmatic**: `DevPanel.open(context)`

### Logging

Flutter Dev Panel provides a unified logging API:

```dart
// Simple logging
DevPanel.log('User action');
DevPanel.logInfo('Request completed');
DevPanel.logWarning('Low memory');
DevPanel.logError('Failed to load', error: e, stackTrace: s);

// Automatic print interception (when using DevPanel.init)
print('This will be captured automatically');
debugPrint('This too');

// Logger package is also captured automatically
final logger = Logger();
logger.i('Info from Logger package');
```

For detailed logging features, see 📖 [Console Module Documentation →](./packages/flutter_dev_panel_console/).

### Integration Methods

#### Using Builder Pattern (Recommended)
```dart
// Works with MaterialApp, GetMaterialApp, etc.
MaterialApp(
  builder: (context, child) {
    return DevPanelWrapper(
      child: child ?? const SizedBox.shrink(),
    );
  },
  home: MyHomePage(),
)
```

The builder pattern works with:
- GetX (`GetMaterialApp`)
- Auto Route navigation
- Apps with complex navigation setup
- Global overlay requirements

### Get Environment Variables
```dart
// Using convenience methods (recommended)
final apiUrl = DevPanel.environment.getString('api_url');
final isDebug = DevPanel.environment.getBool('debug');
final timeout = DevPanel.environment.getInt('timeout');

// Listen to environment changes
ListenableBuilder(
  listenable: DevPanel.environment,
  builder: (context, _) {
    final apiUrl = DevPanel.environment.getString('api_url');
    // UI updates automatically when environment switches
    return Text('API: $apiUrl');
  },
);
```

### Dynamic Endpoint Switching

For **Dio** (simple - can modify directly):
```dart
class ApiService {
  final dio = Dio();
  
  ApiService() {
    NetworkModule.attachToDio(dio); // Only once
    _updateConfig();
    DevPanel.environment.addListener(_updateConfig);
  }
  
  void _updateConfig() {
    // Directly modify options
    dio.options.baseUrl = DevPanel.environment.getString('api_url') ?? '';
  }
}
```

For **GraphQL** (requires recreating client):
```dart
class GraphQLService extends ChangeNotifier {
  GraphQLClient? _client;
  GraphQLClient get client => _client ?? _createClient();
  
  void initialize() {
    _client = _createClient();
    DevPanel.environment.addListener(_onEnvironmentChanged);
  }
  
  void _onEnvironmentChanged() {
    _client = _createClient(); // Recreate with new endpoint
    notifyListeners();
  }
  
  GraphQLClient _createClient() {
    final endpoint = DevPanel.environment.getString('graphql_endpoint') 
        ?? 'https://api.example.com/graphql';
    
    final httpLink = HttpLink(endpoint);
    final authLink = AuthLink(getToken: () async => 'Bearer $token');
    
    // Chain links: Auth → Monitor → HTTP
    final link = NetworkModule.createGraphQLLink(
      Link.from([authLink, httpLink]),
      endpoint: endpoint,
    );
    
    return GraphQLClient(link: link, cache: GraphQLCache());
  }
}
```

See [GraphQL Environment Switching Guide](docs/graphql_environment_switching.md) for more details.

### Network Monitoring Setup

For **Dio** (Recommended):
```dart
final dio = Dio();
NetworkModule.attachToDio(dio);  // Modifies dio directly
// Use dio as normal
```

For **GraphQL**:

Method 1 - Create with monitoring (Recommended):
```dart
// Add monitoring when creating the client
final link = NetworkModule.createGraphQLLink(
  HttpLink('https://api.example.com/graphql'),
  endpoint: 'https://api.example.com/graphql',
);

final graphQLClient = GraphQLClient(
  link: link,
  cache: GraphQLCache(),
);

// Use graphQLClient directly - no need to wrap
```

Method 2 - Wrap existing client:
```dart
// If you already have a client
GraphQLClient client = GraphQLClient(...);

// Note: GraphQL clients are immutable, so you must reassign
client = NetworkModule.wrapGraphQLClient(client);

// Now use the wrapped client
```

For **HTTP** (Alternative):
```dart
// Using interceptor pattern
final client = NetworkInterceptor.http(http.Client());
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
DevPanel.initialize(
  config: const DevPanelConfig(
    triggerModes: {
      TriggerMode.fab,
      TriggerMode.shake,
    },
    enableLogCapture: true,  // Capture print statements (default: true)
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
// Configure via module initialization
ConsoleModule(
  logConfig: const LogCaptureConfig(
    maxLogs: 1000,              // Maximum logs to keep (default: 1000)
    autoScroll: true,           // Auto-scroll to latest log (default: true)
    combineLoggerOutput: true,  // Merge Logger package multi-line output (default: true)
  ),
)

// Default configuration is usually sufficient
ConsoleModule()  // Uses default: maxLogs=1000, autoScroll=true, combineLoggerOutput=true
```

### Network Module

#### Quick Integration
```dart
// Dio
NetworkModule.attachToDio(dio);

// HTTP Package
final client = NetworkModule.createHttpClient();

// GraphQL
final link = NetworkModule.createGraphQLLink(httpLink, endpoint: endpoint);
```

#### Key Features
- **Multi-library Support**: Works with Dio, http package, and GraphQL
- **Real-time Monitoring**: Live stats in FAB (e.g., `5req/315K 300ms`)
- **GraphQL Support**: Operation name detection, query inspection
- **Smart JSON Viewer**: Collapsible tree view for complex data
- **Environment Integration**: Dynamic endpoint switching

#### GraphQL with Environment Switching
```dart
// Automatically recreate GraphQL client when environment changes
final endpoint = DevPanel.environment.getStringOr('GRAPHQL_ENDPOINT', defaultUrl);
final link = NetworkModule.createGraphQLLink(HttpLink(endpoint), endpoint: endpoint);
```

📖 [View Network Module Documentation →](./packages/flutter_dev_panel_network/) for GraphQL integration, environment switching, and advanced usage.

### Performance Module

#### Automatic Monitoring
When using `DevPanel.init()` (Method 1), the module automatically:
- Tracks all Timers via Zone interception
- Monitors FPS and memory usage
- Detects frame drops and jank
- Analyzes memory growth patterns
- Identifies resource leaks

#### Key Features
- **Timer Tracking**: View all active Timers with source location
- **Memory Analysis**: Detect leaks with growth rate calculation  
- **Resource Monitoring**: Track Timers and StreamSubscriptions
- **Interactive UI**: Expandable lists with detailed stack traces
- **Smart Detection**: Automatic identification of potential issues

**Note**: Automatic Timer tracking requires Zone setup (Method 1 or 2). With Method 3, only manual tracking is available.

📖 [View Performance Module Documentation →](./packages/flutter_dev_panel_performance/) for detailed API usage, Timer tracking examples, and memory analysis features.

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

The dev panel has multiple layers of protection for production builds:

#### 1. Default Behavior
- **Debug mode**: Automatically enabled
- **Release mode**: Automatically disabled (code removed by tree shaking)

#### 2. Force Enable in Production
For internal testing builds, you can enable the panel in release mode:

```bash
# Build with dev panel enabled in release mode
flutter build apk --release --dart-define=FORCE_DEV_PANEL=true

# CI/CD example
flutter build ios --release \
  --dart-define=FORCE_DEV_PANEL=true \
  --dart-define=API_KEY=${{ secrets.API_KEY }}
```

#### 3. API Protection
All public APIs check compile-time constants:
- APIs become no-op in release mode (unless `FORCE_DEV_PANEL=true`)
- Tree-shaking removes unused code automatically
- Zero runtime overhead in production

#### 4. Zero Overhead in Production
When not forced in release builds:
- No UI components are rendered
- No logs are captured  
- No performance monitoring
- Code is completely removed by tree-shaking
- No impact on app size or performance

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