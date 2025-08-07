import 'package:flutter/foundation.dart';
import '../models/environment.dart';
import 'storage.dart';

class EnvironmentManager extends ChangeNotifier {
  static EnvironmentManager? _instance;
  static EnvironmentManager get instance => _instance ??= EnvironmentManager._();
  
  List<Environment> _environments = [];
  Environment? _currentEnvironment;
  final _storage = DevPanelStorage();
  final _changeCallbacks = <VoidCallback>[];

  List<Environment> get environments => _environments;
  Environment? get currentEnvironment => _currentEnvironment;

  EnvironmentManager._() {
    _loadEnvironments();
  }
  
  factory EnvironmentManager() => instance;

  void initialize(List<Environment> environments) {
    if (environments.isEmpty) {
      _environments = Environment.defaultEnvironments();
    } else {
      _environments = environments;
    }
    
    // Set first environment as active if none is active
    if (_currentEnvironment == null && _environments.isNotEmpty) {
      switchEnvironment(_environments.first.name);
    }
    notifyListeners();
  }

  Future<void> _loadEnvironments() async {
    final saved = await _storage.loadEnvironments();
    if (saved.isNotEmpty) {
      _environments = saved;
      final active = saved.firstWhere(
        (e) => e.isActive,
        orElse: () => saved.first,
      );
      _currentEnvironment = active;
      notifyListeners();
    }
  }

  void switchEnvironment(String name) {
    final index = _environments.indexWhere((e) => e.name == name);
    if (index != -1) {
      // Deactivate all environments
      for (int i = 0; i < _environments.length; i++) {
        _environments[i] = _environments[i].copyWith(isActive: false);
      }
      
      // Activate selected environment
      _environments[index] = _environments[index].copyWith(
        isActive: true,
        lastUsed: DateTime.now(),
      );
      
      _currentEnvironment = _environments[index];
      _storage.saveEnvironments(_environments);
      
      // Notify listeners
      notifyListeners();
      _notifyEnvironmentChange();
    }
  }

  void addEnvironment(Environment environment) {
    _environments.add(environment);
    _storage.saveEnvironments(_environments);
    notifyListeners();
  }

  void updateEnvironment(String name, Map<String, dynamic> config) {
    final index = _environments.indexWhere((e) => e.name == name);
    if (index != -1) {
      _environments[index] = _environments[index].copyWith(config: config);
      if (_environments[index].isActive) {
        _currentEnvironment = _environments[index];
        _notifyEnvironmentChange();
      }
      _storage.saveEnvironments(_environments);
      notifyListeners();
    }
  }

  void removeEnvironment(String name) {
    _environments.removeWhere((e) => e.name == name);
    _storage.saveEnvironments(_environments);
    notifyListeners();
  }

  T? getConfig<T>(String key) {
    return _currentEnvironment?.config[key] as T?;
  }

  void setConfig(String key, dynamic value) {
    if (_currentEnvironment != null) {
      final newConfig = Map<String, dynamic>.from(_currentEnvironment!.config);
      newConfig[key] = value;
      updateEnvironment(_currentEnvironment!.name, newConfig);
    }
  }

  void _notifyEnvironmentChange() {
    for (final callback in _changeCallbacks) {
      callback();
    }
  }
  
  void addChangeListener(VoidCallback callback) {
    _changeCallbacks.add(callback);
  }
  
  void removeChangeListener(VoidCallback callback) {
    _changeCallbacks.remove(callback);
  }
  
  @override
  void dispose() {
    _changeCallbacks.clear();
    super.dispose();
  }
}