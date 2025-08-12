import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';

/// Flutter Dev Panel Unit Tests
/// 
/// Note: You may see SharedPreferences warnings during test execution.
/// These are expected and can be safely ignored. They occur because
/// SharedPreferences plugin is not available in the test environment.
/// 
/// Example warnings you might see:
/// - "Failed to load max requests: MissingPluginException"
/// - "Failed to load network requests: MissingPluginException"
/// - "Failed to load console config: MissingPluginException"
/// 
/// These warnings do not affect test results or functionality.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Module Registration Tests', () {
    test('Console module registers correctly', () {
      const module = ConsoleModule();
      expect(module.name, 'Console');
      expect(module.icon, Icons.terminal);
      expect(module.id, 'console');
    });

    test('Network module registers correctly', () {
      final module = NetworkModule();
      expect(module.name, 'Network');
      expect(module.icon, Icons.wifi);
      expect(module.id, 'network');
    });

    test('Device module registers correctly', () {
      const module = DeviceModule();
      expect(module.name, 'Device Info');
      expect(module.icon, Icons.devices);
      expect(module.id, 'device_info');
    });

    test('Performance module registers correctly', () {
      const module = PerformanceModule();
      expect(module.name, 'Performance');
      expect(module.icon, Icons.speed);
      expect(module.id, 'performance');
    });
  });

  group('Core Components Tests', () {
    test('DevPanelConfig can be created with defaults', () {
      const config = DevPanelConfig();
      expect(config.enabled, true);
      expect(config.showInProduction, false);
      expect(config.triggerModes.contains(TriggerMode.fab), true);
    });

    test('DevPanelConfig can be customized', () {
      const config = DevPanelConfig(
        enabled: false,
        showInProduction: true,
        triggerModes: {TriggerMode.shake, TriggerMode.manual},
      );
      expect(config.enabled, false);
      expect(config.showInProduction, true);
      expect(config.triggerModes.contains(TriggerMode.shake), true);
      expect(config.triggerModes.contains(TriggerMode.manual), true);
      expect(config.triggerModes.contains(TriggerMode.fab), false);
    });

    test('TriggerMode enum has correct values', () {
      expect(TriggerMode.values.length, 3);
      expect(TriggerMode.values.contains(TriggerMode.fab), true);
      expect(TriggerMode.values.contains(TriggerMode.shake), true);
      expect(TriggerMode.values.contains(TriggerMode.manual), true);
    });
  });

  group('Network Module Integration', () {
    test('NetworkModule.attachToDio adds interceptor', () {
      final dio = Dio();
      NetworkModule.attachToDio(dio);
      
      expect(dio.interceptors.isNotEmpty, true);
      expect(
        dio.interceptors.any((i) => i.toString().contains('NetworkInterceptor')),
        true,
      );
    });

    test('Multiple Dio instances can be attached', () {
      final dio1 = Dio();
      final dio2 = Dio();
      
      NetworkModule.attachToDio(dio1);
      NetworkModule.attachToDio(dio2);
      
      expect(dio1.interceptors.isNotEmpty, true);
      expect(dio2.interceptors.isNotEmpty, true);
    });
  });

  group('Environment Management Tests', () {
    test('EnvironmentConfig can be created with required fields', () {
      const config = EnvironmentConfig(
        name: 'Test',
        variables: {'key': 'value'},
      );

      expect(config.name, 'Test');
      expect(config.variables['key'], 'value');
      expect(config.isDefault, false);
    });

    test('EnvironmentConfig can be created with all fields', () {
      const config = EnvironmentConfig(
        name: 'Production',
        variables: {
          'api_url': 'https://api.example.com',
          'debug': false,
          'timeout': 10000,
        },
        isDefault: true,
      );

      expect(config.name, 'Production');
      expect(config.variables['api_url'], 'https://api.example.com');
      expect(config.variables['debug'], false);
      expect(config.variables['timeout'], 10000);
      expect(config.isDefault, true);
    });

    test('EnvironmentConfig copyWith works correctly', () {
      const original = EnvironmentConfig(
        name: 'Original',
        variables: {'key1': 'value1'},
        isDefault: true,
      );

      final modified = original.copyWith(
        name: 'Modified',
        variables: {'key2': 'value2'},
      );

      expect(modified.name, 'Modified');
      expect(modified.variables['key2'], 'value2');
      expect(modified.isDefault, true); // Should preserve original value
    });

    test('EnvironmentManager singleton instance works', () {
      final instance1 = EnvironmentManager.instance;
      final instance2 = EnvironmentManager.instance;
      
      expect(identical(instance1, instance2), true);
    });

    test('EnvironmentManager getVariable returns null for non-existent key', () {
      final value = EnvironmentManager.instance.getVariable<String>('non_existent');
      expect(value, isNull);
    });

    test('EnvironmentManager getVariable returns default for non-existent key', () {
      final value = EnvironmentManager.instance.getVariable<String>(
        'non_existent',
        defaultValue: 'default',
      );
      expect(value, 'default');
    });
  });

  group('DevLogger Tests', () {
    setUp(() {
      // Clear logs before each test
      DevLogger.instance.clear();
    });

    test('DevLogger can log different levels', () {
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

    test('DevLogger static log method works', () {
      DevLogger.log('Static log message');
      expect(DevLogger.instance.logs.isNotEmpty, true);
      expect(DevLogger.instance.logs.last.message, 'Static log message');
    });

    test('DevLogger clear removes all logs', () {
      DevLogger.instance.info('Test message');
      expect(DevLogger.instance.logs.isNotEmpty, true);
      
      DevLogger.instance.clear();
      expect(DevLogger.instance.logs.isEmpty, true);
    });
  });
}