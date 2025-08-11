import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:dio/dio.dart';

void main() {
  group('Flutter Dev Panel Integration Tests', () {
    setUp(() {
      // Reset before each test
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('FlutterDevPanel.initialize works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              FlutterDevPanel.initialize(
                config: const DevPanelConfig(
                  enabled: true,
                  triggerModes: {TriggerMode.fab, TriggerMode.manual},
                  showInProduction: false,
                ),
                modules: [
                  const ConsoleModule(),
                  NetworkModule(),
                ],
                enableLogCapture: true,
              );
              
              return const Scaffold(
                body: Text('Test App'),
              );
            },
          ),
        ),
      );
      
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('DevPanelWrapper renders child correctly', (tester) async {
      FlutterDevPanel.initialize(
        config: const DevPanelConfig(enabled: true),
        modules: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DevPanelWrapper(
            child: Scaffold(
              body: const Text('Wrapped Content'),
            ),
          ),
        ),
      );

      expect(find.text('Wrapped Content'), findsOneWidget);
    });

    test('NetworkModule.attachToDio adds interceptor', () {
      final dio = Dio();
      NetworkModule.attachToDio(dio);
      
      expect(dio.interceptors.isNotEmpty, true);
      expect(
        dio.interceptors.any((i) => i.toString().contains('NetworkInterceptor')),
        true,
      );
    });

    testWidgets('FlutterDevPanel.open shows panel', (tester) async {
      FlutterDevPanel.initialize(
        config: const DevPanelConfig(enabled: true),
        modules: [const ConsoleModule()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DevPanelWrapper(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => FlutterDevPanel.open(context),
                    child: const Text('Open Panel'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap the button to open panel
      await tester.tap(find.text('Open Panel'));
      await tester.pumpAndSettle();

      // Panel should be visible
      expect(find.text('Dev Panel'), findsOneWidget);
    });
  });

  group('Module Registration Tests', () {
    test('Console module registers correctly', () {
      final module = const ConsoleModule();
      expect(module.name, 'Console');
      expect(module.icon, Icons.terminal);
    });

    test('Network module registers correctly', () {
      final module = NetworkModule();
      expect(module.name, 'Network');
      expect(module.icon, Icons.network_check);
    });

    test('Device module registers correctly', () {
      final module = const DeviceModule();
      expect(module.name, 'Device Info');
      expect(module.icon, Icons.phone_android);
    });

    test('Performance module registers correctly', () {
      final module = const PerformanceModule();
      expect(module.name, 'Performance');
      expect(module.icon, Icons.speed);
    });
  });
}