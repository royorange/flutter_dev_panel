# Flutter Dev Panel - Performance Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_performance.svg)](https://pub.dev/packages/flutter_dev_panel_performance)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

Performance monitoring module for Flutter Dev Panel that provides real-time FPS tracking, memory monitoring, and performance visualization.

## Features

- **FPS tracking** - Real-time frames per second monitoring
- **Memory usage** - Track app memory consumption
- **Jank detection** - Identify and highlight frame drops
- **Live charts** - Real-time performance graphs
- **Performance history** - Historical data with charts
- **FAB display** - Shows FPS, memory usage, and jank warnings

## Installation

```yaml
dependencies:
  flutter_dev_panel_performance:
    path: ../packages/flutter_dev_panel_performance
```

## Usage

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

void main() {
  // Initialize with performance module
  FlutterDevPanel.initialize(
    modules: [PerformanceModule()],
  );
  
  runApp(MyApp());
}

// Access performance data
final controller = PerformanceMonitorController.instance;
controller.startMonitoring();

// Get current metrics
final currentFPS = controller.currentFPS;
final memoryUsage = controller.memoryUsageMB;
final isJanky = controller.isJanky;

// Listen to updates
controller.addListener(() {
  print('FPS: ${controller.currentFPS}');
  print('Memory: ${controller.memoryUsageMB} MB');
});
```


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.