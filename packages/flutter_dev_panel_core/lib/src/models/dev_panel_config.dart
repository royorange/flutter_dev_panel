import 'package:flutter/material.dart';

enum TriggerMode {
  fab,
  shake,
  manual,
}

class DevPanelConfig {
  final bool enabled;
  final Set<TriggerMode> triggerModes;
  final bool showInProduction;
  final Duration animationDuration;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;

  const DevPanelConfig({
    this.enabled = true,
    this.triggerModes = const {TriggerMode.fab},
    this.showInProduction = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.lightTheme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
  });

  DevPanelConfig copyWith({
    bool? enabled,
    Set<TriggerMode>? triggerModes,
    bool? showInProduction,
    Duration? animationDuration,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
  }) {
    return DevPanelConfig(
      enabled: enabled ?? this.enabled,
      triggerModes: triggerModes ?? this.triggerModes,
      showInProduction: showInProduction ?? this.showInProduction,
      animationDuration: animationDuration ?? this.animationDuration,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}