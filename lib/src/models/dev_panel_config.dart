import 'package:flutter/material.dart';

enum TriggerMode {
  fab,
  shake,
}

class DevPanelConfig {
  final Set<TriggerMode> triggerModes;
  final Duration animationDuration;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;
  final bool enableLogCapture;
  final bool loadFromEnvFiles;  // 是否自动加载 .env 文件

  const DevPanelConfig({
    this.triggerModes = const {TriggerMode.fab},
    this.animationDuration = const Duration(milliseconds: 300),
    this.lightTheme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.enableLogCapture = true,
    this.loadFromEnvFiles = true,  // 默认自动加载 .env 文件
  });

  DevPanelConfig copyWith({
    Set<TriggerMode>? triggerModes,
    Duration? animationDuration,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    bool? enableLogCapture,
    bool? loadFromEnvFiles,
  }) {
    return DevPanelConfig(
      triggerModes: triggerModes ?? this.triggerModes,
      animationDuration: animationDuration ?? this.animationDuration,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      enableLogCapture: enableLogCapture ?? this.enableLogCapture,
      loadFromEnvFiles: loadFromEnvFiles ?? this.loadFromEnvFiles,
    );
  }
}