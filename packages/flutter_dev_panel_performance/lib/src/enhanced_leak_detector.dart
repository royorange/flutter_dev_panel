import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 增强版泄漏检测器 - 支持自动追踪
class EnhancedLeakDetector {
  static final EnhancedLeakDetector _instance = EnhancedLeakDetector._internal();
  static EnhancedLeakDetector get instance => _instance;
  
  EnhancedLeakDetector._internal();

  // 自动追踪的 Timer（不需要 WeakReference，因为我们会在 Timer 完成时自动移除）
  final Set<Timer> _activeTimers = {};
  
  // StreamSubscription 仍需要手动或半自动追踪
  final Set<WeakReference<StreamSubscription>> _activeSubscriptions = {};
  
  // 是否已初始化
  bool _initialized = false;
  
  /// 获取活跃的 Timer 数量
  int get activeTimerCount => _activeTimers.where((t) => t.isActive).length;
  
  /// 获取活跃的 StreamSubscription 数量
  int get activeSubscriptionCount {
    _activeSubscriptions.removeWhere((ref) => ref.target == null);
    return _activeSubscriptions.length;
  }
  
  /// 初始化自动追踪
  void initialize() {
    if (_initialized || !kDebugMode) return;
    _initialized = true;
    
    debugPrint('EnhancedLeakDetector: Auto-tracking initialized');
  }
  
  /// 使用自动追踪运行应用
  /// 
  /// 示例：
  /// ```dart
  /// void main() {
  ///   runApp(
  ///     EnhancedLeakDetector.instance.runWithAutoTracking(
  ///       () => MyApp(),
  ///     ),
  ///   );
  /// }
  /// ```
  Widget runWithAutoTracking(Widget Function() appBuilder) {
    if (!kDebugMode) {
      return appBuilder();
    }
    
    return runZoned(
      () => appBuilder(),
      zoneSpecification: _createTrackingZoneSpec(),
    );
  }
  
  /// 创建追踪 Zone 规范
  ZoneSpecification _createTrackingZoneSpec() {
    return ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        Timer? timer;
        timer = parent.createTimer(zone, duration, () {
          f();
          // Timer 执行完成后自动移除
          if (timer != null) {
            _activeTimers.remove(timer);
          }
        });
        _activeTimers.add(timer);
        
        if (kDebugMode && _activeTimers.length % 10 == 0) {
          debugPrint('EnhancedLeakDetector: Active timers: ${_activeTimers.length}');
        }
        
        return timer;
      },
      createPeriodicTimer: (self, parent, zone, period, f) {
        final timer = parent.createPeriodicTimer(zone, period, f);
        _activeTimers.add(timer);
        
        if (kDebugMode && _activeTimers.length > 20) {
          debugPrint('⚠️ EnhancedLeakDetector: High number of periodic timers: ${_activeTimers.length}');
        }
        
        return timer;
      },
    );
  }
  
  /// 手动追踪 StreamSubscription（保留向后兼容）
  void trackSubscription(StreamSubscription subscription) {
    if (!kDebugMode) return;
    _activeSubscriptions.add(WeakReference(subscription));
  }
  
  /// 清理数据
  void clear() {
    _activeTimers.clear();
    _activeSubscriptions.clear();
  }
  
  /// 获取详细的调试信息
  Map<String, dynamic> getDebugInfo() {
    final activeTimers = _activeTimers.where((t) => t.isActive).toList();
    final periodicTimers = activeTimers.where((t) => t.tick > 0).length;
    final oneShotTimers = activeTimers.length - periodicTimers;
    
    return {
      'totalTimers': activeTimers.length,
      'periodicTimers': periodicTimers,
      'oneShotTimers': oneShotTimers,
      'subscriptions': activeSubscriptionCount,
      'warning': activeTimers.length > 10 || activeSubscriptionCount > 10,
    };
  }
}

/// Widget Mixin - 自动管理资源
mixin AutoTrackingMixin<T extends StatefulWidget> on State<T> {
  final _timers = <Timer>[];
  final _subscriptions = <StreamSubscription>[];
  
  /// 创建自动管理的 Timer
  Timer createTimer(Duration duration, void Function() callback) {
    final timer = Timer(duration, callback);
    _timers.add(timer);
    return timer;
  }
  
  /// 创建自动管理的周期性 Timer
  Timer createPeriodicTimer(Duration duration, void Function(Timer) callback) {
    final timer = Timer.periodic(duration, callback);
    _timers.add(timer);
    return timer;
  }
  
  /// 创建自动管理的 StreamSubscription
  StreamSubscription<E> createSubscription<E>(
    Stream<E> stream,
    void Function(E) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    _subscriptions.add(subscription);
    EnhancedLeakDetector.instance.trackSubscription(subscription);
    return subscription;
  }
  
  @override
  void dispose() {
    // 自动清理所有资源
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _timers.clear();
    _subscriptions.clear();
    super.dispose();
  }
}

/// Stream 扩展 - 简化追踪
extension StreamTrackingExtension<T> on Stream<T> {
  /// 创建带追踪的订阅
  /// 
  /// 示例：
  /// ```dart
  /// myStream.listenTracked(
  ///   (data) => print(data),
  ///   tag: 'MyFeature',
  /// );
  /// ```
  StreamSubscription<T> listenTracked(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
    String? tag,
  }) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    
    EnhancedLeakDetector.instance.trackSubscription(subscription);
    
    if (kDebugMode && tag != null) {
      debugPrint('StreamTracking: Created subscription for $tag');
    }
    
    return subscription;
  }
}