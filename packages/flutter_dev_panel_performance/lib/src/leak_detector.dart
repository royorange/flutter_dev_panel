import 'dart:async';
import 'package:flutter/foundation.dart';

/// Timer 信息
class TimerInfo {
  final Timer timer;
  final StackTrace? stackTrace;
  final DateTime createdAt;
  final bool isPeriodic;

  TimerInfo({
    required this.timer,
    this.stackTrace,
    required this.createdAt,
    required this.isPeriodic,
  });

  /// 获取创建位置的简短描述
  String get location {
    if (stackTrace == null) return 'Unknown';

    final lines = stackTrace.toString().split('\n');

    // 从栈顶开始查找第一个有意义的位置
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];

      // 跳过 LeakDetector 自己的调用
      if (line.contains('LeakDetector._trackAutoTimer') ||
          line.contains('LeakDetector.createAutoTrackingZone')) {
        continue;
      }

      // 跳过 Zone 相关的调用
      if (line.contains('_CustomZone') || line.contains('dart:async/zone')) {
        continue;
      }

      // 找到第一个包含文件路径的行
      if (line.contains('.dart:')) {
        // 提取文件名和行号
        final match = RegExp(r'([^/\s(]+\.dart):(\d+)').firstMatch(line);
        if (match != null) {
          final fileName = match.group(1) ?? '';
          final lineNumber = match.group(2) ?? '';

          // 如果是 timer.dart，继续查找真实调用者
          if (fileName == 'timer.dart') continue;

          return '$fileName:$lineNumber';
        }
      }
    }

    // 如果没找到，返回第一个有用的信息
    if (lines.isNotEmpty) {
      final firstLine = lines[0];
      final match = RegExp(r'([^/\s(]+\.dart):(\d+)').firstMatch(firstLine);
      if (match != null) {
        return '${match.group(1)}:${match.group(2)}';
      }
    }

    return 'System';
  }

  /// 是否是内部 Timer（来自 flutter_dev_panel 相关包）
  bool get isInternalTimer {
    if (stackTrace == null) return false;

    final stackString = stackTrace.toString();
    
    // 简单判断：如果调用栈中包含 flutter_dev_panel，就认为是内部 Timer
    return stackString.contains('flutter_dev_panel');
  }
}

/// 简化的内存泄露检测器 - 只关注实用数据
class LeakDetector {
  static final LeakDetector _instance = LeakDetector._internal();
  static LeakDetector get instance => _instance;

  LeakDetector._internal();

  // 手动追踪的 Timer（保留向后兼容）
  final _manualTimers = <WeakReference<Timer>>[];

  // 自动追踪的 Timer 信息（通过 Zone）
  final _autoTimerInfos = <TimerInfo>[];

  // 追踪未取消的 StreamSubscription
  final _activeSubscriptions = <WeakReference<StreamSubscription>>[];

  // 内存增长记录（最近10次）
  final List<double> _memorySnapshots = [];
  final List<DateTime> _snapshotTimes = [];
  DateTime? _lastSnapshotTime;

  /// 获取活跃的 Timer 数量
  int get activeTimerCount {
    // 清理手动追踪的失效引用
    _manualTimers.removeWhere((ref) => ref.target == null);
    // 清理自动追踪的已完成 Timer
    _autoTimerInfos.removeWhere((info) => !info.timer.isActive);
    // 返回总数
    return _manualTimers.length + _autoTimerInfos.length;
  }

  /// 获取活跃的 StreamSubscription 数量
  int get activeSubscriptionCount {
    _activeSubscriptions.removeWhere((ref) => ref.target == null);
    return _activeSubscriptions.length;
  }

  /// 注册 Timer（开发者手动调用 - 保留向后兼容）
  void trackTimer(Timer timer) {
    if (!kDebugMode) return;
    _manualTimers.add(WeakReference(timer));
  }

  // 标记是否正在追踪中，避免递归
  bool _isTracking = false;
  // 标记监控是否已启动
  bool _monitoringStarted = false;

  /// 设置监控状态
  void setMonitoringStarted(bool started) {
    _monitoringStarted = started;
    if (!started) {
      // 监控停止时，清理自动追踪的 Timer
      _autoTimerInfos.clear();
    }
  }

  /// 自动注册 Timer（由 Zone 调用）
  void _trackAutoTimer(Timer timer, {bool isPeriodic = false}) {
    if (!kDebugMode) return;
    
    // 只有在监控启动后才追踪 Timer
    if (!_monitoringStarted) return;

    // 避免递归：如果正在追踪中，直接返回
    if (_isTracking) return;

    try {
      _isTracking = true;

      // 捕获调用栈
      final stackTrace = StackTrace.current;

      // 过滤不需要追踪的 Timer
      final stackString = stackTrace.toString();

      // 只过滤 Flutter SDK 框架的 Timer，不过滤 flutter_dev_panel 和用户代码的 Timer
      // 检查调用栈的前几行，看是否是系统内部的 Timer
      final lines = stackString.split('\n');
      bool isSystemTimer = true;
      
      // 检查前10行，看是否有非系统代码
      for (int i = 0; i < lines.length && i < 10; i++) {
        final line = lines[i];
        
        // 跳过 LeakDetector 自身
        if (line.contains('LeakDetector')) continue;
        
        // 如果找到 flutter_dev_panel 或用户代码，不是系统 Timer
        if (line.contains('flutter_dev_panel') || 
            (line.contains('.dart:') && 
             !line.contains('dart:async') && 
             !line.contains('dart:ui') &&
             !line.contains('dart:isolate') &&
             !line.contains('package:flutter/'))) {
          isSystemTimer = false;
          break;
        }
      }
      
      // 如果整个调用栈都是系统代码，过滤掉
      if (isSystemTimer) {
        // 最后检查：如果调用栈中没有任何用户代码或 flutter_dev_panel，则过滤
        if (!stackString.contains('flutter_dev_panel') && 
            !stackString.contains('package:wisburg') && // 用户项目
            !stackString.contains('lib/main.dart')) {   // 用户代码
          return;
        }
      }

      _autoTimerInfos.add(TimerInfo(
        timer: timer,
        stackTrace: stackTrace,
        createdAt: DateTime.now(),
        isPeriodic: isPeriodic,
      ));

      // 移除 debugPrint 避免可能的递归
      // 只在控制台输出警告，不使用任何可能创建 Timer 的方法
    } finally {
      _isTracking = false;
    }
  }

  /// 获取所有活跃的 Timer 信息
  List<TimerInfo> get activeTimerInfos {
    // 清理已完成的 Timer
    _autoTimerInfos.removeWhere((info) => !info.timer.isActive);
    return List.unmodifiable(_autoTimerInfos);
  }

  /// 注册 StreamSubscription（开发者手动调用）
  void trackSubscription(StreamSubscription subscription) {
    if (!kDebugMode) return;
    _activeSubscriptions.add(WeakReference(subscription));
  }

  /// 记录内存快照
  void recordMemorySnapshot(double memoryMB) {
    final now = DateTime.now();

    // 每5秒记录一次
    if (_lastSnapshotTime != null &&
        now.difference(_lastSnapshotTime!).inSeconds < 5) {
      return;
    }

    _lastSnapshotTime = now;
    _memorySnapshots.add(memoryMB);
    _snapshotTimes.add(now);

    // 只保留最近10个快照
    if (_memorySnapshots.length > 10) {
      _memorySnapshots.removeAt(0);
      _snapshotTimes.removeAt(0);
    }

    // 移除调试输出，避免可能的性能问题
    // 内存信息会在 UI 中显示，不需要在控制台输出
  }

  /// 分析内存增长
  MemoryGrowthAnalysis analyzeMemoryGrowth() {
    if (_memorySnapshots.length < 3 || _snapshotTimes.length < 3) {
      return MemoryGrowthAnalysis(
        isGrowing: false,
        growthRateMBPerMinute: 0,
        suggestion: 'Collecting data... (${_memorySnapshots.length}/3 samples)',
      );
    }

    // 需要至少 30 秒的数据才能准确判断趋势
    final totalTime =
        _snapshotTimes.last.difference(_snapshotTimes.first).inSeconds;
    if (totalTime < 30) {
      final remainingTime = 30 - totalTime;
      return MemoryGrowthAnalysis(
        isGrowing: false,
        growthRateMBPerMinute: 0,
        suggestion: 'Collecting data... (${remainingTime}s remaining)',
      );
    }

    // 使用移动平均来平滑数据
    final smoothedData = <double>[];
    for (int i = 0; i < _memorySnapshots.length; i++) {
      if (i == 0) {
        smoothedData.add(_memorySnapshots[i]);
      } else if (i == 1) {
        smoothedData.add((_memorySnapshots[i] + _memorySnapshots[i - 1]) / 2);
      } else {
        // 3点移动平均
        smoothedData.add((_memorySnapshots[i] +
                _memorySnapshots[i - 1] +
                _memorySnapshots[i - 2]) /
            3);
      }
    }

    // 使用平滑后的数据计算趋势
    // 只使用最近的5个数据点（约25秒）
    final recentCount = smoothedData.length.clamp(0, 5);
    final startIndex = smoothedData.length - recentCount;

    // 计算简单的平均变化率
    final firstValue = smoothedData[startIndex];
    final lastValue = smoothedData.last;
    final firstTime = _snapshotTimes[startIndex];
    final lastTime = _snapshotTimes.last;

    final memoryDiff = lastValue - firstValue;
    final timeDiffMinutes = lastTime.difference(firstTime).inSeconds / 60.0;

    if (timeDiffMinutes < 0.1) {
      return MemoryGrowthAnalysis(
        isGrowing: false,
        growthRateMBPerMinute: 0,
        suggestion: 'Memory usage is stable',
      );
    }

    // 计算增长率
    final growthRate = memoryDiff / timeDiffMinutes;

    // Debug 模式下内存波动较大，使用更宽松的阈值
    // 小于 2 MB/min 视为正常波动
    const threshold = kDebugMode ? 2.0 : 0.5;
    final effectiveGrowthRate = growthRate.abs() < threshold ? 0.0 : growthRate;

    // 判断趋势
    final isGrowing = effectiveGrowthRate > threshold;

    String suggestion;
    final absRate = effectiveGrowthRate.abs();

    if (absRate < 0.1) {
      suggestion = 'Memory usage is stable';
    } else if (effectiveGrowthRate > 20) {
      suggestion = 'Rapid memory growth detected! Check for memory leaks';
    } else if (effectiveGrowthRate > 10) {
      suggestion = 'Memory is growing. Monitor for potential leaks';
    } else if (effectiveGrowthRate > 5) {
      suggestion = 'Moderate memory growth. Keep monitoring';
    } else if (effectiveGrowthRate > 2) {
      suggestion = 'Slight memory growth';
    } else if (effectiveGrowthRate < -5) {
      suggestion = 'Memory is decreasing (GC active)';
    } else if (effectiveGrowthRate < -2) {
      suggestion = 'Memory slightly decreasing';
    } else {
      suggestion = 'Memory usage is stable';
    }

    return MemoryGrowthAnalysis(
      isGrowing: isGrowing,
      growthRateMBPerMinute: effectiveGrowthRate,
      suggestion: suggestion,
    );
  }

  /// 获取实用的调试信息
  Map<String, dynamic> getDebugInfo() {
    final memoryAnalysis = analyzeMemoryGrowth();

    // 清理失效引用
    _manualTimers.removeWhere((ref) => ref.target == null);
    _autoTimerInfos.removeWhere((info) => !info.timer.isActive);

    return {
      'activeTimers': activeTimerCount,
      'autoTrackedTimers': _autoTimerInfos.length,
      'manualTrackedTimers': _manualTimers.length,
      'activeSubscriptions': activeSubscriptionCount,
      'memoryGrowing': memoryAnalysis.isGrowing,
      'memoryGrowthRate':
          '${memoryAnalysis.growthRateMBPerMinute.toStringAsFixed(1)} MB/min',
      'suggestion': memoryAnalysis.suggestion,
      'timerInfos': activeTimerInfos, // 添加详细信息
    };
  }

  /// 创建用于自动追踪的 ZoneSpecification
  ///
  /// 由 DevPanel.init() 或手动在 runZonedGuarded 中使用
  ZoneSpecification createAutoTrackingZone() {
    if (!kDebugMode) {
      return const ZoneSpecification();
    }

    // 使用 print 而不是 debugPrint 避免可能的 Timer 创建
    if (kDebugMode) {
      print('LeakDetector: Auto-tracking enabled for Timers');
    }

    return ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        Timer? timer;
        timer = parent.createTimer(zone, duration, () {
          f();
          // Timer 执行完成后自动移除
          if (timer != null) {
            _autoTimerInfos.removeWhere((info) => info.timer == timer);
          }
        });
        _trackAutoTimer(timer, isPeriodic: false);
        return timer;
      },
      createPeriodicTimer: (self, parent, zone, period, f) {
        final timer = parent.createPeriodicTimer(zone, period, f);
        _trackAutoTimer(timer, isPeriodic: true);
        return timer;
      },
    );
  }

  /// 清理数据
  void clear() {
    _manualTimers.clear();
    _autoTimerInfos.clear();
    _activeSubscriptions.clear();
    _memorySnapshots.clear();
    _snapshotTimes.clear();
    _lastSnapshotTime = null;
  }
}

/// 内存增长分析结果
class MemoryGrowthAnalysis {
  final bool isGrowing;
  final double growthRateMBPerMinute;
  final String suggestion;

  MemoryGrowthAnalysis({
    required this.isGrowing,
    required this.growthRateMBPerMinute,
    required this.suggestion,
  });
}
