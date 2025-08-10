import 'dart:collection';

class PerformanceData {
  final DateTime timestamp;
  final double fps;
  final double memoryUsage;
  final double? peakMemory;  // Peak memory usage
  final int? droppedFrames;  // Number of dropped frames
  final double? renderTime;  // Average frame render time in ms

  PerformanceData({
    required this.timestamp,
    required this.fps,
    required this.memoryUsage,
    this.peakMemory,
    this.droppedFrames,
    this.renderTime,
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

  double get peakMemory {
    if (dataPoints.isEmpty) return 0;
    return dataPoints
        .where((e) => e.peakMemory != null)
        .map((e) => e.peakMemory!)
        .fold(0.0, (a, b) => a > b ? a : b);
  }

  int get totalDroppedFrames {
    if (dataPoints.isEmpty) return 0;
    return dataPoints
        .where((e) => e.droppedFrames != null)
        .map((e) => e.droppedFrames!)
        .fold(0, (a, b) => a + b);
  }

  double get averageRenderTime {
    final validPoints = dataPoints.where((e) => e.renderTime != null).toList();
    if (validPoints.isEmpty) return 0;
    return validPoints.map((e) => e.renderTime!).reduce((a, b) => a + b) / validPoints.length;
  }

  void clear() {
    dataPoints.clear();
  }
}