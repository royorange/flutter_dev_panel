/// Test file to demonstrate the new Module API usage
/// 
/// This file shows how to use the new extension-based API
/// for accessing module functionality.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

// Import modules to get their extensions
import 'package:flutter_dev_panel_performance/flutter_dev_panel_performance.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';

void testNewAPI() {
  // ========== Performance Module API ==========
  
  // Check if performance module is available
  if (DevPanel.get().performance != null) {
    // Start monitoring
    DevPanel.get().performance!.startMonitoring();
    
    // Get current metrics
    print('FPS: ${DevPanel.get().performance!.currentFps}');
    print('Memory: ${DevPanel.get().performance!.currentMemory} MB');
    
    // Track resources for leak detection
    final timer = Timer.periodic(const Duration(seconds: 1), (_) {});
    DevPanel.get().performance!.trackTimer(timer);
    
    // Check for potential leaks
    if (DevPanel.get().performance!.hasPotentialLeak) {
      print('Warning: ${DevPanel.get().performance!.memorySummary}');
    }
    
    // Get resource counts
    print('Active timers: ${DevPanel.get().performance!.activeTimerCount}');
    print('Active subscriptions: ${DevPanel.get().performance!.activeSubscriptionCount}');
  } else {
    print('Performance module not installed');
  }
  
  // ========== Network Module API ==========
  
  // Check if network module is available
  if (DevPanel.get().network != null) {
    // Get network statistics
    print(DevPanel.get().network!.summary);
    
    // Control monitoring
    DevPanel.get().network!.isPaused = false;
    
    // Access requests
    final requests = DevPanel.get().network!.requests;
    print('Total requests: ${requests.length}');
    
    // Get error requests
    final errors = DevPanel.get().network!.getRecentErrors(limit: 5);
    print('Recent errors: ${errors.length}');
    
    // Get slow requests
    final slowRequests = DevPanel.get().network!.getSlowRequests(thresholdMs: 500);
    print('Slow requests: ${slowRequests.length}');
    
    // Get domain statistics
    final domains = DevPanel.get().network!.getRequestsByDomain();
    domains.forEach((domain, count) {
      print('$domain: $count requests');
    });
    
    // Clear requests
    DevPanel.get().network!.clearRequests();
  } else {
    print('Network module not installed');
  }
  
  // ========== Generic Module Access ==========
  
  // For custom modules without extensions
  final customModule = DevPanel.getModule<DevModule>();
  if (customModule != null) {
    // Use the module
    print('Module found: ${customModule.name}');
  }
  
  // Check if a module is installed
  if (DevPanel.hasModule('performance')) {
    print('Performance module is installed');
  }
  
  // Get module by ID
  final moduleById = DevPanel.getModuleById('network');
  if (moduleById != null) {
    print('Network module: ${moduleById.name}');
  }
}

/// Example of creating a custom module with API
class MyCustomModule extends DevModule {
  MyCustomModule() : super(
    id: 'my_custom',
    name: 'My Custom Module',
    description: 'A custom module example',
    icon: Icons.extension,
  );
  
  /// Provide API for the module
  MyCustomAPI get api => MyCustomAPI.instance;
  
  @override
  Widget buildPage(BuildContext context) {
    return const Center(
      child: Text('My Custom Module'),
    );
  }
}

class MyCustomAPI {
  static final MyCustomAPI instance = MyCustomAPI._();
  MyCustomAPI._();
  
  void doSomething() {
    print('Doing something in custom module');
  }
  
  String get status => 'Custom module is working';
}

/// Extension for convenient access to custom module
extension MyCustomModuleExtension on DevPanel {
  static MyCustomAPI? get myCustom {
    if (!DevPanel.isInitialized) {
      debugPrint('DevPanel not initialized');
      return null;
    }
    
    if (!DevPanel.hasModule('my_custom')) {
      debugPrint('MyCustom module not installed');
      return null;
    }
    
    final module = DevPanel.getModule<MyCustomModule>();
    return module?.api;
  }
}

// Usage of custom module
void testCustomModule() {
  // Register the custom module
  DevPanel.initialize(
    modules: [
      MyCustomModule(),
      // ... other modules
    ],
  );
  
  // Use the custom module API
  DevPanel.get().myCustom?.doSomething();
  print(DevPanel.get().myCustom?.status);
}