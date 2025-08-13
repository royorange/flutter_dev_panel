import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvironmentManager Tests', () {
    setUp(() {
      // Clear any existing environments before each test
      EnvironmentManager.instance.clear();
    });

    test('should initialize with code configuration', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Development',
            variables: {
              'api_url': 'https://dev.api.com',
              'timeout': 60,
            },
            isDefault: true,
          ),
          const EnvironmentConfig(
            name: 'Production',
            variables: {
              'api_url': 'https://api.com',
              'timeout': 30,
            },
          ),
        ],
      );

      expect(EnvironmentManager.instance.environments.length, 2);
      expect(
          EnvironmentManager.instance.currentEnvironment?.name, 'Development');
    });

    test('should get variables with correct types', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Test',
            variables: {
              'string_var': 'hello',
              'int_var': 42,
              'double_var': 3.14,
              'bool_var': true,
            },
            isDefault: true,
          ),
        ],
      );

      expect(EnvironmentManager.instance.getVariable<String>('string_var'),
          'hello');
      expect(EnvironmentManager.instance.getVariable<int>('int_var'), 42);
      expect(
          EnvironmentManager.instance.getVariable<double>('double_var'), 3.14);
      expect(EnvironmentManager.instance.getVariable<bool>('bool_var'), true);
    });

    test('should return default value for non-existent variables', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Test',
            variables: {},
            isDefault: true,
          ),
        ],
      );

      expect(
        EnvironmentManager.instance.getVariable<String>(
          'missing_var',
          defaultValue: 'default',
        ),
        'default',
      );
    });

    test('should switch environments', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Dev',
            variables: {'env': 'dev'},
            isDefault: true,
          ),
          const EnvironmentConfig(
            name: 'Prod',
            variables: {'env': 'prod'},
          ),
        ],
      );

      expect(EnvironmentManager.instance.currentEnvironment?.name, 'Dev');
      expect(EnvironmentManager.instance.getVariable<String>('env'), 'dev');

      EnvironmentManager.instance.switchEnvironment('Prod');

      expect(EnvironmentManager.instance.currentEnvironment?.name, 'Prod');
      expect(EnvironmentManager.instance.getVariable<String>('env'), 'prod');
    });

    test('should handle type conversion from strings', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Test',
            variables: {
              'int_as_string': '123',
              'double_as_string': '45.67',
              'bool_as_string': 'true',
              'bool_as_one': '1',
            },
            isDefault: true,
          ),
        ],
      );

      expect(
          EnvironmentManager.instance.getVariable<int>('int_as_string'), 123);
      expect(
          EnvironmentManager.instance.getVariable<double>('double_as_string'),
          45.67);
      expect(EnvironmentManager.instance.getVariable<bool>('bool_as_string'),
          true);
      expect(
          EnvironmentManager.instance.getVariable<bool>('bool_as_one'), true);
    });

    test('should notify listeners on environment change', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Env1',
            variables: {},
            isDefault: true,
          ),
          const EnvironmentConfig(
            name: 'Env2',
            variables: {},
          ),
        ],
      );

      bool notified = false;
      void listener() {
        notified = true;
      }

      EnvironmentManager.instance.addListener(listener);
      EnvironmentManager.instance.switchEnvironment('Env2');

      expect(notified, true);

      EnvironmentManager.instance.removeListener(listener);
    });

    test('should add and remove environments', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Initial',
            variables: {},
            isDefault: true,
          ),
        ],
      );

      expect(EnvironmentManager.instance.environments.length, 1);

      EnvironmentManager.instance.addEnvironment(
        const EnvironmentConfig(
          name: 'Added',
          variables: {'test': 'value'},
        ),
      );

      expect(EnvironmentManager.instance.environments.length, 2);

      EnvironmentManager.instance.removeEnvironment('Added');

      expect(EnvironmentManager.instance.environments.length, 1);
    });

    test('should update environment variables', () async {
      await EnvironmentManager.instance.initialize(
        environments: [
          const EnvironmentConfig(
            name: 'Test',
            variables: {'old': 'value'},
            isDefault: true,
          ),
        ],
      );

      expect(EnvironmentManager.instance.getVariable<String>('old'), 'value');

      // Update the environment with new variables
      final currentEnv = EnvironmentManager.instance.currentEnvironment!;
      final newVars = Map<String, dynamic>.from(currentEnv.variables);
      newVars['new'] = 'new_value';

      EnvironmentManager.instance.updateEnvironment(
        currentEnv.name,
        currentEnv.copyWith(variables: newVars),
      );

      expect(
          EnvironmentManager.instance.getVariable<String>('new'), 'new_value');
    });

    test('should handle priority correctly when dart-define is enabled',
        () async {
      // Note: We can't actually test --dart-define values in unit tests
      // because they're compile-time constants. This test documents
      // the expected behavior.

      await EnvironmentManager.instance.initialize(
        loadFromEnvFiles: false, // Skip .env files for this test
        environments: [
          const EnvironmentConfig(
            name: 'Default',
            variables: {
              'api_url': 'https://default.com',
            },
            isDefault: true,
          ),
        ],
      );

      // In a real app with --dart-define=API_URL=https://override.com,
      // the value would be 'https://override.com'
      // In tests, it falls back to the code configuration
      expect(
        EnvironmentManager.instance.getVariable<String>('api_url'),
        'https://default.com',
      );
    });
  });
}
