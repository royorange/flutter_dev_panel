# Flutter Dev Panel - Performance Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_performance.svg)](https://pub.dev/packages/flutter_dev_panel_performance)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

A comprehensive performance monitoring module for Flutter Dev Panel that provides real-time FPS tracking, memory monitoring, resource leak detection, and automatic Timer tracking.

## Features

### Core Monitoring
- **Real-time FPS Tracking** - Monitor frames per second with instant visual feedback
- **Memory Usage Monitoring** - Track app memory consumption and detect memory leaks
- **Jank Detection** - Identify and highlight frame drops
- **Live Performance Charts** - Real-time visualization of performance metrics
- **Performance History** - Historical data with interactive charts
- **FAB Display** - Shows FPS, memory usage with trend indicators, and performance warnings

### Resource Leak Detection
- **Memory Growth Analysis** - Detect memory leaks with intelligent threshold detection
- **Timer Tracking** - Automatic or manual tracking of active Timers
- **StreamSubscription Monitoring** - Track uncanceled stream subscriptions
- **Smart Analysis** - Actionable advice for detected issues

### Enhanced Timer Tracking (New!)
- **Automatic Timer Tracking** - Zero-configuration Timer interception via Zone API
- **Detailed Timer Information** - View source location, type, creation time, and stack trace
- **Interactive Timer List** - Expandable list with detailed information for each Timer
- **Manual Tracking Support** - Selectively track important Timers when auto-tracking is disabled

## Installation

```yaml
dependencies:
  flutter_dev_panel: ^latest_version
  flutter_dev_panel_performance: ^latest_version
```

## Quick Start

### Basic Setup with DevPanel.init() (Recommended)

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

void main() async {
  // Automatic Zone setup for print and Timer interception
  await DevPanel.init(
    () => runApp(MyApp()),
    modules: [
      PerformanceModule(
        autoTrackTimers: true,  // Enable automatic Timer tracking (default: true)
      ),
      // Other modules...
    ],
  );
}
```

### Alternative Setup with DevPanel.initialize()

```dart
void main() {
  runZonedGuarded(() {
    DevPanel.initialize(
      modules: [
        PerformanceModule(
          autoTrackTimers: true,
        ),
      ],
    );
    runApp(MyApp());
  }, (error, stack) {
    // Error handling
  }, zoneSpecification: DevPanel.get().performance?.createZoneSpecification());
}
```

## API Usage

### Starting and Stopping Monitoring

```dart
// Start monitoring
DevPanel.get().performance?.startMonitoring();

// Start with custom auto-tracking setting
DevPanel.get().performance?.startMonitoring(
  enableAutoTracking: false,  // Override module configuration
);

// Stop monitoring
DevPanel.get().performance?.stopMonitoring();

// Check monitoring status
final isMonitoring = DevPanel.get().performance?.isMonitoring ?? false;

// Clear all data
DevPanel.get().performance?.clearData();
```

### Accessing Performance Metrics

```dart
// Get current metrics
final fps = DevPanel.get().performance?.currentFps ?? 0.0;
final memory = DevPanel.get().performance?.currentMemory ?? 0.0;
final peakMemory = DevPanel.get().performance?.peakMemory ?? 0.0;
final droppedFrames = DevPanel.get().performance?.droppedFrames ?? 0;
final renderTime = DevPanel.get().performance?.renderTime ?? 0.0;

// Check for potential memory leaks
final hasLeak = DevPanel.get().performance?.hasPotentialLeak ?? false;

// Get memory status summary
final memorySummary = DevPanel.get().performance?.memorySummary ?? '';
// Returns: "Memory stable" or "Memory growing: 5.2 MB/min"

// Get resource summary
final resourceSummary = DevPanel.get().performance?.resourceSummary ?? '';
// Returns: "Timers: 3, Subscriptions: 2"
```

### Timer Tracking

#### Automatic Tracking (Default)

When `autoTrackTimers` is enabled (default), all Timers are automatically tracked:

```dart
// All these Timers are automatically tracked
Timer(Duration(seconds: 5), () {
  print('One-time timer');
});

Timer.periodic(Duration(seconds: 1), (timer) {
  print('Periodic timer');
  if (timer.tick >= 10) timer.cancel();
});

Future.delayed(Duration(seconds: 2), () {
  print('Future.delayed creates a Timer internally');
});

Timer.run(() {
  print('Immediate execution');
});
```

#### Manual Tracking

When automatic tracking is disabled or for selective tracking:

```dart
// Configure module with auto-tracking disabled
PerformanceModule(
  autoTrackTimers: false,
)

// Manually track specific Timers
final timer = Timer.periodic(Duration(seconds: 30), (_) {
  refreshData();
});
DevPanel.get().performance?.trackTimer(timer);

// Track StreamSubscriptions
final subscription = stream.listen((data) {
  processData(data);
});
DevPanel.get().performance?.trackSubscription(subscription);
```

### Resource Statistics

```dart
// Get detailed resource statistics
final stats = DevPanel.get().performance?.resourceStats;
print('Total Timers: ${stats?['totalTimers']}');
print('Auto-tracked: ${stats?['autoTrackedTimers']}');
print('Manual-tracked: ${stats?['manualTrackedTimers']}');
print('Subscriptions: ${stats?['subscriptions']}');

// Get active counts
final timerCount = DevPanel.get().performance?.activeTimerCount ?? 0;
final subscriptionCount = DevPanel.get().performance?.activeSubscriptionCount ?? 0;
```

### Memory Analysis

```dart
// Analyze memory growth
final analysis = DevPanel.get().performance?.analyzeMemoryGrowth();
if (analysis != null) {
  print('Growing: ${analysis.isGrowing}');
  print('Rate: ${analysis.growthRateMBPerMinute} MB/min');
  print('Suggestion: ${analysis.suggestion}');
}

// Get debug information
final debugInfo = DevPanel.get().performance?.getDebugInfo();
print('Debug info: $debugInfo');
```

## UI Features

### Performance Monitor Page

The Performance module provides a comprehensive UI with three tabs:

1. **Metrics Tab**
   - Real-time FPS and memory graphs
   - Current performance metrics
   - Visual indicators for performance issues
   - Centered play button when monitoring is stopped

2. **Analysis Tab**
   - Memory growth detection with visual status
   - Resource leak detection (Timers and Subscriptions)
   - **Expandable Timer list with detailed information**
     - Shows Timer location, type, and age
     - Click on any Timer to view full details including stack trace
   - Actionable advice for detected issues

3. **History Tab**
   - Historical performance data
   - Interactive charts
   - Performance trends over time

### FAB Integration

When monitoring is active, the FAB displays:
- Current FPS with color coding (green/yellow/red)
- Memory usage with trend arrows (↑/↓)
- Frame drop warnings

### Visual Indicators

- **Recording Indicator**: Flashing red dot in AppBar when monitoring
- **Memory Trends**: Up/down arrows showing memory growth/decline
- **Color Coding**: 
  - Green: Good performance
  - Yellow: Warning
  - Red: Critical issue

## Timer Information Details

When automatic tracking is enabled, each Timer provides:

- **Location**: Source file and line number (e.g., `main.dart:42`)
- **Type**: One-time or Periodic
- **Creation Time**: When the Timer was created
- **Age**: How long the Timer has been active
- **Stack Trace**: Full call stack for debugging (in detail view)
- **Active Status**: Whether the Timer is still running

## Configuration Options

### PerformanceModule Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `autoTrackTimers` | `bool` | `true` | Enable automatic Timer tracking via Zone |

### startMonitoring Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enableAutoTracking` | `bool?` | `null` | Override module's autoTrackTimers setting |

## Best Practices

### 1. Use DevPanel.init() for Easy Setup
```dart
void main() async {
  await DevPanel.init(
    () => runApp(MyApp()),
    modules: [PerformanceModule()],
  );
}
```

### 2. Always Cancel Timers in dispose()
```dart
@override
void dispose() {
  _timer?.cancel();
  _subscription?.cancel();
  super.dispose();
}
```

### 3. Monitor Memory Growth During Development
- Watch for continuously growing memory
- Check Timer count doesn't increase indefinitely
- Verify StreamSubscriptions are properly canceled

### 4. Use Thresholds Appropriately
- Debug mode: 2 MB/min growth threshold (more tolerant)
- Release mode: 0.5 MB/min growth threshold (stricter)

## How Auto-Tracking Works

The automatic Timer tracking uses Dart's Zone API to intercept Timer creation:

1. **Zone Setup**: `DevPanel.init()` creates a Zone with Timer interceptors
2. **Timer Interception**: All Timer creation within the Zone is captured
3. **Automatic Cleanup**: Completed Timers are automatically removed
4. **Zero Overhead**: Only active in Debug mode, no production impact

## Common Issues and Solutions

### Q: Why does Timer count show 0?

**Possible causes:**
1. Auto-tracking not enabled (check `autoTrackTimers` configuration)
2. Timers created outside the Zone (ensure Zone setup before `runApp()`)
3. No active Timers in the application

**Solution:**
```dart
// Ensure proper initialization order
await DevPanel.init(
  () => runApp(MyApp()),  // App runs inside Zone
  modules: [PerformanceModule(autoTrackTimers: true)],
);
```

### Q: Can I use both automatic and manual tracking?

**Yes!** Both methods can be used simultaneously:
```dart
// Auto-tracking captures all Timers
PerformanceModule(autoTrackTimers: true)

// Still manually track critical Timers for special attention
final criticalTimer = Timer.periodic(Duration(minutes: 1), (_) {
  performCriticalTask();
});
DevPanel.get().performance?.trackTimer(criticalTimer);
```

### Q: How to detect Timer leaks?

**Look for these signs:**
1. Timer count continuously increasing
2. "High number of active timers" warning in Analysis tab
3. Expandable Timer list shows old Timers that should have been canceled

**Example of a Timer leak:**
```dart
// ❌ BAD: Timer not canceled in dispose
class BadWidget extends StatefulWidget {
  @override
  _BadWidgetState createState() => _BadWidgetState();
}

class _BadWidgetState extends State<BadWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      // Do something
    });
  }
  
  @override
  void dispose() {
    // ❌ Forgot to call: _timer?.cancel();
    super.dispose();
  }
}
```

## Performance Impact

- **Debug Mode Only**: All tracking is disabled in Release mode
- **Minimal Overhead**: Zone interception has negligible performance impact
- **WeakReference**: Manual tracking uses weak references, no memory leaks
- **Automatic Cleanup**: Inactive resources are automatically removed

## Requirements

- Flutter ≥3.10.0
- Dart ≥3.0.0
- flutter_dev_panel (core package)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please visit the [GitHub repository](https://github.com/your-repo/flutter_dev_panel).