import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:logger/logger.dart';

/// LogOutput implementation that captures logs to Flutter Dev Panel.
/// 
/// This is a proper LogOutput that can be used directly with Logger package
/// without any type compatibility issues.
/// 
/// Usage:
/// ```dart
/// final logger = Logger(
///   output: DevPanelLoggerOutput(), // Zero configuration needed!
///   printer: PrettyPrinter(),
/// );
/// ```
class DevPanelLoggerOutput extends LogOutput {
  final LogOutput _baseOutput;
  
  /// Creates a LogOutput that captures to Dev Panel.
  /// 
  /// [baseOutput] - Optional base output. Defaults to ConsoleOutput.
  DevPanelLoggerOutput({LogOutput? baseOutput}) 
    : _baseOutput = baseOutput ?? ConsoleOutput();
  
  @override
  void output(OutputEvent event) {
    // Always forward to base output (console, file, etc.)
    _baseOutput.output(event);
    
    // In debug mode, also capture to Dev Panel
    if (kDebugMode) {
      _captureToDevPanel(event);
    }
  }
  
  @override
  Future<void> destroy() async {
    await _baseOutput.destroy();
  }
  
  void _captureToDevPanel(OutputEvent event) {
    try {
      final lines = event.lines;
      if (lines.isEmpty) return;
      
      final message = lines.join('\n');
      final level = event.level;
      
      // Map Logger levels to DevLogger levels
      if (level == Level.error || level == Level.fatal) {
        DevLogger.instance.error(message);
      } else if (level == Level.warning) {
        DevLogger.instance.warning(message);
      } else if (level == Level.info) {
        DevLogger.instance.info(message);
      } else if (level == Level.debug) {
        DevLogger.instance.debug(message);
      } else if (level == Level.trace) {
        DevLogger.instance.verbose(message);
      } else {
        DevLogger.instance.info(message);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DevPanelLoggerOutput: Failed to capture log: $e');
      }
    }
  }
}

/// Extension method for easy integration.
/// 
/// Usage:
/// ```dart
/// final logger = Logger(
///   output: ConsoleOutput().withDevPanel(),
///   printer: PrettyPrinter(),
/// );
/// ```
extension DevPanelLoggerExtension on LogOutput {
  /// Wraps this LogOutput to also capture logs to Dev Panel.
  LogOutput withDevPanel() {
    // In release mode, return unchanged
    if (!kDebugMode) {
      return this;
    }
    
    // In debug mode, wrap with DevPanelLoggerOutput
    return DevPanelLoggerOutput(baseOutput: this);
  }
}