import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'env_loader.dart';

/// Environment configuration
class EnvironmentConfig {
  final String name;
  final Map<String, dynamic> variables;
  final bool isDefault;

  const EnvironmentConfig({
    required this.name,
    required this.variables,
    this.isDefault = false,
  });

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) {
    return EnvironmentConfig(
      name: json['name'] as String,
      variables: Map<String, dynamic>.from(json['variables'] as Map),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'variables': variables,
      'isDefault': isDefault,
    };
  }

  EnvironmentConfig copyWith({
    String? name,
    Map<String, dynamic>? variables,
    bool? isDefault,
  }) {
    return EnvironmentConfig(
      name: name ?? this.name,
      variables: variables ?? this.variables,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Environment manager singleton
class EnvironmentManager extends ChangeNotifier {
  static EnvironmentManager? _instance;
  static EnvironmentManager get instance {
    _instance ??= EnvironmentManager._();
    return _instance!;
  }

  EnvironmentManager._() {
    _loadEnvironments();
  }

  // Current environment
  EnvironmentConfig? _currentEnvironment;
  EnvironmentConfig? get currentEnvironment => _currentEnvironment;

  // Available environments
  final List<EnvironmentConfig> _environments = [];
  List<EnvironmentConfig> get environments => List.unmodifiable(_environments);

  // Storage key
  static const String _storageKey = 'dev_panel_environments';
  static const String _currentEnvKey = 'dev_panel_current_env';

  /// Initialize with environments from multiple sources
  /// Priority: .env files > code configuration > saved configuration
  Future<void> initialize({
    List<EnvironmentConfig>? environments,
    String? defaultEnvironment,
    bool loadFromEnvFiles = true,
  }) async {
    // Load from .env files if enabled
    List<EnvironmentConfig>? envFileConfigs;
    if (loadFromEnvFiles) {
      try {
        envFileConfigs = await EnvLoader.loadFromEnvFiles();
        if (envFileConfigs != null && envFileConfigs.isNotEmpty) {
          debugPrint('Loaded ${envFileConfigs.length} environments from .env files');
        }
      } catch (e) {
        debugPrint('Failed to load .env files: $e');
      }
    }
    
    // Load saved configuration
    List<EnvironmentConfig>? savedConfigs;
    try {
      final prefs = await SharedPreferences.getInstance();
      final envsJson = prefs.getString(_storageKey);
      if (envsJson != null) {
        final List<dynamic> envsList = jsonDecode(envsJson) as List<dynamic>;
        savedConfigs = envsList
            .map((json) => EnvironmentConfig.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to load saved environments: $e');
    }
    
    // Merge all sources
    final mergedEnvs = EnvLoader.mergeEnvironments(
      fromEnvFiles: envFileConfigs,
      fromCode: environments,
      fromStorage: savedConfigs,
    );
    
    if (mergedEnvs.isNotEmpty) {
      _environments.clear();
      _environments.addAll(mergedEnvs);
      
      // Set default environment
      if (defaultEnvironment != null) {
        final env = _environments.firstWhere(
          (e) => e.name == defaultEnvironment,
          orElse: () => _environments.first,
        );
        _currentEnvironment = env;
      } else {
        // Try to restore previously selected environment
        final prefs = await SharedPreferences.getInstance();
        final lastEnvName = prefs.getString(_currentEnvKey);
        if (lastEnvName != null) {
          final lastEnv = _environments.firstWhere(
            (e) => e.name == lastEnvName,
            orElse: () => _environments.firstWhere(
              (e) => e.isDefault,
              orElse: () => _environments.first,
            ),
          );
          _currentEnvironment = lastEnv;
        } else {
          // Use the one marked as default or the first one
          _currentEnvironment = _environments.firstWhere(
            (e) => e.isDefault,
            orElse: () => _environments.first,
          );
        }
      }
      
      _saveEnvironments();
      notifyListeners();
    } else if (environments == null || environments.isEmpty) {
      // No environments provided, try to create from .env files only
      debugPrint('No environments configured. Please provide environments or create .env files.');
    }
  }


  /// Load environments from storage
  Future<void> _loadEnvironments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load environments
      final envsJson = prefs.getString(_storageKey);
      if (envsJson != null) {
        final List<dynamic> envsList = jsonDecode(envsJson) as List<dynamic>;
        _environments.clear();
        for (final json in envsList) {
          _environments.add(
            EnvironmentConfig.fromJson(json as Map<String, dynamic>),
          );
        }
      }

      // Load current environment
      final currentEnvName = prefs.getString(_currentEnvKey);
      if (currentEnvName != null && _environments.isNotEmpty) {
        _currentEnvironment = _environments.firstWhere(
          (e) => e.name == currentEnvName,
          orElse: () => _environments.first,
        );
      }

      // If no environments loaded, leave empty
      // User should initialize with their own environments

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load environments: $e');
      // Leave empty on error
      // User should initialize with their own environments
    }
  }

  /// Save environments to storage
  Future<void> _saveEnvironments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save environments
      final envsList = _environments.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(envsList));

      // Save current environment
      if (_currentEnvironment != null) {
        await prefs.setString(_currentEnvKey, _currentEnvironment!.name);
      }
    } catch (e) {
      debugPrint('Failed to save environments: $e');
    }
  }

  /// Switch to a different environment
  void switchEnvironment(String name) {
    // Handle case where saved environment no longer exists
    EnvironmentConfig? env;
    try {
      env = _environments.firstWhere((e) => e.name == name);
    } catch (e) {
      debugPrint('Environment "$name" not found, falling back to first available');
      if (_environments.isNotEmpty) {
        env = _environments.first;
      }
    }
    
    if (env != null && _currentEnvironment != env) {
      _currentEnvironment = env;
      _saveEnvironments();
      notifyListeners();
    }
  }

  /// Add a new environment
  void addEnvironment(EnvironmentConfig environment) {
    // Check if name already exists
    if (_environments.any((e) => e.name == environment.name)) {
      throw Exception('Environment with name ${environment.name} already exists');
    }
    
    _environments.add(environment);
    _saveEnvironments();
    notifyListeners();
  }

  /// Update an existing environment
  void updateEnvironment(String name, EnvironmentConfig newConfig) {
    final index = _environments.indexWhere((e) => e.name == name);
    if (index != -1) {
      _environments[index] = newConfig;
      
      // Update current if it's the same
      if (_currentEnvironment?.name == name) {
        _currentEnvironment = newConfig;
      }
      
      _saveEnvironments();
      notifyListeners();
    }
  }

  /// Remove an environment
  void removeEnvironment(String name) {
    // Can't remove if it's the only one
    if (_environments.length <= 1) {
      throw Exception('Cannot remove the last environment');
    }
    
    _environments.removeWhere((e) => e.name == name);
    
    // If current was removed, switch to first
    if (_currentEnvironment?.name == name) {
      _currentEnvironment = _environments.first;
    }
    
    _saveEnvironments();
    notifyListeners();
  }

  /// Get a variable from current environment with optional default value
  /// 
  /// Example:
  /// ```dart
  /// // Without default value (returns null if not found)
  /// final apiUrl = EnvironmentManager.instance.getVariable<String>('API_URL');
  /// 
  /// // With default value
  /// final apiUrl = EnvironmentManager.instance.getVariable<String>(
  ///   'API_URL', 
  ///   defaultValue: 'https://api.example.com'
  /// );
  /// ```
  T? getVariable<T>(String key, {T? defaultValue}) {
    final value = _currentEnvironment?.variables[key];
    if (value != null) {
      return value as T;
    }
    return defaultValue;
  }

  /// Get a variable with a required default value (deprecated, use getVariable with defaultValue)
  @Deprecated('Use getVariable with defaultValue parameter instead')
  T getVariableOrDefault<T>(String key, T defaultValue) {
    return getVariable<T>(key, defaultValue: defaultValue) ?? defaultValue;
  }

  /// Update a variable in current environment
  void updateVariable(String key, dynamic value) {
    if (_currentEnvironment != null) {
      final newVars = Map<String, dynamic>.from(_currentEnvironment!.variables);
      newVars[key] = value;
      
      final newEnv = _currentEnvironment!.copyWith(variables: newVars);
      updateEnvironment(_currentEnvironment!.name, newEnv);
    }
  }

  /// Clear all environments
  void clear() {
    _environments.clear();
    _currentEnvironment = null;
    _saveEnvironments();
    notifyListeners();
  }
}