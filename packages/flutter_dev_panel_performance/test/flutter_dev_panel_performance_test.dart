import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

// Simple test context for unit tests
class _TestBuildContext extends BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  Widget get widget => Container();

  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PerformanceModule', () {
    test('should have correct properties', () {
      final module = PerformanceModule();
      
      expect(module.name, 'Performance');
      expect(module.icon, Icons.speed);
      expect(module.description, 'Monitor app performance metrics including FPS and memory usage');
      expect(module.fabPriority, 10);
      expect(module.id, 'performance');
      expect(module.order, 30);
    });

    test('buildPage should return PerformanceMonitorPage', () {
      final module = PerformanceModule();
      final page = module.buildPage(_TestBuildContext());
      
      expect(page, isNotNull);
      expect(page, isA<Widget>());
    });

    test('buildFabContent returns null when not monitoring', () {
      final module = PerformanceModule();
      
      // Ensure monitoring is stopped
      PerformanceMonitorController.instance.stopMonitoring();
      
      final fabContent = module.buildFabContent(_TestBuildContext());
      expect(fabContent, isNull);
    });

    test('buildFabContent returns widget when monitoring', () {
      final module = PerformanceModule();
      
      // Start monitoring
      PerformanceMonitorController.instance.startMonitoring();
      
      final fabContent = module.buildFabContent(_TestBuildContext());
      expect(fabContent, isNotNull);
      expect(fabContent, isA<Widget>());
      
      // Cleanup
      PerformanceMonitorController.instance.stopMonitoring();
    });
  });

  group('PerformanceMonitorController', () {
    setUp(() {
      // Ensure clean state
      PerformanceMonitorController.instance.stopMonitoring();
      PerformanceMonitorController.instance.clearData();
    });

    tearDown(() {
      // Clean up after tests
      PerformanceMonitorController.instance.stopMonitoring();
    });

    test('should be singleton', () {
      final controller1 = PerformanceMonitorController.instance;
      final controller2 = PerformanceMonitorController.instance;
      
      expect(identical(controller1, controller2), true);
    });

    test('should start and stop monitoring', () {
      final controller = PerformanceMonitorController.instance;
      
      expect(controller.isMonitoring, false);
      
      controller.startMonitoring();
      expect(controller.isMonitoring, true);
      
      controller.stopMonitoring();
      expect(controller.isMonitoring, false);
    });

    test('should not start monitoring if already monitoring', () {
      final controller = PerformanceMonitorController.instance;
      
      controller.startMonitoring();
      expect(controller.isMonitoring, true);
      
      // Try to start again
      controller.startMonitoring();
      expect(controller.isMonitoring, true); // Should still be true
    });

    test('should clear data', () {
      final controller = PerformanceMonitorController.instance;
      
      controller.clearData();
      
      expect(controller.currentFps, 0.0);
      expect(controller.currentMemory, 0.0);
      expect(controller.peakMemory, 0.0);
      expect(controller.droppedFrames, 0);
      expect(controller.renderTime, 0.0);
    });

    test('should have correct property types', () {
      final controller = PerformanceMonitorController.instance;
      
      // Check that getters exist and return expected types
      expect(controller.currentFps, isA<double>());
      expect(controller.currentMemory, isA<double>());
      expect(controller.peakMemory, isA<double>());
      expect(controller.droppedFrames, isA<int>());
      expect(controller.renderTime, isA<double>());
      expect(controller.isMonitoring, isA<bool>());
    });

  });

  group('PerformanceData', () {
    test('should create with all fields', () {
      final now = DateTime.now();
      final data = PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 150.5,
        peakMemory: 200.0,
        droppedFrames: 5,
        renderTime: 16.67,
      );
      
      expect(data.timestamp, now);
      expect(data.fps, 60.0);
      expect(data.memoryUsage, 150.5);
      expect(data.peakMemory, 200.0);
      expect(data.droppedFrames, 5);
      expect(data.renderTime, 16.67);
    });

    test('should create with required fields only', () {
      final now = DateTime.now();
      final data = PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 150.5,
      );
      
      expect(data.timestamp, now);
      expect(data.fps, 60.0);
      expect(data.memoryUsage, 150.5);
      expect(data.peakMemory, isNull);
      expect(data.droppedFrames, isNull);
      expect(data.renderTime, isNull);
    });

    test('should handle zero values', () {
      final data = PerformanceData(
        timestamp: DateTime.now(),
        fps: 0.0,
        memoryUsage: 0.0,
        peakMemory: 0.0,
        droppedFrames: 0,
        renderTime: 0.0,
      );
      
      expect(data.fps, 0.0);
      expect(data.memoryUsage, 0.0);
      expect(data.peakMemory, 0.0);
      expect(data.droppedFrames, 0);
      expect(data.renderTime, 0.0);
    });

    test('should handle high values', () {
      final data = PerformanceData(
        timestamp: DateTime.now(),
        fps: 120.0, // High refresh rate
        memoryUsage: 2048.0, // 2GB
        peakMemory: 4096.0, // 4GB
        droppedFrames: 1000,
        renderTime: 100.0, // Very slow render
      );
      
      expect(data.fps, 120.0);
      expect(data.memoryUsage, 2048.0);
      expect(data.peakMemory, 4096.0);
      expect(data.droppedFrames, 1000);
      expect(data.renderTime, 100.0);
    });
  });

  group('PerformanceMetrics', () {
    test('should initialize correctly', () {
      final metrics = PerformanceMetrics();
      
      expect(metrics.dataPoints.isEmpty, true);
      expect(metrics.maxDataPoints, 60);
    });

    test('should initialize with custom max data points', () {
      final metrics = PerformanceMetrics(maxDataPoints: 100);
      
      expect(metrics.maxDataPoints, 100);
    });

    test('should add data points', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      expect(metrics.dataPoints.length, 1);
      expect(metrics.dataPoints.first.fps, 60.0);
    });

    test('should limit data points to max', () {
      final metrics = PerformanceMetrics(maxDataPoints: 3);
      final now = DateTime.now();
      
      // Add 5 data points
      for (int i = 0; i < 5; i++) {
        metrics.addDataPoint(PerformanceData(
          timestamp: now.add(Duration(seconds: i)),
          fps: 60.0 - i,
          memoryUsage: 100.0 + i * 10,
        ));
      }
      
      // Should only have last 3
      expect(metrics.dataPoints.length, 3);
      expect(metrics.dataPoints.first.fps, 58.0); // Third point (60-2)
      expect(metrics.dataPoints.last.fps, 56.0); // Fifth point (60-4)
    });

    test('should calculate average FPS correctly', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      expect(metrics.averageFps, 0.0); // Empty
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      expect(metrics.averageFps, 60.0);
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 40.0,
        memoryUsage: 110.0,
      ));
      
      expect(metrics.averageFps, 50.0);
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 2)),
        fps: 50.0,
        memoryUsage: 120.0,
      ));
      
      expect(metrics.averageFps, 50.0);
    });

    test('should calculate min and max FPS', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      expect(metrics.minFps, 0.0); // Empty
      expect(metrics.maxFps, 0.0); // Empty
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      expect(metrics.minFps, 60.0);
      expect(metrics.maxFps, 60.0);
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 30.0,
        memoryUsage: 110.0,
      ));
      
      expect(metrics.minFps, 30.0);
      expect(metrics.maxFps, 60.0);
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 2)),
        fps: 120.0,
        memoryUsage: 120.0,
      ));
      
      expect(metrics.minFps, 30.0);
      expect(metrics.maxFps, 120.0);
    });

    test('should calculate average memory', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      expect(metrics.averageMemory, 0.0); // Empty
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 60.0,
        memoryUsage: 200.0,
      ));
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 2)),
        fps: 60.0,
        memoryUsage: 150.0,
      ));
      
      expect(metrics.averageMemory, 150.0);
    });

    test('should handle clear operation', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      // Add some data
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      expect(metrics.dataPoints.length, 1);
      
      metrics.clear();
      
      expect(metrics.dataPoints.isEmpty, true);
      expect(metrics.averageFps, 0.0);
      expect(metrics.minFps, 0.0);
      expect(metrics.maxFps, 0.0);
    });

    test('should maintain chronological order', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      for (int i = 0; i < 5; i++) {
        metrics.addDataPoint(PerformanceData(
          timestamp: now.add(Duration(seconds: i)),
          fps: 60.0,
          memoryUsage: 100.0,
        ));
      }
      
      // Check that timestamps are in order
      final dataList = metrics.dataPoints.toList();
      for (int i = 1; i < dataList.length; i++) {
        expect(
          dataList[i].timestamp.isAfter(dataList[i - 1].timestamp),
          isTrue,
        );
      }
    });
  });
}