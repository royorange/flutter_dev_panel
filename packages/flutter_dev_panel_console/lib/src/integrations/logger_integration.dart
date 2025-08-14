import 'package:flutter/foundation.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

/// Logger package integration helper for Flutter Dev Panel.
/// 
/// This provides a way to integrate with Logger package without
/// requiring a direct dependency on it.
/// 
/// Usage in your app:
/// ```dart
/// import 'package:logger/logger.dart';
/// import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
/// 
/// class DevPanelLogOutput extends LogOutput {
///   final LogOutput baseOutput;
///   
///   DevPanelLogOutput({LogOutput? baseOutput}) 
///     : baseOutput = baseOutput ?? ConsoleOutput();
///   
///   @override
///   void output(OutputEvent event) {
///     baseOutput.output(event);
///     DevPanelLogger.capture(event); // Use our helper
///   }
///   
///   @override
///   Future<void> destroy() async {
///     await baseOutput.destroy();
///   }
/// }
/// 
/// // Then use it:
/// final logger = Logger(
///   output: DevPanelLogOutput(),
///   printer: PrettyPrinter(),
/// );
/// ```
class DevPanelLogger {
  /// Captures Logger output to Dev Panel.
  /// Pass the OutputEvent from Logger's output() method.
  static void capture(dynamic event) {
    if (!kDebugMode || event == null) return;
    
    try {
      // Extract lines from event (Logger's OutputEvent has a lines property)
      final lines = _getLines(event);
      if (lines == null || lines.isEmpty) return;
      
      final message = lines.join('\n');
      
      // Extract level from event
      final levelName = _getLevelName(event);
      
      // Map to DevLogger levels
      if (levelName == 'error' || levelName == 'fatal' || levelName == 'wtf') {
        DevLogger.instance.error(message);
      } else if (levelName == 'warning') {
        DevLogger.instance.warning(message);
      } else if (levelName == 'info') {
        DevLogger.instance.info(message);
      } else if (levelName == 'debug') {
        DevLogger.instance.debug(message);
      } else if (levelName == 'trace' || levelName == 'verbose') {
        DevLogger.instance.verbose(message);
      } else {
        DevLogger.instance.info(message);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DevPanelLogger: Failed to capture log: $e');
      }
    }
  }
  
  static List<String>? _getLines(dynamic event) {
    try {
      // Try to access event.lines
      final lines = event.lines;
      if (lines is List<String>) {
        return lines;
      }
      // Try to convert to list of strings
      if (lines is List) {
        return lines.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return null;
  }
  
  static String? _getLevelName(dynamic event) {
    try {
      // Try to access event.level.name
      final level = event.level;
      if (level != null) {
        // Try different ways to get the level name
        try {
          return level.name?.toString();
        } catch (_) {}
        
        // Fallback to toString
        final levelStr = level.toString().toLowerCase();
        if (levelStr.contains('error')) return 'error';
        if (levelStr.contains('warning')) return 'warning';
        if (levelStr.contains('info')) return 'info';
        if (levelStr.contains('debug')) return 'debug';
        if (levelStr.contains('trace')) return 'trace';
        if (levelStr.contains('verbose')) return 'verbose';
      }
    } catch (_) {}
    return null;
  }
}

