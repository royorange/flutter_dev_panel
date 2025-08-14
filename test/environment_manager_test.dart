import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

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

      // Note: getVariable doesn't do type conversion, use convenience methods instead
      // The convenience methods (getInt, getDouble) handle type conversion
      expect(EnvironmentManager.instance.getInt('int_as_string'), 123);
      expect(EnvironmentManager.instance.getDouble('double_as_string'), 45.67);
      
      // For bool, these strings are stored as strings, not converted
      // So getVariable<bool> will fail. This is expected behavior.
      // Users should use the convenience methods for type conversion
      expect(EnvironmentManager.instance.getVariable<String>('bool_as_string'), 'true');
      expect(EnvironmentManager.instance.getVariable<String>('bool_as_one'), '1');
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

    group('Convenience Methods', () {
      setUp(() async {
        EnvironmentManager.instance.clear();
        await EnvironmentManager.instance.initialize(
          environments: [
            const EnvironmentConfig(
              name: 'Test',
              variables: {
                // String types
                'api_url': 'https://test-api.example.com',
                'api_key': 'test-key-123',
                
                // Bool types
                'debug': true,
                'enable_analytics': false,
                
                // Number types
                'timeout': 30000,
                'version': 1.5,
                'max_retries': '3', // String that can be parsed to int
                'price': '19.99', // String that can be parsed to double
                
                // List types
                'servers': ['server1.com', 'server2.com', 'server3.com'],
                'features': ['feature_a', 'feature_b'],
                
                // Map type
                'database': {
                  'host': 'localhost',
                  'port': 5432,
                  'name': 'test_db',
                },
              },
              isDefault: true,
            ),
          ],
        );
      });

      test('getString should work correctly', () {
        expect(
          EnvironmentManager.instance.getString('api_url'),
          'https://test-api.example.com',
        );
        expect(
          EnvironmentManager.instance.getString('api_key'),
          'test-key-123',
        );
        expect(
          EnvironmentManager.instance.getString('missing', defaultValue: 'default'),
          'default',
        );
        expect(
          EnvironmentManager.instance.getString('missing'),
          null,
        );
      });

      test('getBool should work correctly', () {
        expect(EnvironmentManager.instance.getBool('debug'), true);
        expect(EnvironmentManager.instance.getBool('enable_analytics'), false);
        expect(
          EnvironmentManager.instance.getBool('missing', defaultValue: true),
          true,
        );
        expect(EnvironmentManager.instance.getBool('missing'), null);
      });

      test('getInt should work correctly with type conversion', () {
        // Direct int
        expect(EnvironmentManager.instance.getInt('timeout'), 30000);
        
        // String to int conversion
        expect(EnvironmentManager.instance.getInt('max_retries'), 3);
        
        // Double to int conversion
        expect(EnvironmentManager.instance.getInt('version'), 1);
        
        // Default value
        expect(
          EnvironmentManager.instance.getInt('missing', defaultValue: 100),
          100,
        );
        expect(EnvironmentManager.instance.getInt('missing'), null);
      });

      test('getDouble should work correctly with type conversion', () {
        // Direct double
        expect(EnvironmentManager.instance.getDouble('version'), 1.5);
        
        // Int to double conversion
        expect(EnvironmentManager.instance.getDouble('timeout'), 30000.0);
        
        // String to double conversion
        expect(EnvironmentManager.instance.getDouble('price'), 19.99);
        
        // Default value
        expect(
          EnvironmentManager.instance.getDouble('missing', defaultValue: 0.0),
          0.0,
        );
        expect(EnvironmentManager.instance.getDouble('missing'), null);
      });

      test('getList should work correctly', () {
        final servers = EnvironmentManager.instance.getList<String>('servers');
        expect(servers, ['server1.com', 'server2.com', 'server3.com']);
        
        final features = EnvironmentManager.instance.getList<String>('features');
        expect(features, ['feature_a', 'feature_b']);
        
        expect(
          EnvironmentManager.instance.getList<String>('missing', defaultValue: ['default']),
          ['default'],
        );
        expect(EnvironmentManager.instance.getList<String>('missing'), null);
      });

      test('getMap should work correctly', () {
        final dbConfig = EnvironmentManager.instance.getMap('database');
        expect(dbConfig, {
          'host': 'localhost',
          'port': 5432,
          'name': 'test_db',
        });
        
        expect(
          EnvironmentManager.instance.getMap('missing', defaultValue: {'default': true}),
          {'default': true},
        );
        expect(EnvironmentManager.instance.getMap('missing'), null);
      });

      test('convenience methods should match generic getVariable', () {
        // String comparison
        expect(
          EnvironmentManager.instance.getString('api_url'),
          EnvironmentManager.instance.getVariable<String>('api_url'),
        );
        
        // Bool comparison
        expect(
          EnvironmentManager.instance.getBool('debug'),
          EnvironmentManager.instance.getVariable<bool>('debug'),
        );
        
        // Int comparison (note: getInt has smart conversion)
        expect(
          EnvironmentManager.instance.getInt('timeout'),
          EnvironmentManager.instance.getVariable<int>('timeout'),
        );
        
        // Double comparison
        expect(
          EnvironmentManager.instance.getDouble('version'),
          EnvironmentManager.instance.getVariable<double>('version'),
        );
      });

      test('should access via DevPanel.environment shortcut', () {
        // Test that DevPanel.environment works the same as EnvironmentManager.instance
        expect(
          DevPanel.environment.getString('api_url'),
          'https://test-api.example.com',
        );
        expect(DevPanel.environment.getBool('debug'), true);
        expect(DevPanel.environment.getInt('timeout'), 30000);
        expect(DevPanel.environment.getDouble('version'), 1.5);
        expect(
          DevPanel.environment.getList<String>('servers'),
          ['server1.com', 'server2.com', 'server3.com'],
        );
        expect(DevPanel.environment.getMap('database'), {
          'host': 'localhost',
          'port': 5432,
          'name': 'test_db',
        });
      });
    });
  });
}
