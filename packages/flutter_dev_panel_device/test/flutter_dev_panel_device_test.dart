import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';

void main() {
  group('DeviceModule', () {
    test('should have correct properties', () {
      const module = DeviceModule();
      expect(module.id, 'device_info');
      expect(module.name, 'Device Info');
      expect(module.description, 'Display device and application information');
      expect(module.icon, Icons.devices);
      expect(module.enabled, true);
      expect(module.order, 1);
    });
    
    testWidgets('should build DeviceInfoPage', (WidgetTester tester) async {
      const module = DeviceModule();
      
      await tester.pumpWidget(
        MaterialApp(
          home: module.buildPage(tester.element(find.byType(Container))),
        ),
      );
      
      expect(find.byType(DeviceInfoPage), findsOneWidget);
    });
  });
  
  group('DeviceInfoData', () {
    test('should convert to display map correctly', () {
      final deviceInfo = DeviceInfoData(
        platform: 'Test Platform',
        deviceModel: 'Test Model',
        deviceId: 'test-id',
        osVersion: 'Test OS 1.0',
        manufacturer: 'Test Manufacturer',
        isPhysicalDevice: true,
        rawData: {},
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0',
        buildNumber: '1',
        installerStore: 'Test Store',
        screenWidth: 1920,
        screenHeight: 1080,
        devicePixelRatio: 2.0,
        textScaleFactor: 1.0,
        orientation: 'Portrait',
      );
      
      final displayMap = deviceInfo.toDisplayMap();
      
      expect(displayMap['Platform'], 'Test Platform');
      expect(displayMap['Device Model'], 'Test Model');
      expect(displayMap['App Name'], 'Test App');
      expect(displayMap['Screen Width'], '1920 px');
      expect(displayMap['Screen Height'], '1080 px');
    });
  });
}