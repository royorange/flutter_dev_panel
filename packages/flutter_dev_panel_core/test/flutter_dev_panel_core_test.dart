/// Tests for Flutter Dev Panel Core package
/// 
/// This file contains unit tests for the core functionality including:
/// - DevLogger: Log capture and management
/// - LogEntry: Log entry model
/// - DevPanelConfig: Panel configuration
/// - LogCaptureConfig: Log capture configuration  
/// - EnvironmentConfig: Environment configuration management

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';

void main() {
  group('DevLogger Basic Tests', () {
    setUp(() {
      DevLogger.instance.clear();
    });

    test('DevLogger captures different log levels', () {
      DevLogger.instance.verbose('Verbose message');
      DevLogger.instance.debug('Debug message');
      DevLogger.instance.info('Info message');
      DevLogger.instance.warning('Warning message');
      DevLogger.instance.error('Error message');

      final logs = DevLogger.instance.logs;
      expect(logs.length, 5);
      expect(logs[0].level, LogLevel.verbose);
      expect(logs[1].level, LogLevel.debug);
      expect(logs[2].level, LogLevel.info);
      expect(logs[3].level, LogLevel.warning);
      expect(logs[4].level, LogLevel.error);
    });

    test('DevLogger respects max logs configuration', () {
      DevLogger.instance.updateConfig(
        const LogCaptureConfig(maxLogs: 3),
      );

      for (int i = 0; i < 5; i++) {
        DevLogger.instance.info('Log $i');
      }

      expect(DevLogger.instance.logs.length, 3);
      expect(DevLogger.instance.logs.last.message, 'Log 4');
    });

    test('DevLogger clear works', () {
      DevLogger.instance.info('Test log');
      expect(DevLogger.instance.logs.length, 1);
      
      DevLogger.instance.clear();
      expect(DevLogger.instance.logs.length, 0);
    });

    test('DevLogger pause functionality', () {
      DevLogger.instance.setPaused(true);
      DevLogger.instance.info('This should not be captured');
      
      expect(DevLogger.instance.logs.length, 0);
      
      DevLogger.instance.setPaused(false);
      DevLogger.instance.info('This should be captured');
      
      expect(DevLogger.instance.logs.length, 1);
    });

    test('DevLogger filtering by level', () {
      DevLogger.instance.verbose('Verbose');
      DevLogger.instance.debug('Debug');
      DevLogger.instance.info('Info');
      DevLogger.instance.warning('Warning');
      DevLogger.instance.error('Error');

      final filtered = DevLogger.instance.getFilteredLogs(
        minLevel: LogLevel.warning,
      );
      
      expect(filtered.length, 2);
      expect(filtered[0].level, LogLevel.warning);
      expect(filtered[1].level, LogLevel.error);
    });

    test('DevLogger text search filtering', () {
      DevLogger.instance.info('Hello world');
      DevLogger.instance.info('Goodbye world');
      DevLogger.instance.info('Hello again');

      final filtered = DevLogger.instance.getFilteredLogs(
        filter: 'Hello',
      );
      
      expect(filtered.length, 2);
    });
  });

  group('LogEntry Tests', () {
    test('LogEntry color by level', () {
      final verbose = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.verbose,
        message: 'test',
      );
      expect(verbose.color, Colors.grey);

      final error = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        message: 'test',
      );
      expect(error.color, Colors.red);
    });

    test('LogEntry level text', () {
      final verbose = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.verbose,
        message: 'test',
      );
      expect(verbose.levelText, 'V');

      final error = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        message: 'test',
      );
      expect(error.levelText, 'E');
    });

    test('LogEntry formatted time', () {
      final entry = LogEntry(
        timestamp: DateTime(2024, 1, 1, 12, 34, 56, 789),
        level: LogLevel.info,
        message: 'test',
      );
      expect(entry.formattedTime, '12:34:56.789');
    });
  });

  group('DevPanelConfig Tests', () {
    test('DevPanelConfig default values', () {
      const config = DevPanelConfig();
      
      expect(config.enabled, true);
      expect(config.triggerModes.contains(TriggerMode.fab), true);
      expect(config.showInProduction, false);
    });

    test('DevPanelConfig custom values', () {
      const config = DevPanelConfig(
        enabled: false,
        triggerModes: {TriggerMode.shake, TriggerMode.manual},
        showInProduction: true,
      );
      
      expect(config.enabled, false);
      expect(config.triggerModes.length, 2);
      expect(config.triggerModes.contains(TriggerMode.shake), true);
      expect(config.showInProduction, true);
    });

    test('DevPanelConfig copyWith', () {
      const config = DevPanelConfig();
      final updated = config.copyWith(enabled: false);
      
      expect(updated.enabled, false);
      expect(updated.triggerModes, config.triggerModes);
      expect(updated.showInProduction, config.showInProduction);
    });
  });

  group('LogCaptureConfig Tests', () {
    test('LogCaptureConfig default values', () {
      const config = LogCaptureConfig();
      
      expect(config.maxLogs, 1000);
      expect(config.autoScroll, true);
      expect(config.combineLoggerOutput, true);
    });

    test('LogCaptureConfig presets', () {
      const minimal = LogCaptureConfig.minimal();
      expect(minimal.maxLogs, 500);
      
      const development = LogCaptureConfig.development();
      expect(development.maxLogs, 1000);
      
      const full = LogCaptureConfig.full();
      expect(full.maxLogs, 5000);
    });

    test('LogCaptureConfig copyWith', () {
      const config = LogCaptureConfig();
      final updated = config.copyWith(maxLogs: 2000);
      
      expect(updated.maxLogs, 2000);
      expect(updated.autoScroll, config.autoScroll);
      expect(updated.combineLoggerOutput, config.combineLoggerOutput);
    });
  });

  group('EnvironmentConfig Tests', () {
    test('EnvironmentConfig creation', () {
      const env = EnvironmentConfig(
        name: 'Test',
        variables: {'key': 'value'},
        isDefault: true,
      );
      
      expect(env.name, 'Test');
      expect(env.variables['key'], 'value');
      expect(env.isDefault, true);
    });

    test('EnvironmentConfig copyWith', () {
      const env = EnvironmentConfig(
        name: 'Test',
        variables: {'key': 'value'},
      );
      
      final updated = env.copyWith(
        name: 'Updated',
        variables: {'key': 'new_value', 'extra': 'data'},
      );
      
      expect(updated.name, 'Updated');
      expect(updated.variables['key'], 'new_value');
      expect(updated.variables['extra'], 'data');
    });

    test('EnvironmentConfig fromJson/toJson', () {
      const env = EnvironmentConfig(
        name: 'Test',
        variables: {'key': 'value', 'number': 42},
        isDefault: true,
      );
      
      final json = env.toJson();
      expect(json['name'], 'Test');
      expect(json['variables']['key'], 'value');
      expect(json['variables']['number'], 42);
      expect(json['isDefault'], true);
      
      final restored = EnvironmentConfig.fromJson(json);
      expect(restored.name, env.name);
      expect(restored.variables['key'], env.variables['key']);
      expect(restored.isDefault, env.isDefault);
    });
  });
}