import 'package:get/get.dart';
import '../models/environment.dart';
import 'storage.dart';

class EnvironmentManager extends GetxController {
  final _environments = <Environment>[].obs;
  final _currentEnvironment = Rxn<Environment>();
  final _storage = DevPanelStorage();

  List<Environment> get environments => _environments;
  Environment? get currentEnvironment => _currentEnvironment.value;

  @override
  void onInit() {
    super.onInit();
    _loadEnvironments();
  }

  void initialize(List<Environment> environments) {
    if (environments.isEmpty) {
      _environments.value = Environment.defaultEnvironments();
    } else {
      _environments.value = environments;
    }
    
    // Set first environment as active if none is active
    if (_currentEnvironment.value == null && _environments.isNotEmpty) {
      switchEnvironment(_environments.first.name);
    }
  }

  Future<void> _loadEnvironments() async {
    final saved = await _storage.loadEnvironments();
    if (saved.isNotEmpty) {
      _environments.value = saved;
      final active = saved.firstWhereOrNull((e) => e.isActive);
      if (active != null) {
        _currentEnvironment.value = active;
      }
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
      
      _currentEnvironment.value = _environments[index];
      _storage.saveEnvironments(_environments);
      
      // Notify listeners
      _notifyEnvironmentChange();
    }
  }

  void addEnvironment(Environment environment) {
    _environments.add(environment);
    _storage.saveEnvironments(_environments);
  }

  void updateEnvironment(String name, Map<String, dynamic> config) {
    final index = _environments.indexWhere((e) => e.name == name);
    if (index != -1) {
      _environments[index] = _environments[index].copyWith(config: config);
      if (_environments[index].isActive) {
        _currentEnvironment.value = _environments[index];
        _notifyEnvironmentChange();
      }
      _storage.saveEnvironments(_environments);
    }
  }

  void removeEnvironment(String name) {
    _environments.removeWhere((e) => e.name == name);
    _storage.saveEnvironments(_environments);
  }

  T? getConfig<T>(String key) {
    return _currentEnvironment.value?.config[key] as T?;
  }

  void setConfig(String key, dynamic value) {
    if (_currentEnvironment.value != null) {
      final newConfig = Map<String, dynamic>.from(_currentEnvironment.value!.config);
      newConfig[key] = value;
      updateEnvironment(_currentEnvironment.value!.name, newConfig);
    }
  }

  void _notifyEnvironmentChange() {
    // Trigger environment change event
    Get.find<DevPanelEnvironmentChangeNotifier>()._onEnvironmentChange();
  }
}

class DevPanelEnvironmentChangeNotifier extends GetxController {
  final _changeNotifier = 0.obs;
  
  int get changeCount => _changeNotifier.value;
  
  void _onEnvironmentChange() {
    _changeNotifier.value++;
  }
}