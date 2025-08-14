import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// Logger package integration output for Flutter Dev Panel.
/// 
/// This provides a LogOutput implementation specifically designed for
/// the Logger package (https://pub.dev/packages/logger).
/// 
/// Features:
/// - In debug mode: Captures logs to Dev Panel AND outputs to console
/// - In release mode: Only outputs to console (zero overhead)
/// - Automatically handles ConsoleOutput internally
/// 
/// Usage:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// final logger = Logger(
///   output: DevPanelLoggerOutput(),  // That's it!
///   printer: PrettyPrinter(...),
/// );
/// ```
/// 
/// Advanced usage with custom base output:
/// ```dart
/// final logger = Logger(
///   output: DevPanelLoggerOutput(baseOutput: FileOutput()),
///   printer: PrettyPrinter(...),
/// );
/// ```
class DevPanelLoggerOutput {
  final dynamic baseOutput;
  late final dynamic _actualOutput;
  
  /// Creates a LogOutput for Logger package.
  /// 
  /// [baseOutput] - Optional base LogOutput to use. If not provided,
  /// ConsoleOutput will be used by default.
  DevPanelLoggerOutput({this.baseOutput}) {
    _actualOutput = _createOutput();
  }
  
  /// Creates the appropriate output based on debug mode and base output
  dynamic _createOutput() {
    // Get the base output (provided or default ConsoleOutput)
    final output = baseOutput ?? _createDefaultConsoleOutput();
    
    // In debug mode, wrap it to capture to Dev Panel
    if (kDebugMode) {
      return _DevPanelLoggerOutputImpl(output);
    }
    
    // In release mode, use the base output directly
    return output;
  }
  
  /// Create default ConsoleOutput dynamically
  dynamic _createDefaultConsoleOutput() {
    // Create a simple console output that works like Logger's ConsoleOutput
    return _DefaultConsoleOutput();
  }
  
  /// Forward the output call to the actual implementation
  void output(dynamic event) {
    _actualOutput.output(event);
  }
}

/// Internal implementation that captures to Dev Panel in debug mode
class _DevPanelLoggerOutputImpl {
  final dynamic _wrappedOutput;
  
  _DevPanelLoggerOutputImpl(this._wrappedOutput);
  
  void output(dynamic event) {
    // Always forward to the wrapped output
    if (_wrappedOutput != null) {
      _wrappedOutput.output(event);
    }
    
    // Also capture to Dev Panel
    _captureToDevPanel(event);
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
        debugPrint('DevPanelLoggerOutput: Failed to capture log: $e');
      }
    }
  }
}

/// Default console output implementation
/// Mimics Logger package's ConsoleOutput behavior
class _DefaultConsoleOutput {
  void output(dynamic event) {
    if (event == null) return;
    
    try {
      // Try to get lines from event (Logger's OutputEvent has lines property)
      final lines = event.lines as List<String>?;
      if (lines != null) {
        for (final line in lines) {
          // Use debugPrint in debug mode, print in release mode
          if (kDebugMode) {
            debugPrint(line);
          } else {
            // ignore: avoid_print
            print(line);
          }
        }
      } else {
        // Fallback to toString if lines not available
        final message = event.toString();
        if (kDebugMode) {
          debugPrint(message);
        } else {
          // ignore: avoid_print
          print(message);
        }
      }
    } catch (e) {
      // Last resort fallback
      final message = event.toString();
      if (kDebugMode) {
        debugPrint('DevPanelLoggerOutput fallback: $message');
      } else {
        // ignore: avoid_print
        print(message);
      }
    }
  }
}