import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:flutter_dev_panel_console/src/ui/pages/console_page.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'package:get/get.dart';

void main() {
  group('ConsoleModule Tests', () {
    test('ConsoleModule should have correct properties', () {
      const module = ConsoleModule();
      
      expect(module.id, equals('console'));
      expect(module.name, equals('控制台'));
      expect(module.description, equals('查看应用日志和错误信息'));
      expect(module.icon, equals(Icons.terminal));
      expect(module.enabled, equals(true));
      expect(module.order, equals(20));
      expect(module.fabPriority, equals(10));
    });

    testWidgets('ConsoleModule buildPage returns ConsolePage', (tester) async {
      const module = ConsoleModule();
      
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => module.buildPage(context),
            ),
          ),
        ),
      );
      
      // Verify that ConsolePage is rendered
      expect(find.byType(ConsolePage), findsOneWidget);
    });

    test('ConsoleModule.addTestLogs should add logs without errors', () {
      // This test just ensures the method runs without throwing
      expect(() => ConsoleModule.addTestLogs(), returnsNormally);
    });

    test('DevLogger should capture logs', () {
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

    test('DevLogger filter should work correctly', () {
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