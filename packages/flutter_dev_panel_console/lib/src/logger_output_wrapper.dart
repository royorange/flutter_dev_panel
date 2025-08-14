import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// A wrapper for Logger package's LogOutput that conditionally captures logs
/// to Flutter Dev Panel in debug mode.
/// 
/// This approach is safer as it wraps an existing LogOutput rather than
/// trying to create one.
/// 
/// Usage:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// final logger = Logger(
///   output: DevPanelLogOutputWrapper(ConsoleOutput()),
///   printer: PrettyPrinter(...),
/// );
/// ```
/// 
/// In debug mode: Captures logs to Dev Panel AND forwards to wrapped output
/// In release mode: Simply forwards to wrapped output (no overhead)
class DevPanelLogOutputWrapper {
  final dynamic _wrappedOutput;
  
  DevPanelLogOutputWrapper(this._wrappedOutput);
  
  void output(dynamic event) {
    // Always forward to the wrapped output
    if (_wrappedOutput != null) {
      _wrappedOutput.output(event);
    }
    
    // In debug mode, also capture to Dev Panel
    if (kDebugMode) {
      _captureToDevPanel(event);
    }
  }
  
  void _captureToDevPanel(dynamic event) {
    if (event == null) return;
    
    try {
      // Access event.lines which contains the formatted output
      final lines = event.lines as List<String>?;
      
      if (lines == null || lines.isEmpty) return;
      
      // Combine all lines into a single message
      final message = lines.join('\n');
      
      // Determine log level from the event
      final level = event.level;
      
      // Map logger levels to DevLogger levels
      if (level?.name == 'error' || level?.name == 'wtf') {
        DevLogger.instance.error(message);
      } else if (level?.name == 'warning') {
        DevLogger.instance.warning(message);
      } else if (level?.name == 'info') {
        DevLogger.instance.info(message);
      } else if (level?.name == 'debug') {
        DevLogger.instance.debug(message);
      } else if (level?.name == 'verbose' || level?.name == 'trace') {
        DevLogger.instance.verbose(message);
      } else {
        // Default to info for unknown levels
        DevLogger.instance.info(message);
      }
    } catch (e) {
      // Silently ignore errors to not interfere with normal logging
      if (kDebugMode) {
        debugPrint('DevPanelLogOutputWrapper: Failed to capture log: $e');
      }
    }
  }
}

/// Convenience method to wrap an existing LogOutput
/// 
/// Usage:
/// ```dart
/// final logger = Logger(
///   output: wrapLogOutput(ConsoleOutput()),
///   printer: PrettyPrinter(...),
/// );
/// ```
dynamic wrapLogOutput(dynamic logOutput) {
  if (kDebugMode) {
    return DevPanelLogOutputWrapper(logOutput);
  }
  // In release mode, return the original output unchanged
  return logOutput;
}