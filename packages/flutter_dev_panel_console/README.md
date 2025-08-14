# Flutter Dev Panel - Console Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_console.svg)](https://pub.dev/packages/flutter_dev_panel_console)

Console/Logs monitoring module for Flutter Dev Panel.

## Features

- Automatic capture of print, debugPrint, and Logger package output
- Log level filtering (verbose, debug, info, warning, error)
- Search and filter capabilities
- Smart multi-line log merging for Logger package
- Configurable log retention and auto-scroll
- FAB display with error/warning count

## Installation

```yaml
dependencies:
  flutter_dev_panel: ^0.0.1
  flutter_dev_panel_console: ^0.0.1
```

## Usage

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';

void main() {
  FlutterDevPanel.initialize(
    modules: [
      ConsoleModule(),
      // Other modules...
    ],
  );

  runApp(
    DevPanelWrapper(
      child: MyApp(),
    ),
  );
}
```

## Log Capture

The console module automatically captures:
- Standard `print()` statements
- `debugPrint()` output
- Logger package logs (with smart multi-line merging)
- Flutter framework errors

## Logger Package Integration

Flutter Dev Panel Console now includes built-in support for the [logger](https://pub.dev/packages/logger) package with zero configuration needed!

### Simple Usage

```dart
import 'package:logger/logger.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';

final logger = Logger(
  output: DevPanelLoggerOutput(), // That's it!
  printer: PrettyPrinter(),
);

// Use logger as normal - logs appear in both console AND Dev Panel!
logger.i("Info message");
logger.e("Error message", error: exception, stackTrace: stack);
```

### Using Extension Method

```dart
final logger = Logger(
  output: ConsoleOutput().withDevPanel(), // Add Dev Panel capture to any LogOutput
  printer: PrettyPrinter(),
);
```

### Advanced Usage

```dart
// With custom base output
final logger = Logger(
  output: DevPanelLoggerOutput(
    baseOutput: MultiOutput([
      ConsoleOutput(),
      FileOutput(),
    ]),
  ),
);

// Or wrap any existing LogOutput
final logger = Logger(
  output: FileOutput().withDevPanel(),
);

Features:
- **Type-safe**: Properly extends LogOutput
- **Debug mode**: Logs appear in both console AND Dev Panel
- **Release mode**: Only outputs to console (zero overhead)
- **Customizable**: Can pass any LogOutput as base

## Configuration

```dart
// Configure log capture settings
DevLogger.instance.updateConfig(
  maxLogs: 500,        // Maximum logs to keep
  autoScroll: true,    // Auto-scroll to latest log
  pauseOnError: true,  // Pause auto-scroll on error
);
```

## License

MIT