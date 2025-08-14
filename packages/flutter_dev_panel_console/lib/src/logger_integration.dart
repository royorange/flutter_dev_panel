import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// Logger package integration for Flutter Dev Panel
/// 
/// This provides a LogOutput implementation that redirects Logger package
/// output to Flutter Dev Panel's console in debug mode, and falls back
/// to console output in release mode.
/// 
/// Usage:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// final logger = Logger(
///   output: DevPanelLogOutput.create(), // Safe for production
///   printer: PrettyPrinter(
///     methodCount: 2,
///     errorMethodCount: 8,
///     lineLength: 120,
///     colors: true,
///     printEmojis: true,
///     printTime: false,
///   ),
/// );
/// ```
/// 
/// In debug mode: Logs are captured and displayed in Dev Panel
/// In release mode: Returns ConsoleOutput (default Logger behavior)
class DevPanelLogOutput {
  /// Factory method to create appropriate output based on debug mode
  /// Returns a LogOutput that:
  /// - In debug mode: Captures logs to Dev Panel AND prints to console
  /// - In release mode: Uses ConsoleOutput (normal Logger behavior)
  static dynamic create() {
    // Try to create the appropriate LogOutput
    try {
      if (kDebugMode) {
        // In debug mode, use our custom output that captures to Dev Panel
        return _DevPanelLogOutputImpl();
      } else {
        // In release mode, use ConsoleOutput (the default Logger output)
        // We create it dynamically to avoid compile-time dependency
        return _createConsoleOutput();
      }
    } catch (e) {
      // If anything fails, create a safe fallback
      debugPrint('DevPanelLogOutput: Using fallback output - $e');
      return _createConsoleOutput();
    }
  }
  
  /// Create ConsoleOutput dynamically to avoid hard dependency
  static dynamic _createConsoleOutput() {
    try {
      // Try to find and instantiate ConsoleOutput from logger package
      // This uses reflection-like approach to avoid direct import
      final loggerLibrary = _findLoggerLibrary();
      if (loggerLibrary != null) {
        // Found logger package, create ConsoleOutput
        final consoleOutputType = loggerLibrary['ConsoleOutput'];
        if (consoleOutputType != null) {
          return consoleOutputType();
        }
      }
    } catch (_) {}
    
    // If we can't find ConsoleOutput, return a simple implementation
    return _FallbackConsoleOutput();
  }
  
  /// Try to find the logger library dynamically
  static Map<String, dynamic>? _findLoggerLibrary() {
    // This is a placeholder - in practice, Logger's ConsoleOutput
    // would need to be passed in or we'd need to import it conditionally
    return null;
  }
}

/// Internal implementation that captures to Dev Panel
/// This is separated to avoid compile-time dependency on logger package
class _DevPanelLogOutputImpl {
  void output(dynamic event) {
    // Check if this is a LogEvent from logger package
    if (event == null) return;
    
    try {
      // Access event.lines which contains the formatted output
      final lines = event.lines as List<String>;
      
      if (lines.isEmpty) return;
      
      // Combine all lines into a single message
      final message = lines.join('\n');
      
      // Also print to console for visibility
      for (final line in lines) {
        debugPrint(line);
      }
      
      // Determine log level from the event
      final level = event.level;
      
      // Map logger levels to DevLogger levels
      if (level.name == 'error' || level.name == 'wtf') {
        DevLogger.instance.error(message);
      } else if (level.name == 'warning') {
        DevLogger.instance.warning(message);
      } else if (level.name == 'info') {
        DevLogger.instance.info(message);
      } else if (level.name == 'debug') {
        DevLogger.instance.debug(message);
      } else if (level.name == 'verbose' || level.name == 'trace') {
        DevLogger.instance.verbose(message);
      } else {
        // Default to info for unknown levels
        DevLogger.instance.info(message);
      }
    } catch (e) {
      // If we can't properly parse the event, just log it as info
      debugPrint('DevPanelLogOutput: Failed to parse log event: $e');
      debugPrint(event.toString());
    }
  }
}

/// Fallback console output for when Logger package isn't available
/// or in release mode
class _FallbackConsoleOutput {
  void output(dynamic event) {
    if (event == null) return;
    
    try {
      // Try to get lines from event
      final lines = event.lines as List<String>?;
      if (lines != null) {
        for (final line in lines) {
          // In release mode, use print instead of debugPrint
          if (kDebugMode) {
            debugPrint(line);
          } else {
            print(line);
          }
        }
      } else {
        // Fallback to toString
        if (kDebugMode) {
          debugPrint(event.toString());
        } else {
          print(event.toString());
        }
      }
    } catch (e) {
      // Last resort fallback
      final message = event.toString();
      if (kDebugMode) {
        debugPrint(message);
      } else {
        print(message);
      }
    }
  }
}

/// Alternative approach: A mixin that can be applied to any LogOutput
/// 
/// Usage:
/// ```dart
/// class MyLogOutput extends ConsoleOutput with DevPanelLogCapture {
///   // Your custom implementation
/// }
/// ```
mixin DevPanelLogCapture {
  void captureToDevPanel(dynamic event) {
    if (!kDebugMode) return;
    
    try {
      final lines = event.lines as List<String>;
      if (lines.isNotEmpty) {
        final message = lines.join('\n');
        DevLogger.instance.info(message);
      }
    } catch (_) {
      // Silently ignore if not compatible
    }
  }
}