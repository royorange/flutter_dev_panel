import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_console/src/ui/pages/console_page.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';

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
  
  group('ConsoleModule', () {
    test('should have correct properties', () {
      const module = ConsoleModule();
      
      expect(module.name, equals('Console'));
      expect(module.description, equals('查看应用日志和错误信息'));
      expect(module.icon, equals(Icons.terminal));
      expect(module.fabPriority, equals(1));
    });

    test('buildPage returns ConsolePage', () {
      const module = ConsoleModule();
      
      // Just verify that buildPage returns a ConsolePage widget
      final page = module.buildPage(_TestBuildContext());
      expect(page, isA<ConsolePage>());
    });

    test('addTestLogs should execute without errors', () {
      // This test just ensures the method runs without throwing
      expect(() => ConsoleModule.addTestLogs(), returnsNormally);
    });
  });

  group('DevLogger', () {
    setUp(() {
      DevLogger.instance.clear();
    });

    test('should capture logs with different levels', () {
      final logger = DevLogger.instance;
      
      // Clear existing logs
      logger.clear();
      
      // Add test logs
      logger.verbose('Test verbose');
      logger.debug('Test debug');
      logger.info('Test info');
      logger.warning('Test warning');
      logger.error('Test error', error: 'Error details');
      
      // Verify logs were captured
      final logs = logger.logs;
      expect(logs.length, equals(5));
      
      // Verify log levels
      expect(logs[0].level, equals(LogLevel.verbose));
      expect(logs[1].level, equals(LogLevel.debug));
      expect(logs[2].level, equals(LogLevel.info));
      expect(logs[3].level, equals(LogLevel.warning));
      expect(logs[4].level, equals(LogLevel.error));
      
      // Verify messages
      expect(logs[0].message, equals('Test verbose'));
      expect(logs[4].error, equals('Error details'));
    });

    test('should filter logs correctly', () {
      final logger = DevLogger.instance;
      
      // Clear and add test logs
      logger.clear();
      logger.verbose('Verbose message');
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');
      
      // Test filtering by level
      final errorLogs = logger.getFilteredLogs(minLevel: LogLevel.error);
      expect(errorLogs.length, equals(1));
      expect(errorLogs[0].level, equals(LogLevel.error));
      
      // Test filtering by level (warning and above)
      final warningLogs = logger.getFilteredLogs(minLevel: LogLevel.warning);
      expect(warningLogs.length, equals(2));
      
      // Test filtering by text
      final debugLogs = logger.getFilteredLogs(filter: 'Debug');
      expect(debugLogs.length, equals(1));
      expect(debugLogs[0].message, contains('Debug'));
    });
  });
}