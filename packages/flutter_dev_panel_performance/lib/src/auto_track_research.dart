import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 研究自动追踪 Timer 和 StreamSubscription 的可能方案
class AutoTrackResearch {
  
  // ========== 方案1: 使用 Zone 拦截 ==========
  
  /// Zone 方案 - 可以拦截 Timer 和 Stream 的创建
  static void testZoneInterception() {
    final trackedTimers = <Timer>[];
    final trackedSubscriptions = <StreamSubscription>[];
    
    // 创建自定义 Zone 规范
    final zoneSpec = ZoneSpecification(
      // 拦截 Timer 创建
      createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() f) {
        debugPrint('[Zone] Timer.new intercepted: duration=$duration');
        final timer = parent.createTimer(zone, duration, f);
        trackedTimers.add(timer);
        return timer;
      },
      
      // 拦截周期性 Timer 创建
      createPeriodicTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration period, void Function(Timer) f) {
        debugPrint('[Zone] Timer.periodic intercepted: period=$period');
        final timer = parent.createPeriodicTimer(zone, period, f);
        trackedTimers.add(timer);
        return timer;
      },
      
      // 拦截错误处理（可选）
      handleUncaughtError: (Zone self, ZoneDelegate parent, Zone zone, Object error, StackTrace stackTrace) {
        debugPrint('[Zone] Uncaught error: $error');
        parent.handleUncaughtError(zone, error, stackTrace);
      },
    );
    
    // 在自定义 Zone 中运行代码
    runZoned(() {
      // 这些 Timer 会被自动追踪
      Timer(const Duration(seconds: 1), () {
        debugPrint('Timer 1 executed');
      });
      
      Timer.periodic(const Duration(seconds: 2), (timer) {
        debugPrint('Periodic timer executed');
        timer.cancel();
      });
      
      // Stream subscriptions 需要额外处理
      final controller = StreamController<int>();
      final subscription = controller.stream.listen((data) {
        debugPrint('Stream data: $data');
      });
      trackedSubscriptions.add(subscription);
      
      controller.add(1);
      controller.close();
      subscription.cancel();
      
      debugPrint('Tracked timers: ${trackedTimers.length}');
      debugPrint('Tracked subscriptions: ${trackedSubscriptions.length}');
    }, zoneSpecification: zoneSpec);
  }
  
  // ========== 方案2: 使用 Timeline API (dart:developer) ==========
  
  /// Timeline 方案 - 可以记录性能事件，但不能拦截对象创建
  static void testTimelineAPI() {
    // 开始一个 Timeline 任务
    developer.Timeline.startSync('timer_tracking');
    
    Timer(const Duration(seconds: 1), () {
      debugPrint('Timer executed');
      developer.Timeline.finishSync();
    });
    
    // Timeline 主要用于性能分析，不适合对象追踪
    debugPrint('Timeline events recorded (visible in DevTools)');
  }
  
  // ========== 方案3: 使用 Service Extension ==========
  
  /// Service Extension 方案 - 可以注册自定义调试服务
  static void testServiceExtension() {
    if (kDebugMode) {
      // 注册自定义服务扩展
      developer.registerExtension(
        'ext.flutter.devPanel.getActiveTimers',
        (String method, Map<String, String> parameters) async {
          // 这里可以返回追踪的 Timer 信息
          // 但仍然需要手动追踪
          return developer.ServiceExtensionResponse.result(
            '{"activeTimers": 0, "message": "需要手动追踪"}',
          );
        },
      );
      
      debugPrint('Service extension registered');
    }
  }
  
  // ========== 方案4: Monkey Patching (不推荐) ==========
  
  /// 创建包装类来替代原生 Timer
  static Timer createTrackedTimer(Duration duration, void Function() callback) {
    debugPrint('Creating tracked timer: $duration');
    Timer? trackedTimer;
    trackedTimer = Timer(duration, () {
      debugPrint('Timer executed and auto-removed from tracking');
      callback();
      if (trackedTimer != null) {
        _activeTimers.removeWhere((ref) => ref.target == trackedTimer);
      }
    });
    // 自动追踪
    _activeTimers.add(WeakReference(trackedTimer));
    return trackedTimer;
  }
  
  static Timer createTrackedPeriodicTimer(Duration duration, void Function(Timer) callback) {
    debugPrint('Creating tracked periodic timer: $duration');
    final timer = Timer.periodic(duration, callback);
    _activeTimers.add(WeakReference(timer));
    return timer;
  }
  
  static final _activeTimers = <WeakReference<Timer>>[];
  
  // ========== 方案5: 使用 Flutter 的 SchedulerBinding ==========
  
  /// Flutter 框架层面的追踪
  static void testSchedulerBinding() {
    // Flutter 的 SchedulerBinding 可以追踪帧回调
    // 但不能直接追踪 Timer 和 StreamSubscription
    
    if (kDebugMode) {
      // 可以获取一些调试信息
      debugPrint('SchedulerBinding 主要用于帧调度，不适合 Timer 追踪');
    }
  }
  
  // ========== 方案6: 混合方案 - Zone + 包装器 ==========
  
  /// 最实用的方案：结合 Zone 和工具方法
  static Zone? _trackingZone;
  static final _zoneTimers = <Timer>[];
  static final _zoneSubscriptions = <StreamSubscription>[];
  
  /// 初始化追踪 Zone
  static void initializeTracking() {
    if (_trackingZone != null) return;
    
    final zoneSpec = ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        Timer? createdTimer;
        createdTimer = parent.createTimer(zone, duration, () {
          f();
          if (createdTimer != null) {
            _zoneTimers.remove(createdTimer);  // 执行后自动移除
          }
        });
        _zoneTimers.add(createdTimer);
        debugPrint('[AutoTrack] Timer created: ${_zoneTimers.length} active');
        return createdTimer;
      },
      
      createPeriodicTimer: (self, parent, zone, period, f) {
        final timer = parent.createPeriodicTimer(zone, period, f);
        _zoneTimers.add(timer);
        debugPrint('[AutoTrack] Periodic timer created: ${_zoneTimers.length} active');
        return timer;
      },
    );
    
    _trackingZone = Zone.current.fork(specification: zoneSpec);
  }
  
  /// 在追踪 Zone 中运行代码
  static T runWithTracking<T>(T Function() body) {
    initializeTracking();
    return _trackingZone!.run(body);
  }
  
  /// 获取活跃的 Timer 数量
  static int get activeTimerCount {
    _zoneTimers.removeWhere((timer) => !timer.isActive);
    return _zoneTimers.length;
  }
  
  /// 提供便捷的 Stream 扩展
  static StreamSubscription<T> trackSubscription<T>(
    Stream<T> stream,
    void Function(T) onData,
  ) {
    final subscription = stream.listen(onData);
    _zoneSubscriptions.add(subscription);
    debugPrint('[AutoTrack] Subscription created: ${_zoneSubscriptions.length} active');
    return subscription;
  }
  
  // ========== 测试所有方案 ==========
  
  static void runAllTests() {
    debugPrint('\n===== 测试 Zone 拦截 =====');
    testZoneInterception();
    
    debugPrint('\n===== 测试 Timeline API =====');
    testTimelineAPI();
    
    debugPrint('\n===== 测试 Service Extension =====');
    testServiceExtension();
    
    debugPrint('\n===== 测试混合方案 =====');
    runWithTracking(() {
      Timer(const Duration(seconds: 1), () {
        debugPrint('Auto-tracked timer executed');
      });
      
      Timer.periodic(const Duration(seconds: 2), (timer) {
        debugPrint('Auto-tracked periodic timer executed');
        if (DateTime.now().second % 5 == 0) {
          timer.cancel();
        }
      });
      
      debugPrint('Active timers: $activeTimerCount');
    });
  }
}

/// 为应用提供的便捷扩展
extension StreamAutoTrack<T> on Stream<T> {
  /// 自动追踪的 listen 方法
  StreamSubscription<T> listenTracked(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    
    // 这里可以自动注册到 LeakDetector
    // LeakDetector.instance.trackSubscription(subscription);
    
    return subscription;
  }
}

/// Timer 的工厂方法
class TrackedTimer {
  /// 创建自动追踪的 Timer
  static Timer create(Duration duration, void Function() callback) {
    return AutoTrackResearch.runWithTracking(() {
      return Timer(duration, callback);
    });
  }
  
  /// 创建自动追踪的周期性 Timer
  static Timer periodic(Duration duration, void Function(Timer) callback) {
    return AutoTrackResearch.runWithTracking(() {
      return Timer.periodic(duration, callback);
    });
  }
}