import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('NetworkModule', () {
    test('should have correct properties', () {
      final module = NetworkModule();
      
      expect(module.name, 'Network');
      expect(module.icon, Icons.wifi);
      expect(module.description, 'Monitor and debug network requests');
      expect(module.fabPriority, 20);
    });

    test('should be singleton', () {
      final module1 = NetworkModule();
      final module2 = NetworkModule();
      
      // Should be the same instance (singleton)
      expect(identical(module1, module2), true);
    });

    test('controller should be initialized and singleton', () {
      final controller = NetworkModule.controller;
      
      expect(controller, isNotNull);
      
      // Controller should be singleton too
      final controller2 = NetworkModule.controller;
      expect(identical(controller, controller2), true);
    });
  });
}