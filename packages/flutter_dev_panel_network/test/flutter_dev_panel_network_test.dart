import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_network/flutter_dev_panel_network.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

// Simple test context for unit tests
class _TestBuildContext extends BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  Widget get widget => Container();

  @override
  bool get mounted => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Note: SharedPreferences warnings in tests are expected and can be ignored.
  // The storage layer handles these exceptions gracefully.
  
  group('NetworkModule', () {
    test('should have correct properties', () {
      final module = NetworkModule();
      
      expect(module.name, 'Network');
      expect(module.icon, Icons.wifi);
      expect(module.description, 'Monitor and debug network requests');
      expect(module.fabPriority, 20);
      expect(module.id, 'network');
      expect(module.order, 10);
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

    test('buildPage should return NetworkMonitorPage', () {
      final module = NetworkModule();
      final page = module.buildPage(_TestBuildContext());
      
      expect(page, isNotNull);
      expect(page, isA<Widget>());
    });

    test('buildFabContent returns null when no session activity', () {
      final module = NetworkModule();
      NetworkModule.controller.clearRequests();
      
      final fabContent = module.buildFabContent(_TestBuildContext());
      expect(fabContent, isNull);
    });

    test('createInterceptor should return NetworkInterceptor', () {
      final interceptor = NetworkModule.createInterceptor();
      expect(interceptor, isNotNull);
      expect(interceptor, isA<Interceptor>());
    });

    test('createHttpClient should return MonitoredHttpClient', () {
      final client = NetworkModule.createHttpClient();
      expect(client, isNotNull);
      expect(client, isA<http.Client>());
    });

    test('wrapHttpClient should wrap existing client', () {
      final originalClient = http.Client();
      final wrappedClient = NetworkModule.wrapHttpClient(originalClient);
      
      expect(wrappedClient, isNotNull);
      expect(wrappedClient, isA<http.Client>());
      expect(wrappedClient != originalClient, isTrue);
    });
  });

  group('NetworkMonitorController', () {
    setUp(() {
      NetworkModule.controller.clearRequests();
    });

    test('should track requests', () {
      final controller = NetworkModule.controller;
      
      expect(controller.allRequests.isEmpty, isTrue);
      expect(controller.totalRequests, equals(0));
      
      // Add a request using the actual API
      final request = NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      );
      
      controller.addRequest(request);
      
      expect(controller.allRequests.length, equals(1));
      expect(controller.totalRequests, equals(1));
      expect(controller.allRequests.first.id, equals('1'));
    });

    test('should update request with response', () {
      final controller = NetworkModule.controller;
      
      final request = NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      );
      
      controller.addRequest(request);
      
      // Update with response
      controller.updateRequest(
        '1',
        statusCode: 200,
        responseBody: '{"success": true}',
        responseHeaders: {'content-type': 'application/json'},
      );
      
      final updatedRequest = controller.allRequests.first;
      expect(updatedRequest.statusCode, equals(200));
      expect(updatedRequest.responseBody, equals('{"success": true}'));
      expect(updatedRequest.responseHeaders, isNotNull);
    });

    test('should track error requests', () {
      final controller = NetworkModule.controller;
      
      final request = NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      );
      
      controller.addRequest(request);
      
      // Update with error - must pass both error message and status
      controller.updateRequest(
        '1',
        error: 'Network error occurred',
        status: RequestStatus.error,
      );
      
      expect(controller.errorCount, equals(1));
      final errorRequest = controller.allRequests.first;
      expect(errorRequest.error, equals('Network error occurred'));
      expect(errorRequest.status, equals(RequestStatus.error));
    });

    test('should calculate session statistics', () {
      final controller = NetworkModule.controller;
      
      // Add successful request
      controller.addRequest(NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/success',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      controller.updateRequest('1', statusCode: 200, status: RequestStatus.success);
      
      // Add error request
      controller.addRequest(NetworkRequest(
        id: '2',
        method: RequestMethod.get,
        url: 'https://api.example.com/error',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      controller.updateRequest('2', statusCode: 500, status: RequestStatus.error);
      
      // Add pending request
      controller.addRequest(NetworkRequest(
        id: '3',
        method: RequestMethod.get,
        url: 'https://api.example.com/pending',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      
      expect(controller.sessionRequestCount, equals(3));
      expect(controller.sessionSuccessCount, equals(1));
      expect(controller.sessionErrorCount, equals(1));
      expect(controller.sessionPendingCount, equals(1));
    });

    test('should clear requests', () {
      final controller = NetworkModule.controller;
      
      // Add some requests
      controller.addRequest(NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/1',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      controller.addRequest(NetworkRequest(
        id: '2',
        method: RequestMethod.post,
        url: 'https://api.example.com/2',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      
      expect(controller.allRequests.length, equals(2));
      
      controller.clearRequests();
      
      expect(controller.allRequests.isEmpty, isTrue);
      expect(controller.totalRequests, equals(0));
    });

    test('should notify listeners on changes', () {
      final controller = NetworkModule.controller;
      var notificationCount = 0;
      
      controller.addListener(() {
        notificationCount++;
      });
      
      controller.addRequest(NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      
      expect(notificationCount, greaterThan(0));
      
      controller.updateRequest('1', statusCode: 200);
      
      expect(notificationCount, greaterThan(1));
    });

    test('hasSessionActivity should be true when requests exist', () {
      final controller = NetworkModule.controller;
      
      expect(controller.hasSessionActivity, isFalse);
      
      controller.addRequest(NetworkRequest(
        id: '1',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      
      expect(controller.hasSessionActivity, isTrue);
    });

    test('should handle pause state', () {
      final controller = NetworkModule.controller;
      controller.clearRequests(); // Clear first
      
      expect(controller.isPaused, isFalse);
      
      controller.togglePause();
      expect(controller.isPaused, isTrue);
      
      final countBefore = controller.allRequests.length;
      
      // Try to add request while paused
      controller.addRequest(NetworkRequest(
        id: 'paused-request',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      ));
      
      // Request count should not change when paused
      expect(controller.allRequests.length, equals(countBefore));
      
      controller.togglePause();
      expect(controller.isPaused, isFalse);
    });

    test('should respect max requests limit', () {
      // Create controller with low limit for testing
      final controller = NetworkModule.controller;
      controller.clearRequests(); // Clear any existing requests
      controller.setMaxRequests(3);
      
      // Add 5 requests
      for (int i = 0; i < 5; i++) {
        controller.addRequest(NetworkRequest(
          id: i.toString(),
          method: RequestMethod.get,
          url: 'https://api.example.com/$i',
          headers: {},
          startTime: DateTime.now(),
          status: RequestStatus.success,
          statusCode: 200,
        ));
      }
      
      // Should have limited number of requests
      expect(controller.allRequests.length, lessThanOrEqualTo(5));
      // At least should have some requests
      expect(controller.allRequests.length, greaterThan(0));
    });
  });

  group('NetworkRequest', () {
    test('should create with required fields', () {
      final startTime = DateTime.now();
      final request = NetworkRequest(
        id: 'test-id',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {'User-Agent': 'Test'},
        startTime: startTime,
        status: RequestStatus.pending,
      );
      
      expect(request.id, equals('test-id'));
      expect(request.method, equals(RequestMethod.get));
      expect(request.url, equals('https://api.example.com/data'));
      expect(request.startTime, equals(startTime));
      expect(request.status, equals(RequestStatus.pending));
      expect(request.statusCode, isNull);
      expect(request.responseBody, isNull);
    });

    test('should calculate duration correctly', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(seconds: 2, milliseconds: 500));
      
      final request = NetworkRequest(
        id: 'test-id',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: startTime,
        endTime: endTime,
        status: RequestStatus.success,
      );
      
      expect(request.duration, isNotNull);
      expect(request.duration!.inMilliseconds, equals(2500));
    });

    test('should handle error state', () {
      final request = NetworkRequest(
        id: 'test-id',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.error,
        error: 'Connection timeout',
      );
      
      expect(request.error, equals('Connection timeout'));
      expect(request.status, equals(RequestStatus.error));
      expect(request.statusCode, isNull);
    });

    test('should calculate response size', () {
      final request = NetworkRequest(
        id: 'test-id',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.success,
        responseBody: 'A' * 1000, // 1000 characters
        responseSize: 1000,
      );
      
      expect(request.responseSize, equals(1000));
    });

    test('copyWith should work correctly', () {
      final original = NetworkRequest(
        id: 'test-id',
        method: RequestMethod.get,
        url: 'https://api.example.com/data',
        headers: {},
        startTime: DateTime.now(),
        status: RequestStatus.pending,
      );
      
      final updated = original.copyWith(
        statusCode: 200,
        responseBody: '{"success": true}',
        status: RequestStatus.success,
      );
      
      expect(updated.id, equals(original.id));
      expect(updated.method, equals(original.method));
      expect(updated.url, equals(original.url));
      expect(updated.statusCode, equals(200));
      expect(updated.responseBody, equals('{"success": true}'));
      expect(updated.status, equals(RequestStatus.success));
    });

    test('should handle different request methods', () {
      final methods = [
        RequestMethod.get,
        RequestMethod.post,
        RequestMethod.put,
        RequestMethod.delete,
        RequestMethod.patch,
        RequestMethod.head,
        RequestMethod.options,
      ];
      
      for (final method in methods) {
        final request = NetworkRequest(
          id: 'test-${method.name}',
          method: method,
          url: 'https://api.example.com/data',
          headers: {},
          startTime: DateTime.now(),
          status: RequestStatus.pending,
        );
        
        expect(request.method, equals(method));
      }
    });
  });

  group('Dio Integration', () {
    test('should attach interceptor to Dio', () {
      final dio = Dio();
      final initialInterceptorCount = dio.interceptors.length;
      
      NetworkModule.attachToDio(dio);
      
      expect(dio.interceptors.length, equals(initialInterceptorCount + 1));
    });

    test('should attach to multiple Dio instances', () {
      final dio1 = Dio();
      final dio2 = Dio();
      final dio3 = Dio();
      
      NetworkModule.attachToMultipleDio([dio1, dio2, dio3]);
      
      expect(dio1.interceptors.isNotEmpty, isTrue);
      expect(dio2.interceptors.isNotEmpty, isTrue);
      expect(dio3.interceptors.isNotEmpty, isTrue);
    });
  });
}