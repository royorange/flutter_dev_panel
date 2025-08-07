import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';

void main() {
  group('Flutter Dev Panel Core Tests', () {
    setUp(() {
      FlutterDevPanelCore.instance.reset();
    });

    test('Core initialization with config', () {
      FlutterDevPanelCore.instance.initialize(
        config: const DevPanelConfig(
          enabled: true,
          triggerModes: {TriggerMode.fab, TriggerMode.shake},
          showInProduction: false,
        ),
      );

      final config = FlutterDevPanelCore.instance.controller.config;
      expect(config.enabled, true);
      expect(config.triggerModes.length, 2);
      expect(config.showInProduction, false);
    });

    test('Module registration', () {
      final modules = [
        NetworkModule(),
        const DeviceModule(),
        const PerformanceModule(),
      ];

      FlutterDevPanelCore.instance.initialize(modules: modules);

      final registry = FlutterDevPanelCore.instance.moduleRegistry;
      expect(registry.modules.length, 3);
      expect(registry.getModule('network'), isNotNull);
      expect(registry.getModule('device_info'), isNotNull);
      expect(registry.getModule('performance'), isNotNull);
    });

    test('NetworkModule Dio attachment', () {
      final dio = Dio();
      NetworkModule.attachToDio(dio);
      
      expect(dio.interceptors.isNotEmpty, true);
    });

    test('Module enable and disable', () {
      FlutterDevPanelCore.instance.initialize(
        modules: [NetworkModule()],
      );

      final registry = FlutterDevPanelCore.instance.moduleRegistry;
      
      expect(registry.isModuleEnabled('network'), true);
      
      registry.disableModule('network');
      expect(registry.isModuleEnabled('network'), false);
      
      registry.enableModule('network');
      expect(registry.isModuleEnabled('network'), true);
    });
  });
}