import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

// Import modules to get their extensions
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DevPanel
  DevPanel.initialize(
    modules: [
      const PerformanceModule(),
      NetworkModule(),
    ],
  );
  
  // Test API access after runApp
  WidgetsBinding.instance.addPostFrameCallback((_) {
    testAPIAccess();
  });
  
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Testing DevPanel API'),
      ),
    ),
  ));
}

void testAPIAccess() {
  // Test Performance API
  final perfApi = DevPanel.get().performance;
  if (perfApi != null) {
    print('✅ Performance API accessible');
    perfApi.startMonitoring();
    print('  - Monitoring started');
    print('  - FPS: ${perfApi.currentFps}');
    print('  - Memory: ${perfApi.currentMemory} MB');
  } else {
    print('❌ Performance API not accessible');
  }
  
  // Test Network API
  final networkApi = DevPanel.get().network;
  if (networkApi != null) {
    print('✅ Network API accessible');
    print('  - Summary: ${networkApi.summary}');
    print('  - Total requests: ${networkApi.totalRequests}');
  } else {
    print('❌ Network API not accessible');
  }
}