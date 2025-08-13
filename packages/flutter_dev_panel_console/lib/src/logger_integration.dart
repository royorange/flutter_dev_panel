import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// Logger package integration for Flutter Dev Panel
/// 
/// This provides a LogOutput implementation that redirects Logger package
/// output to Flutter Dev Panel's console.
/// 
/// Usage:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// final logger = Logger(
///   output: DevPanelLogOutput(), // Use this output
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
class DevPanelLogOutput {
  /// Factory method to create appropriate output based on debug mode
  static dynamic create() {
    if (!kDebugMode) {
      // In release mode, return null to use default output
      return null;
    }
    
    // Try to create the LogOutput dynamically to avoid hard dependency
    try {
      // This will only work if logger package is available
      return _DevPanelLogOutputImpl();
    } catch (e) {
      debugPrint('DevPanelLogOutput: Logger package not found, using default output');
      return null;
    }
  }
}

/// Internal implementation that extends LogOutput
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