import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('PerformanceModule', () {
    test('should have correct properties', () {
      const module = PerformanceModule();
      
      expect(module.name, 'Performance');
      expect(module.icon, Icons.speed);
      expect(module.description, 'Monitor app performance metrics including FPS and memory usage');
      expect(module.fabPriority, 10);
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

    test('should clear data', () {
      final controller = PerformanceMonitorController.instance;
      
      controller.clearData();
      
      expect(controller.currentFps, 0.0);
      expect(controller.currentMemory, 0.0);
      expect(controller.peakMemory, 0.0);
      expect(controller.droppedFrames, 0);
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

    test('should create with optional fields', () {
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
  });

  group('PerformanceMetrics', () {
    test('should initialize correctly', () {
      final metrics = PerformanceMetrics();
      
      expect(metrics.dataPoints.isEmpty, true);
      expect(metrics.maxDataPoints, 60);
    });

    test('should add and limit data points', () {
      final metrics = PerformanceMetrics(maxDataPoints: 3);
      final now = DateTime.now();
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      expect(metrics.dataPoints.length, 1);
      
      // Add more points
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 55.0,
        memoryUsage: 110.0,
      ));
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 2)),
        fps: 50.0,
        memoryUsage: 120.0,
      ));
      
      expect(metrics.dataPoints.length, 3);
      
      // Add one more - should remove the oldest
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 3)),
        fps: 45.0,
        memoryUsage: 130.0,
      ));
      
      expect(metrics.dataPoints.length, 3);
      expect(metrics.dataPoints.first.fps, 55.0); // First one was removed
    });

    test('should calculate average FPS', () {
      final metrics = PerformanceMetrics();
      final now = DateTime.now();
      
      expect(metrics.averageFps, 0.0); // Empty
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now,
        fps: 60.0,
        memoryUsage: 100.0,
      ));
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 40.0,
        memoryUsage: 110.0,
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
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 1)),
        fps: 40.0,
        memoryUsage: 110.0,
      ));
      
      metrics.addDataPoint(PerformanceData(
        timestamp: now.add(const Duration(seconds: 2)),
        fps: 50.0,
        memoryUsage: 120.0,
      ));
      
      expect(metrics.minFps, 40.0);
      expect(metrics.maxFps, 60.0);
    });
  });
}