import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 日志级别
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  Color get color {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  String get levelText {
    switch (level) {
      case LogLevel.verbose:
        return 'V';
      case LogLevel.debug:
        return 'D';
      case LogLevel.info:
        return 'I';
      case LogLevel.warning:
        return 'W';
      case LogLevel.error:
        return 'E';
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

/// 开发日志管理器
class DevLogger {
  static final DevLogger _instance = DevLogger._internal();
  static DevLogger get instance => _instance;
  
  DevLogger._internal() {
    _setupErrorHandlers();
  }

  final int maxLogs = 1000;
  final Queue<LogEntry> _logs = Queue<LogEntry>();
  final StreamController<LogEntry> _logController = StreamController<LogEntry>.broadcast();
  
  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => _logs.toList();
  int get logCount => _logs.length;
  
  // Setup Flutter error handlers to capture all errors
  void _setupErrorHandlers() {
    if (!kReleaseMode) {
      // Capture Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        error(
          'Flutter Error: ${details.exceptionAsString()}',
          error: details.exception?.toString(),
          stackTrace: details.stack?.toString(),
        );
      };
      
      // Capture uncaught async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        this.error(
          'Uncaught Error',
          error: error.toString(),
          stackTrace: stack.toString(),
        );
        return true;
      };
    }
  }
  
  void _addLog(LogLevel level, String message, {String? error, String? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
    
    _logs.addLast(entry);
    if (_logs.length > maxLogs) {
      _logs.removeFirst();
    }
    
    _logController.add(entry);
    
    // Also print to console in debug mode
    if (kDebugMode) {
      final prefix = '[${entry.levelText}] ${entry.formattedTime}';
      debugPrint('$prefix: $message');
      if (error != null) {
        debugPrint('  Error: $error');
      }
      if (stackTrace != null && level == LogLevel.error) {
        debugPrint('  Stack: $stackTrace');
      }
    }
  }
  
  // Public logging methods
  void verbose(String message) => _addLog(LogLevel.verbose, message);
  void debug(String message) => _addLog(LogLevel.debug, message);
  void info(String message) => _addLog(LogLevel.info, message);
  void warning(String message, {String? error}) => _addLog(LogLevel.warning, message, error: error);
  void error(String message, {String? error, String? stackTrace}) {
    _addLog(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
  
  // Static convenience methods that mirror print
  static void log(String message) => instance.info(message);
  static void logDebug(String message) => instance.debug(message);
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    instance.error(message, error: error?.toString(), stackTrace: stackTrace?.toString());
  }
  
  void clear() {
    _logs.clear();
  }
  
  void dispose() {
    _logController.close();
  }
  
  // Filter logs by level
  List<LogEntry> getFilteredLogs({LogLevel? minLevel, String? filter}) {
    var filtered = logs;
    
    if (minLevel != null) {
      filtered = filtered.where((log) => log.level.index >= minLevel.index).toList();
    }
    
    if (filter != null && filter.isNotEmpty) {
      final lowerFilter = filter.toLowerCase();
      filtered = filtered.where((log) => 
        log.message.toLowerCase().contains(lowerFilter) ||
        (log.error?.toLowerCase().contains(lowerFilter) ?? false)
      ).toList();
    }
    
    return filtered;
  }
}

// Global convenience function to replace print in dev panel
void devLog(String message) => DevLogger.log(message);