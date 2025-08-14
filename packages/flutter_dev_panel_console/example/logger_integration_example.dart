import 'package:flutter_dev_panel_console/flutter_dev_panel_console.dart';
// import 'package:logger/logger.dart';

/// Example of integrating Logger package with Flutter Dev Panel
/// 
/// This example shows how to use DevPanelLoggerOutput to capture
/// Logger package output in the Dev Panel console.
void main() {
  // Simple usage - automatically uses ConsoleOutput internally
  // final logger = Logger(
  //   output: DevPanelLoggerOutput(),
  //   printer: PrettyPrinter(
  //     methodCount: 2,
  //     errorMethodCount: 8,
  //     lineLength: 120,
  //     colors: true,
  //     printEmojis: true,
  //     printTime: false,
  //   ),
  // );
  
  // Advanced usage - with custom output
  // final logger = Logger(
  //   output: DevPanelLoggerOutput(
  //     customOutput: MultiOutput([
  //       ConsoleOutput(),
  //       FileOutput(file: File('log.txt')),
  //     ]),
  //   ),
  //   printer: PrettyPrinter(),
  // );
  
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