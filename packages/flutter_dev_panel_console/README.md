# Flutter Dev Panel - Console Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_console.svg)](https://pub.dev/packages/flutter_dev_panel_console)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

A comprehensive logging and console module for Flutter Dev Panel that provides zero-configuration log capture, filtering, and management capabilities for Flutter applications.

## Features

### Log Capture
- **Automatic capture** of `print` and `debugPrint` statements
- **Logger package integration** - Works out of the box with the popular Logger package
- **Flutter framework errors** - Captures all Flutter errors and exceptions
- **Async error handling** - Catches unhandled asynchronous errors
- **Smart source detection** - Automatically identifies and tags log sources

### Log Viewing
- **Real-time search** - Filter logs by content instantly
- **Level filtering** - Filter by Verbose, Debug, Info, Warning, and Error levels
- **Color-coded levels** - Visual distinction between different log severities
- **Timestamp display** - Precise timing information for each log entry
- **Pause/Resume** - Control log collection in real-time
- **Auto-scroll** - Automatically scrolls to latest logs (configurable)
- **Detail view** - Tap to expand and view full log details including stack traces

### Configuration
- **Flexible capture options** - Fine-grained control over what gets logged
- **Preset modes** - Minimal, Development, and Full capture modes
- **Persistent settings** - Configuration survives app restarts
- **Runtime adjustable** - Change settings without restarting the app

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_dev_panel_console:
    git:
      url: https://github.com/yourusername/flutter_dev_panel
      path: packages/flutter_dev_panel_console
```

Or if using a local path:

```yaml
dependencies:
  flutter_dev_panel_console:
    path: ../packages/flutter_dev_panel_console
```

## Usage

### Basic Setup

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';

void main() {
  runZonedGuarded(() async {
    // Initialize with console module
    FlutterDevPanel.initialize(
      modules: [
        const ConsoleModule(),
        // Add other modules as needed
      ],
      enableLogCapture: true,
    );
    
    runApp(MyApp());
  }, (error, stack) {
    // Errors are automatically captured
    DevLogger.instance.error('Uncaught error', error: error, stackTrace: stack);
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      // Capture print statements
      DevLogger.instance.info('[Print] $line');
      parent.print(zone, line);
    },
  ));
}
```

### Configuration Options

#### Using Preset Configurations

```dart
// Minimal mode - maxLogs: 500, autoScroll: true
DevLogger.instance.updateConfig(
  const LogCaptureConfig.minimal(),
);

// Development mode - maxLogs: 1000, autoScroll: true (default)
DevLogger.instance.updateConfig(
  const LogCaptureConfig.development(),
);

// Full mode - maxLogs: 5000, autoScroll: true
DevLogger.instance.updateConfig(
  const LogCaptureConfig.full(),
);

```

#### Custom Configuration

```dart
DevLogger.instance.updateConfig(
  const LogCaptureConfig(
    maxLogs: 1000,                // Maximum number of logs to keep
    autoScroll: true,             // Auto-scroll to latest logs
    combineLoggerOutput: true,    // Combine multi-line Logger package output
  ),
);
```

### Logger Package Integration

The console module automatically captures output from the Logger package:

```dart
import 'package:logger/logger.dart';

final logger = Logger();

// All these are automatically captured
logger.t('Trace message');
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: exception, stackTrace: stack);
```

### Manual Logging

You can also use the DevLogger directly:

```dart
// Different log levels
DevLogger.instance.verbose('Detailed trace information');
DevLogger.instance.debug('Debug information');
DevLogger.instance.info('General information');
DevLogger.instance.warning('Warning message');
DevLogger.instance.error('Error occurred', error: exception, stackTrace: stack);

// With source tagging
DevLogger.instance.info('[Network] Request completed');
DevLogger.instance.error('[Database] Query failed', error: error);
```

## API Reference

### ConsoleModule

The main module class that integrates with Flutter Dev Panel:

```dart
class ConsoleModule extends DevModule {
  const ConsoleModule();
  
  @override
  Widget buildPage(BuildContext context);
  
  @override
  Widget? buildFabContent(BuildContext context);
}
```

### LogCaptureConfig

Configuration for log capture behavior:

```dart
class LogCaptureConfig {
  final bool captureFrameworkLogs;
  final bool captureNetworkLogs;
  final bool captureSystemLogs;
  final bool captureLibraryLogs;
  final bool captureVerbose;
  final bool captureAllErrors;
  final int maxLogs;
  
  const LogCaptureConfig({...});
  
  // Preset configurations
  const LogCaptureConfig.minimal();
  const LogCaptureConfig.development();
  const LogCaptureConfig.full();
}
```

### DevLogger

The singleton logger instance:

```dart
class DevLogger {
  static DevLogger get instance;
  
  void verbose(String message, {dynamic error, StackTrace? stackTrace});
  void debug(String message, {dynamic error, StackTrace? stackTrace});
  void info(String message, {dynamic error, StackTrace? stackTrace});
  void warning(String message, {dynamic error, StackTrace? stackTrace});
  void error(String message, {dynamic error, StackTrace? stackTrace});
  
  void updateConfig(LogCaptureConfig config);
  void clearLogs();
  void setPaused(bool paused);
}
```

## Log Source Identification

The console module automatically detects and formats logs from different sources:

- **Print statements** - Standard print output
- **debugPrint** - Debug print statements
- **Logger package** - Multi-line output automatically combined
- **Flutter errors** - Framework errors and exceptions
- **Custom prefixes** - Logs with `Error:`, `Warning:`, `Info:`, etc. are auto-detected

## Performance Considerations

Different configuration modes have different memory impacts:

| Mode | Max Logs | Use Case |
|------|----------|----------|
| Minimal | 500 | Limited memory, basic debugging |
| Development | 1000 | Daily development, balanced features |
| Full | 5000 | Debugging complex issues, complete history |

## Best Practices

1. **Use appropriate log levels** - Use error for errors, warning for warnings, etc.
2. **Add context to logs** - Include relevant information to help debugging
3. **Configure for your needs** - Use minimal mode for performance, full for debugging
4. **Clean up verbose logs** - Remove unnecessary verbose logging in production
5. **Use source tags** - Tag logs with `[Network]`, `[Database]`, etc. for clarity

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please file an issue on the [GitHub repository](https://github.com/yourusername/flutter_dev_panel/issues).