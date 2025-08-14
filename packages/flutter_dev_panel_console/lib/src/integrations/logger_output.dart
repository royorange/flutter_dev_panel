import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// Creates a LogOutput adapter for Logger package integration.
/// 
/// This factory function returns a dynamic object that can be used
/// as LogOutput with the Logger package, without requiring a direct dependency.
/// 
/// Usage:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// final logger = Logger(
///   output: createDevPanelLoggerOutput(), // Returns LogOutput
///   printer: PrettyPrinter(),
/// );
/// 
/// // Or with custom base output:
/// final logger = Logger(
///   output: createDevPanelLoggerOutput(baseOutput: FileOutput()),
/// );
/// ```
/// 
/// In debug mode: Captures to Dev Panel + base output
/// In release mode: Only uses base output (zero overhead)
dynamic createDevPanelLoggerOutput({dynamic baseOutput}) {
  // If no base output provided, create a default console output
  final output = baseOutput ?? _DefaultConsoleOutput();
  
  // In debug mode, wrap to capture to Dev Panel
  if (kDebugMode) {
    return _DevPanelLoggerAdapter(output);
  }
  
  // In release mode, return base output directly
  return output;
}

/// Adapter class that captures Logger output to Dev Panel.
/// This is designed to work with Logger package's LogOutput interface
/// without directly importing or depending on it.
class _DevPanelLoggerAdapter {
  final dynamic _baseOutput;
  
  _DevPanelLoggerAdapter(this._baseOutput);
  
  /// The output method expected by Logger's LogOutput interface
  void output(dynamic event) {
    // Forward to base output
    if (_baseOutput != null) {
      _baseOutput.output(event);
    }
    
    // Capture to Dev Panel in debug mode
    if (kDebugMode) {
      _captureToDevPanel(event);
    }
  }
  
  /// The destroy method expected by Logger's LogOutput interface
  void destroy() {
    if (_baseOutput != null && _baseOutput.destroy != null) {
      _baseOutput.destroy();
    }
  }
  
  void _captureToDevPanel(dynamic event) {
    if (event == null) return;
    
    try {
      // Logger's OutputEvent has 'lines' and 'level' properties
      final lines = event.lines as List<String>?;
      if (lines == null || lines.isEmpty) return;
      
      final message = lines.join('\n');
      final level = event.level;
      
      // Map Logger levels to DevLogger levels
      final levelName = level?.name?.toString() ?? '';
      
      if (levelName == 'error' || levelName == 'wtf') {
        DevLogger.instance.error(message);
      } else if (levelName == 'warning') {
        DevLogger.instance.warning(message);
      } else if (levelName == 'info') {
        DevLogger.instance.info(message);
      } else if (levelName == 'debug') {
        DevLogger.instance.debug(message);
      } else if (levelName == 'verbose' || levelName == 'trace') {
        DevLogger.instance.verbose(message);
      } else {
        DevLogger.instance.info(message);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DevPanelLoggerAdapter: Failed to capture log: $e');
      }
    }
  }
}

/// Default console output that mimics Logger's ConsoleOutput
class _DefaultConsoleOutput {
  void output(dynamic event) {
    if (event == null) return;
    
    try {
      final lines = event.lines as List<String>?;
      if (lines != null) {
        for (final line in lines) {
          if (kDebugMode) {
            debugPrint(line);
          } else {
            // ignore: avoid_print
            print(line);
          }
        }
      }
    } catch (_) {
      final message = event.toString();
      if (kDebugMode) {
        debugPrint(message);
      } else {
        // ignore: avoid_print
        print(message);
      }
    }
  }
  
  void destroy() {
    // Nothing to destroy
  }
}

