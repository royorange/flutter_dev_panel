import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
import 'package:logger/logger.dart';

/// Example of integrating Logger package with Flutter Dev Panel
void main() {
  // Simple usage - zero configuration
  final logger = Logger(
    output: DevPanelLoggerOutput(), // That's it!
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );
  
  // Alternative: Use extension method
  final logger2 = Logger(
    output: ConsoleOutput().withDevPanel(), // Extension method
    printer: PrettyPrinter(),
  );
  
  // Advanced: With custom base output
  final logger3 = Logger(
    output: DevPanelLoggerOutput(
      baseOutput: ConsoleOutput(), // Or any LogOutput
    ),
    printer: PrettyPrinter(),
  );
  
  // Usage examples
  // logger.v("Verbose log");
  // logger.d("Debug log");
  // logger.i("Info log");
  // logger.w("Warning log");
  // logger.e("Error log", error: 'Test error', stackTrace: StackTrace.current);
  // logger.wtf("What a terrible failure log");
  
  // In debug mode:
  // - Logs will appear in the console as usual
  // - Logs will also be captured in Dev Panel's Console module
  // - You can view, filter, and search logs in the Dev Panel
  
  // In release mode:
  // - Logs will only appear in the console
  // - Dev Panel is completely disabled
  // - Zero performance overhead
}