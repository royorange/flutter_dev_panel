import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io' show stdout, IOSink;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'monitoring_data_provider.dart';
import 'dev_panel_controller.dart';

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
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

/// 开发日志管理器
class DevLogger {
  static final DevLogger _instance = DevLogger._internal();
  static DevLogger get instance => _instance;
  
  // 日志捕获配置
  LogCaptureConfig _config = const LogCaptureConfig();
  LogCaptureConfig get config => _config;
  
  // 暂停状态
  bool _isPaused = false;
  bool get isPaused => _isPaused;
  
  // Logger package buffer for combining multi-line output
  final List<String> _loggerBuffer = [];
  DateTime? _loggerBufferStartTime;
  Timer? _loggerBufferTimer;
  
  // stdout interception
  IOSink? _originalStdout;
  StreamController<List<int>>? _stdoutController;
  
  DevLogger._internal() {
    _setupErrorHandlers();
    _interceptPrint();
    _interceptDeveloperLog();
    _setupFrameworkLogging();
    _interceptStdout();
    // 延迟加载配置，等待 binding 初始化
    Future.microtask(() async {
      try {
        // 等待一帧，确保 binding 已初始化
        await Future.delayed(Duration.zero);
        await _loadConfig();
      } catch (e) {
        // 忽略错误，使用默认配置
      }
    });
  }
  
  /// Load configuration from SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maxLogs = prefs.getInt('console_max_logs') ?? 1000;
      final autoScroll = prefs.getBool('console_auto_scroll') ?? true;
      final combineLoggerOutput = prefs.getBool('console_combine_logger') ?? true;
      
      _config = LogCaptureConfig(
        maxLogs: maxLogs,
        autoScroll: autoScroll,
        combineLoggerOutput: combineLoggerOutput,
      );
    } catch (e) {
      // If loading fails, keep default config
      debugPrint('Failed to load console config: $e');
    }
  }
  
  /// Save configuration to SharedPreferences
  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('console_max_logs', _config.maxLogs);
      await prefs.setBool('console_auto_scroll', _config.autoScroll);
      await prefs.setBool('console_combine_logger', _config.combineLoggerOutput);
    } catch (e) {
      debugPrint('Failed to save console config: $e');
    }
  }
  
  /// 更新日志捕获配置
  void updateConfig(LogCaptureConfig config) {
    _config = config;
    // Update max logs if changed
    while (_logs.length > config.maxLogs) {
      _logs.removeFirst();
    }
    // Save to disk
    _saveConfig();
  }

  final _logs = ListQueue<LogEntry>();
  final _logController = StreamController<LogEntry>.broadcast();
  
  int get maxLogs => _config.maxLogs;
  Stream<LogEntry> get logStream => _logController.stream;
  List<LogEntry> get logs => _logs.toList();
  int get logCount => _logs.length;
  
  Zone? _printInterceptZone;
  
  // Setup Flutter error handlers to capture all errors
  void _setupErrorHandlers() {
    if (!kReleaseMode) {
      // Capture Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        error(
          'Flutter Error: ${details.exceptionAsString()}',
          error: details.exception.toString(),
          stackTrace: details.stack.toString(),
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
  
  // Intercept print statements - this is actually handled by the main Zone
  void _interceptPrint() {
    // Print interception is handled by the Zone in main()
    // This method is kept for compatibility
  }
  
  // Intercept developer.log calls
  void _interceptDeveloperLog() {
    if (!kReleaseMode) {
      // Override developer.log using Zone
      developer.registerExtension('ext.flutter.dev_panel.log', (method, parameters) async {
        final message = parameters['message'] ?? '';
        final level = parameters['level'] ?? 'info';
        
        switch (level) {
          case 'verbose':
            verbose(message);
            break;
          case 'debug':
            debug(message);
            break;
          case 'info':
            info(message);
            break;
          case 'warning':
            warning(message);
            break;
          case 'error':
            error(message);
            break;
          default:
            info(message);
        }
        
        return developer.ServiceExtensionResponse.result('{}');
      });
    }
  }
  
  // Setup framework logging capture
  void _setupFrameworkLogging() {
    if (!kReleaseMode) {
      // Capture HTTP client logs
      // Note: This requires HttpClient.enableTimelineLogging = true
      
      // Capture debugPrint output more reliably
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addLog(LogLevel.debug, message);
        }
        // Still print to console
        debugPrintSynchronously(message, wrapWidth: wrapWidth);
      };
    }
  }
  
  // Intercept stdout to capture Logger package output
  void _interceptStdout() {
    if (!kReleaseMode && !kIsWeb) {
      try {
        // Create a custom stdout that captures output
        _stdoutController = StreamController<List<int>>.broadcast();
        
        // Listen to our custom stdout
        _stdoutController!.stream.listen((data) {
          final message = String.fromCharCodes(data);
          // Process the stdout message (Logger package writes to stdout)
          if (message.isNotEmpty && message != '\n') {
            _addLog(LogLevel.info, message.trim());
          }
        });
        
        // Note: Actually replacing stdout requires platform-specific code
        // and may not work in all environments. The Zone-based approach
        // is more reliable for Flutter apps.
      } catch (e) {
        // Stdout interception failed, fall back to Zone-based approach
        debugPrint('DevLogger: stdout interception not available: $e');
      }
    }
  }
  
  // Enable print interception for the entire app
  static void enablePrintInterception() {
    if (!kReleaseMode) {
      // Create a custom Zone that intercepts print
      final printZone = Zone.current.fork(
        specification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
            // Capture print statement
            instance._addLog(LogLevel.info, line);
            // Still print to console
            parent.print(zone, line);
          },
        ),
      );
      
      instance._printInterceptZone = printZone;
    }
  }
  
  // Run callback with print interception
  static T runWithPrintInterception<T>(T Function() callback) {
    if (!kReleaseMode && instance._printInterceptZone != null) {
      return instance._printInterceptZone!.run(callback);
    }
    return callback();
  }
  
  void _addLog(LogLevel level, String message, {String? error, String? stackTrace}) {
    // Production safety: use unified check
    if (!DevPanelController.isEnabled) {
      return;
    }
    
    // Don't capture logs when paused
    if (_isPaused) {
      return;
    }
    
    // Check if we should filter this log based on config
    if (!_shouldCaptureLog(level, message)) {
      return;
    }
    
    // Check if this is a Logger package output and we should combine it
    if (_config.combineLoggerOutput && _isLoggerPackageOutput(message)) {
      _handleLoggerPackageOutput(level, message, error: error, stackTrace: stackTrace);
      return;
    }
    
    // Parse and detect log source
    final parsedLog = _parseLogMessage(message);
    
    // Skip empty decoration lines from Logger package
    if (parsedLog.skip || parsedLog.message == null || parsedLog.message!.isEmpty) {
      return;
    }
    
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: parsedLog.level ?? level,
      message: parsedLog.message!,
      error: error,
      stackTrace: stackTrace,
    );
    
    _logs.addLast(entry);
    if (_logs.length > _config.maxLogs) {
      _logs.removeFirst();
    }
    
    _logController.add(entry);
    
    // Notify MonitoringDataProvider when logs change
    // This will trigger FAB update
    MonitoringDataProvider.instance.triggerUpdate();
    
    // Don't print to console to avoid infinite loop when intercepting print
    // The original print will still be called through the Zone
  }
  
  /// Check if message is from Logger package
  bool _isLoggerPackageOutput(String message) {
    return message.contains('┌') || 
           message.contains('├') || 
           message.contains('│') || 
           message.contains('└') ||
           message.contains('┄');
  }
  
  /// Handle Logger package multi-line output
  void _handleLoggerPackageOutput(LogLevel level, String message, {String? error, String? stackTrace}) {
    // Start or continue buffering
    _loggerBufferStartTime ??= DateTime.now();
    _loggerBuffer.add(message);
    
    // Cancel previous timer
    _loggerBufferTimer?.cancel();
    
    // Check if this is the end of a Logger block
    if (message.contains('└')) {
      // This is the end, flush the buffer
      _flushLoggerBuffer();
    } else {
      // Wait a bit for more lines
      _loggerBufferTimer = Timer(const Duration(milliseconds: 50), () {
        _flushLoggerBuffer();
      });
    }
  }
  
  /// Flush the Logger buffer as a single log entry
  /// 
  /// This method is critical for handling Logger package's multi-line output.
  /// Logger package prints each line separately (with box-drawing characters),
  /// which would create multiple log entries if not properly combined.
  /// 
  /// This method:
  /// 1. Combines all buffered lines into a single log entry
  /// 2. Detects the appropriate log level from emoji/text indicators
  /// 3. Cleans up box-drawing characters and ANSI color codes
  /// 4. Triggers FAB update via MonitoringDataProvider
  /// 
  /// IMPORTANT: Must call MonitoringDataProvider.instance.triggerUpdate() 
  /// after adding the log, otherwise FAB won't update for Logger package logs.
  void _flushLoggerBuffer() {
    if (_loggerBuffer.isEmpty) return;
    
    // Combine all lines
    final combinedMessage = _loggerBuffer.join('\n');
    
    // Detect log level from the combined message
    LogLevel detectedLevel = LogLevel.info;
    if (combinedMessage.contains('⛔') || combinedMessage.contains('Error')) {
      detectedLevel = LogLevel.error;
    } else if (combinedMessage.contains('⚠️') || combinedMessage.contains('Warning')) {
      detectedLevel = LogLevel.warning;
    } else if (combinedMessage.contains('🐛') || combinedMessage.contains('Debug')) {
      detectedLevel = LogLevel.debug;
    } else if (combinedMessage.contains('💡') || combinedMessage.contains('Info')) {
      detectedLevel = LogLevel.info;
    }
    
    // Clean up the message for display
    String cleanMessage = combinedMessage
        // Remove box drawing characters but keep emojis
        .replaceAll(RegExp(r'[┌─├│└╟╚╔╗╝═║╠┄]'), '')
        // Remove ANSI escape sequences (color codes) but preserve the content
        .replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')
        .replaceAll(RegExp(r'\[38;5;\d+m'), '')
        .replaceAll(RegExp(r'\[\d+m'), '')
        .replaceAll('[0m', '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
    
    // Extract main message and stack trace if present
    String? mainMessage;
    String? stackTrace;
    
    final lines = cleanMessage.split('\n');
    if (lines.isNotEmpty) {
      // First line is usually the main message
      mainMessage = lines[0];
      
      // If there are more lines and they look like stack trace, treat them as such
      if (lines.length > 1) {
        final stackLines = lines.sublist(1);
        if (stackLines.any((line) => line.contains('#') || line.contains('package:'))) {
          stackTrace = stackLines.join('\n');
        } else {
          // Not a stack trace, include in main message
          mainMessage = cleanMessage;
        }
      }
    }
    
    // Create a single log entry
    final entry = LogEntry(
      timestamp: _loggerBufferStartTime ?? DateTime.now(),
      level: detectedLevel,
      message: mainMessage ?? cleanMessage,
      error: null,
      stackTrace: stackTrace,
    );
    
    _logs.addLast(entry);
    if (_logs.length > _config.maxLogs) {
      _logs.removeFirst();
    }
    
    _logController.add(entry);
    
    // Notify MonitoringDataProvider when logs change
    // This will trigger FAB update
    MonitoringDataProvider.instance.triggerUpdate();
    
    // Clear buffer
    _loggerBuffer.clear();
    _loggerBufferStartTime = null;
    _loggerBufferTimer?.cancel();
    _loggerBufferTimer = null;
  }
  
  /// Check if a log should be captured based on config
  bool _shouldCaptureLog(LogLevel level, String message) {
    // Always capture all logs that come through print/Zone
    // System logs (Logcat, NSLog) don't come through here anyway
    // They are printed directly to the platform's logging system
    return true;
  }
  
  // Parse log messages to detect source and level
  _ParsedLog _parseLogMessage(String message) {
    // Check for Logger package format (e.g., "│ ⛔ Error message")
    if (message.contains('│') || message.contains('┌') || message.contains('└') || message.contains('├') || message.contains('┄')) {
      // Logger package format detected
      LogLevel? level;
      String cleanMessage = message;
      
      // Remove Logger package decorations but keep the content
      cleanMessage = cleanMessage.replaceAll(RegExp(r'[┌─├│└╟╚╔╗╝═║╠┄]'), '').trim();
      
      // Detect level from Logger emoji/symbols
      if (message.contains('⛔') || cleanMessage.contains('Error') || message.contains('👾')) {
        level = LogLevel.error;
      } else if (message.contains('⚠️') || cleanMessage.contains('Warning')) {
        level = LogLevel.warning;  
      } else if (message.contains('💡') || cleanMessage.contains('Info')) {
        level = LogLevel.info;
      } else if (message.contains('🐛') || cleanMessage.contains('Debug')) {
        level = LogLevel.debug;
      } else if (cleanMessage.contains('Verbose') || cleanMessage.contains('Trace')) {
        level = LogLevel.verbose;
      }
      
      // For Logger package, return cleaned message
      if (cleanMessage.isNotEmpty) {
        // Remove ANSI escape sequences from the cleaned message
        cleanMessage = cleanMessage
            .replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')
            .replaceAll(RegExp(r'\[38;5;\d+m'), '')
            .replaceAll(RegExp(r'\[\d+m'), '')
            .replaceAll('[0m', '');
        return _ParsedLog(level: level, message: cleanMessage);
      } else {
        // Only skip if this is purely a Logger decoration line (only contains Logger special chars)
        // Don't skip user's intentional empty prints
        final hasOnlyLoggerChars = RegExp(r'^[┌─├│└╟╚╔╗╝═║╠┄\s]*$').hasMatch(message);
        if (hasOnlyLoggerChars) {
          return _ParsedLog(level: level, message: null, skip: true);
        } else {
          // Keep the message as is (might be intentional empty line from user)
          return _ParsedLog(level: level, message: message);
        }
      }
    }
    
    // Check for common log patterns
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.startsWith('error:') || lowerMessage.startsWith('[error]')) {
      return _ParsedLog(level: LogLevel.error, message: message);
    } else if (lowerMessage.startsWith('warning:') || lowerMessage.startsWith('[warning]') || lowerMessage.startsWith('warn:')) {
      return _ParsedLog(level: LogLevel.warning, message: message);
    } else if (lowerMessage.startsWith('info:') || lowerMessage.startsWith('[info]')) {
      return _ParsedLog(level: LogLevel.info, message: message);
    } else if (lowerMessage.startsWith('debug:') || lowerMessage.startsWith('[debug]')) {
      return _ParsedLog(level: LogLevel.debug, message: message);
    } else if (lowerMessage.startsWith('verbose:') || lowerMessage.startsWith('[verbose]')) {
      return _ParsedLog(level: LogLevel.verbose, message: message);
    }
    
    // Return the message as is, without adding [Print] prefix
    return _ParsedLog(level: null, message: message);
  }
  
  // Public logging methods - respect user's configuration
  void verbose(String message) => _addLog(LogLevel.verbose, message);
  void debug(String message) => _addLog(LogLevel.debug, message);
  void info(String message) => _addLog(LogLevel.info, message);
  void warning(String message, {String? error}) => _addLog(LogLevel.warning, message, error: error);
  void error(String message, {String? error, String? stackTrace}) {
    _addLog(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }
  
  // Static convenience methods that mirror print
  // These check isEnabled internally through _addLog
  static void log(String message) => instance.info(message);
  static void logDebug(String message) => instance.debug(message);
  static void logError(String message, {Object? error, StackTrace? stackTrace}) {
    instance.error(message, error: error?.toString(), stackTrace: stackTrace?.toString());
  }
  
  void clear() {
    _logs.clear();
    // Notify MonitoringDataProvider when logs are cleared
    MonitoringDataProvider.instance.triggerUpdate();
  }
  
  void dispose() {
    _logController.close();
  }
  
  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
  }
  
  /// Set pause state
  void setPaused(bool paused) {
    _isPaused = paused;
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

// Helper class for parsed log
class _ParsedLog {
  final LogLevel? level;
  final String? message;
  final bool skip;
  
  _ParsedLog({this.level, required this.message, this.skip = false});
}

// Global convenience function to replace print in dev panel
void devLog(String message) => DevLogger.log(message);

/// Configuration for log capture
class LogCaptureConfig {
  /// Maximum number of logs to keep in memory
  final int maxLogs;
  
  /// Auto scroll to bottom when new logs arrive
  final bool autoScroll;
  
  /// Combine Logger package multi-line output
  final bool combineLoggerOutput;
  
  const LogCaptureConfig({
    this.maxLogs = 1000,
    this.autoScroll = true,
    this.combineLoggerOutput = true,
  });
  
  LogCaptureConfig copyWith({
    int? maxLogs,
    bool? autoScroll,
    bool? combineLoggerOutput,
  }) {
    return LogCaptureConfig(
      maxLogs: maxLogs ?? this.maxLogs,
      autoScroll: autoScroll ?? this.autoScroll,
      combineLoggerOutput: combineLoggerOutput ?? this.combineLoggerOutput,
    );
  }
}