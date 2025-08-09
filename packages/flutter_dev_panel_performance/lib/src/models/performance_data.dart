import 'dart:collection';

class PerformanceData {
  final DateTime timestamp;
  final double fps;
  final double memoryUsage;
  final int? batteryLevel;  // Battery percentage (0-100)
  final String? batteryState;  // charging, discharging, full, etc.

  PerformanceData({
    required this.timestamp,
    required this.fps,
    required this.memoryUsage,
    this.batteryLevel,
    this.batteryState,
  });
}

class PerformanceMetrics {
  final Queue<PerformanceData> dataPoints;
  final int maxDataPoints;

  PerformanceMetrics({this.maxDataPoints = 60})
      : dataPoints = Queue<PerformanceData>();

  void addDataPoint(PerformanceData data) {
    dataPoints.addLast(data);
    if (dataPoints.length > maxDataPoints) {
      dataPoints.removeFirst();
    }
  }

  double get averageFps {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.fps).reduce((a, b) => a + b) /
        dataPoints.length;
  }

  double get minFps {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.fps).reduce((a, b) => a < b ? a : b);
  }

  double get maxFps {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.fps).reduce((a, b) => a > b ? a : b);
  }

  double get averageMemory {
    if (dataPoints.isEmpty) return 0;
    return dataPoints.map((e) => e.memoryUsage).reduce((a, b) => a + b) /
        dataPoints.length;
  }

  double get minMemory {
    if (dataPoints.isEmpty) return 0;
    return dataPoints
        .map((e) => e.memoryUsage)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxMemory {
    if (dataPoints.isEmpty) return 0;
    return dataPoints
        .map((e) => e.memoryUsage)
        .reduce((a, b) => a > b ? a : b);
  }

  void clear() {
    dataPoints.clear();
  }
}