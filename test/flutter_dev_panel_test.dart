import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

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
  
  // Module tests have been moved to their respective packages
  // since modules are now published as separate packages

  group('Core Components Tests', () {
    test('DevPanelConfig can be created with defaults', () {
      const config = DevPanelConfig();
      expect(config.triggerModes.contains(TriggerMode.fab), true);
      expect(config.enableLogCapture, true);
    });

    test('DevPanelConfig can be customized', () {
      const config = DevPanelConfig(
        triggerModes: {TriggerMode.shake},
        enableLogCapture: false,
      );
      expect(config.triggerModes.contains(TriggerMode.shake), true);
      expect(config.triggerModes.contains(TriggerMode.fab), false);
      expect(config.enableLogCapture, false);
    });

    test('TriggerMode enum has correct values', () {
      expect(TriggerMode.values.length, 2);
      expect(TriggerMode.values.contains(TriggerMode.fab), true);
      expect(TriggerMode.values.contains(TriggerMode.shake), true);
    });
  });

  // Network module tests have been moved to flutter_dev_panel_network package

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