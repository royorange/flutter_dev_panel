# Flutter Dev Panel - Performance Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_performance.svg)](https://pub.dev/packages/flutter_dev_panel_performance)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

A comprehensive performance monitoring module for Flutter Dev Panel that provides real-time FPS tracking, memory monitoring, and performance metrics visualization.

## Features

### Performance Monitoring
- **FPS tracking** - Real-time frames per second monitoring
- **Memory usage** - Track app memory consumption and available memory
- **CPU usage** - Monitor CPU utilization (platform-dependent)
- **Battery monitoring** - Battery level and charging status
- **Performance history** - Historical data with charts and graphs

### Visualization
- **Live charts** - Real-time updating performance graphs
- **FPS graph** - Visual representation of frame rate over time
- **Memory chart** - Memory usage trends and patterns
- **Statistics cards** - Current, average, min, and max values
- **Performance indicators** - Color-coded performance status

### Performance Analysis
- **Jank detection** - Identify and highlight frame drops
- **Memory leak detection** - Monitor for unusual memory patterns
- **Performance thresholds** - Configurable warning levels
- **Export capabilities** - Export performance data for analysis

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_dev_panel_performance:
    git:
      url: https://github.com/yourusername/flutter_dev_panel
      path: packages/flutter_dev_panel_performance
```

Or if using a local path:

```yaml
dependencies:
  flutter_dev_panel_performance:
    path: ../packages/flutter_dev_panel_performance
```

## Usage

### Basic Setup

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

void main() {
  // Initialize with performance module
  FlutterDevPanel.initialize(
    modules: [
      PerformanceModule(),
      // Add other modules as needed
    ],
  );
  
  runApp(MyApp());
}
```

### Accessing Performance Data

```dart
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

// Get performance monitor controller
final controller = PerformanceMonitorController.instance;

// Start monitoring
controller.startMonitoring();

// Access current performance data
final currentFPS = controller.currentFPS;
final memoryUsage = controller.memoryUsageMB;
final isJanky = controller.isJanky;

// Listen to performance updates
controller.addListener(() {
  print('FPS: ${controller.currentFPS}');
  print('Memory: ${controller.memoryUsageMB} MB');
});

// Stop monitoring
controller.stopMonitoring();
```

### Custom FPS Tracking

```dart
// Create FPS tracker
final fpsTracker = FPSTracker();

// Start tracking
fpsTracker.start();

// Get current FPS
final fps = fpsTracker.currentFPS;

// Listen to FPS updates
fpsTracker.fpsStream.listen((fps) {
  print('Current FPS: $fps');
  if (fps < 30) {
    print('Warning: Low FPS detected!');
  }
});

// Stop tracking
fpsTracker.stop();
```

## API Reference

### PerformanceModule

The main module class that integrates with Flutter Dev Panel:

```dart
class PerformanceModule extends DevModule {
  @override
  String get name => 'Performance';
  
  @override
  IconData get icon => Icons.speed;
  
  @override
  Widget buildPage(BuildContext context);
  
  @override
  Widget? buildFabContent(BuildContext context);
}
```

### PerformanceMonitorController

Controls performance monitoring and data collection:

```dart
class PerformanceMonitorController extends ChangeNotifier {
  static PerformanceMonitorController get instance;
  
  // Current metrics
  double get currentFPS;
  double get averageFPS;
  double get minFPS;
  double get maxFPS;
  
  double get memoryUsageMB;
  double get memoryUsagePercent;
  
  bool get isMonitoring;
  bool get isJanky;
  
  // Control methods
  void startMonitoring();
  void stopMonitoring();
  void reset();
  
  // Data access
  List<PerformanceData> get performanceHistory;
  Stream<PerformanceData> get performanceStream;
  
  // Configuration
  void setHistoryLimit(int limit);
  void setJankThreshold(double fps);
}
```

### PerformanceData

Contains performance metrics at a point in time:

```dart
class PerformanceData {
  final DateTime timestamp;
  final double fps;
  final double memoryUsageMB;
  final double cpuUsage; // Platform-dependent
  final double batteryLevel;
  final bool isCharging;
  
  bool get isJanky => fps < 55.0;
  bool get isLowMemory => memoryUsageMB > 500;
}
```

### FPSTracker

Dedicated FPS tracking utility:

```dart
class FPSTracker {
  double get currentFPS;
  double get averageFPS;
  Stream<double> get fpsStream;
  
  void start();
  void stop();
  void reset();
}
```

## Performance Metrics

### FPS (Frames Per Second)

```dart
// Monitor FPS
controller.performanceStream.listen((data) {
  if (data.fps < 60) {
    print('Frame drop detected: ${data.fps} FPS');
  }
  
  if (data.fps < 30) {
    print('Severe performance issue: ${data.fps} FPS');
  }
});

// FPS thresholds
// 60 FPS - Excellent (smooth)
// 30-59 FPS - Good (minor jank)
// <30 FPS - Poor (noticeable jank)
```

### Memory Usage

```dart
// Monitor memory
controller.performanceStream.listen((data) {
  final memoryMB = data.memoryUsageMB;
  
  if (memoryMB > 500) {
    print('High memory usage: ${memoryMB} MB');
  }
  
  // Check for memory leaks
  if (controller.isMemoryIncreasing()) {
    print('Possible memory leak detected');
  }
});
```

### Jank Detection

```dart
// Configure jank threshold
controller.setJankThreshold(55.0); // FPS below 55 is considered janky

// Monitor jank
controller.addListener(() {
  if (controller.isJanky) {
    print('Jank detected!');
    // Log or handle jank event
  }
});
```

## Visualization Widgets

### FPS Chart

```dart
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

class PerformanceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FPSChart(
      data: controller.performanceHistory,
      height: 200,
      showAverage: true,
      showThreshold: true,
      thresholdValue: 55.0,
    );
  }
}
```

### Memory Chart

```dart
MemoryChart(
  data: controller.performanceHistory,
  height: 200,
  showMax: true,
  warningLevel: 500, // MB
  criticalLevel: 700, // MB
)
```

### Performance Stats Card

```dart
PerformanceStatsCard(
  title: 'FPS',
  current: controller.currentFPS,
  average: controller.averageFPS,
  min: controller.minFPS,
  max: controller.maxFPS,
  unit: 'fps',
  goodThreshold: 55,
  warningThreshold: 30,
)
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

void main() {
  FlutterDevPanel.initialize(
    modules: [PerformanceModule()],
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterDevPanel.wrap(
      child: MaterialApp(
        title: 'Performance Demo',
        home: PerformanceDemo(),
      ),
    );
  }
}

class PerformanceDemo extends StatefulWidget {
  @override
  _PerformanceDemoState createState() => _PerformanceDemoState();
}

class _PerformanceDemoState extends State<PerformanceDemo> {
  final controller = PerformanceMonitorController.instance;
  
  @override
  void initState() {
    super.initState();
    controller.startMonitoring();
    controller.addListener(_update);
  }
  
  @override
  void dispose() {
    controller.removeListener(_update);
    controller.stopMonitoring();
    super.dispose();
  }
  
  void _update() {
    setState(() {});
  }
  
  void _simulateHeavyWork() {
    // Simulate heavy computation
    for (int i = 0; i < 1000000; i++) {
      final result = i * i;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performance Monitor'),
        actions: [
          IconButton(
            icon: Icon(controller.isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (controller.isMonitoring) {
                controller.stopMonitoring();
              } else {
                controller.startMonitoring();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: controller.reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Performance stats
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'FPS',
                  controller.currentFPS.toStringAsFixed(1),
                  controller.isJanky ? Colors.red : Colors.green,
                ),
                _buildStatCard(
                  'Memory',
                  '${controller.memoryUsageMB.toStringAsFixed(1)} MB',
                  controller.memoryUsagePercent > 80 ? Colors.orange : Colors.blue,
                ),
              ],
            ),
          ),
          
          // FPS Chart
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: FPSChart(
                data: controller.performanceHistory,
                showAverage: true,
                showThreshold: true,
              ),
            ),
          ),
          
          // Memory Chart
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: MemoryChart(
                data: controller.performanceHistory,
                showMax: true,
              ),
            ),
          ),
          
          // Test buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _simulateHeavyWork,
                  child: Text('Simulate Heavy Work'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Create memory pressure
                    List<List<int>> memoryHog = [];
                    for (int i = 0; i < 100; i++) {
                      memoryHog.add(List.generate(100000, (i) => i));
                    }
                    Future.delayed(Duration(seconds: 2), () {
                      memoryHog.clear();
                    });
                  },
                  child: Text('Simulate Memory Pressure'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Performance Optimization Tips

### Improving FPS

```dart
// Use RepaintBoundary to isolate expensive widgets
RepaintBoundary(
  child: ExpensiveWidget(),
)

// Use const constructors where possible
const MyWidget()

// Avoid rebuilding entire widget tree
ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) {
    return Text('$value');
  },
)
```

### Memory Management

```dart
// Dispose controllers and listeners
@override
void dispose() {
  controller.dispose();
  streamSubscription.cancel();
  super.dispose();
}

// Clear caches when appropriate
imageCache.clear();
imageCache.clearLiveImages();

// Use weak references for callbacks
final weakRef = WeakReference(this);
callback = () {
  weakRef.target?.handleCallback();
};
```

## Configuration

### Performance Thresholds

```dart
// Configure monitoring thresholds
PerformanceMonitorController.instance.configure(
  PerformanceConfig(
    jankThreshold: 55.0,        // FPS below this is janky
    memoryWarningMB: 500,        // Memory warning level
    memoryCriticalMB: 700,       // Memory critical level
    historyLimit: 100,           // Number of data points to keep
    samplingInterval: Duration(milliseconds: 500),
  ),
);
```

### Export Performance Data

```dart
// Export performance history
final data = controller.exportData();
await File('performance_log.json').writeAsString(data);

// Export as CSV
final csv = controller.exportAsCSV();
await File('performance_log.csv').writeAsString(csv);
```

## Platform Considerations

### iOS
- FPS tracking uses CADisplayLink for accuracy
- Memory usage from `os_proc_available_memory`
- Battery monitoring requires device (not simulator)

### Android
- FPS tracking uses Choreographer API
- Memory info from ActivityManager
- CPU usage available through /proc/stat

### Web
- FPS tracking using requestAnimationFrame
- Memory API limited (performance.memory)
- Battery API may require permissions

### Desktop
- FPS tracking platform-specific
- Full system memory access
- CPU monitoring available

## Best Practices

1. **Monitor in development** - Use performance monitoring during development to catch issues early
2. **Set realistic thresholds** - Configure thresholds based on your app's requirements
3. **Profile on real devices** - Performance characteristics differ between devices
4. **Clean up monitoring** - Stop monitoring when not needed to avoid overhead
5. **Export and analyze** - Export data for detailed analysis and comparison

## Troubleshooting

### FPS not updating
- Ensure monitoring is started
- Check if app is in foreground
- Verify Flutter is in debug or profile mode

### Memory readings incorrect
- Memory values are estimates
- Platform differences in measurement
- Consider garbage collection timing

### High performance overhead
- Reduce sampling frequency
- Limit history size
- Disable unused metrics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please file an issue on the [GitHub repository](https://github.com/yourusername/flutter_dev_panel/issues).