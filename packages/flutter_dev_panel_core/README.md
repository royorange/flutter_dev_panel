# Flutter Dev Panel Core

Core framework for Flutter Dev Panel - A modular, zero-intrusion debugging panel for Flutter applications.

**⚠️ Note: This is an internal package. Users should install the main `flutter_dev_panel` package instead.**

## Features

- 🔌 **Modular Architecture** - Load only the modules you need
- 🎨 **Theme Management** - Built-in theme switcher with persistence
- 🌍 **Environment Management** - Switch between dev/prod environments
- 📝 **Log Capture** - Comprehensive logging system with Zone-based interception
- 📊 **Data Provider** - Centralized monitoring data management
- 🎯 **Zero Intrusion** - No impact on production code

## Installation

**For end users, please use the main package:**

```yaml
dependencies:
  flutter_dev_panel: ^1.0.0
```

This core package is automatically included as a dependency.

## Quick Start

```dart
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';

void main() {
  // Initialize environment
  EnvironmentManager.instance.initialize(
    environments: [
      const EnvironmentConfig(
        name: 'Development',
        variables: {'api_url': 'https://dev-api.example.com'},
        isDefault: true,
      ),
      const EnvironmentConfig(
        name: 'Production',
        variables: {'api_url': 'https://api.example.com'},
      ),
    ],
  );

  // Initialize dev panel (using the main package)
  FlutterDevPanel.initialize(
    config: const DevPanelConfig(
      enabled: true,
      triggerModes: {TriggerMode.fab, TriggerMode.shake},
    ),
    modules: [
      // Add your modules here
    ],
    enableLogCapture: true,
  );

  // Run app with Zone-based log capture
  runZonedGuarded(
    () => runApp(DevPanelWrapper(child: MyApp())),
    (error, stack) => DevLogger.instance.error('Error', error: error),
  );
}
```

## Core Components

### 1. Module System

Create custom modules by extending `DevModule`:

```dart
class MyCustomModule extends DevModule {
  @override
  String get name => 'Custom';
  
  @override
  IconData get icon => Icons.settings;
  
  @override
  Widget buildPage(BuildContext context) {
    return YourCustomPage();
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // Optional: Return widget to show in FAB
    return Text('Status');
  }
}
```

### 2. Environment Management

```dart
// Switch environment
EnvironmentManager.instance.switchEnvironment('Production');

// Get environment variable
final apiUrl = EnvironmentManager.instance.getVariable<String>('api_url');

// Listen to changes
EnvironmentManager.instance.addListener(() {
  // Update your configuration
});
```

### 3. Theme Management

```dart
// Add custom theme
ThemeManager.instance.addCustomTheme(
  name: 'Custom',
  mode: ThemeMode.light,
  primaryColor: Colors.blue,
);

// Integrate with MaterialApp
MaterialApp(
  themeMode: ThemeManager.instance.currentTheme.mode,
  theme: ThemeManager.instance.getThemeData(context),
)
```

### 4. Log Capture (DevLogger)

```dart
// Log messages
DevLogger.instance.info('Info message');
DevLogger.instance.warning('Warning');
DevLogger.instance.error('Error', error: exception, stackTrace: stack);

// Configure log capture
DevLogger.instance.updateConfig(
  LogCaptureConfig(
    maxLogs: 1000,
    autoScroll: true,
    combineLoggerOutput: true,
  ),
);

// Pause/Resume
DevLogger.instance.pauseCapture();
DevLogger.instance.resumeCapture();
```

### 5. Monitoring Data Provider

```dart
// Update monitoring data
MonitoringDataProvider.instance.updatePerformanceData(
  fps: 60.0,
  memory: 120.5,
);

// Listen to changes
MonitoringDataProvider.instance.addListener(() {
  // Update UI
});
```

## Configuration Options

```dart
DevPanelConfig(
  enabled: true,                    // Enable/disable panel
  triggerModes: {                   // How to open the panel
    TriggerMode.fab,               // Floating action button
    TriggerMode.shake,             // Shake device
    TriggerMode.manual,            // Programmatic only
  },
  showInProduction: false,         // Hide in production builds
  animationDuration: Duration(milliseconds: 300),
)
```

## Access Methods

### 1. Floating Action Button (FAB)
A draggable button appears on screen. Tap to open the panel.

### 2. Shake Detection
Shake the device to open the panel (physical devices only).

### 3. Programmatic
```dart
DevPanelController.instance.open();
```

## Persistence

The following data is automatically persisted:
- Current environment selection
- Theme preferences  
- Log capture settings
- Custom configurations

## Best Practices

1. **Initialize Early** - Set up environments and themes before `runApp()`
2. **Use Zones** - Wrap your app with `runZonedGuarded` for complete error capture
3. **Module Loading** - Only load modules you need to minimize overhead
4. **Production Safety** - Use `showInProduction: false` in config

## Requirements

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0

## License

MIT License - see LICENSE file for details