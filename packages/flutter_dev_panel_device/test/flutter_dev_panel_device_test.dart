import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';

void main() {
  group('DeviceModule', () {
    test('should have correct properties', () {
      const module = DeviceModule();
      
      expect(module.name, 'Device Info');
      expect(module.icon, Icons.devices);
      expect(module.description, 'Display device and application information');
      // Device module doesn't override fabPriority, so it uses the default value from DevModule
      expect(module.fabPriority, 100); // Uses default priority
    });
  });
}