import 'package:flutter/material.dart';
import 'environment.dart';
import 'module.dart';
import 'theme_config.dart';

enum TriggerMode {
  fab,
  shake,
  manual,
}

class DevPanelConfig {
  final bool enabled;
  final Set<TriggerMode> triggerModes;
  final List<DevModule> modules;
  final List<Environment> environments;
  final ThemeConfig themeConfig;
  final Locale? locale;
  final bool showInProduction;
  final Duration animationDuration;

  const DevPanelConfig({
    this.enabled = true,
    this.triggerModes = const {TriggerMode.fab},
    this.modules = const [],
    this.environments = const [],
    this.themeConfig = const ThemeConfig(),
    this.locale,
    this.showInProduction = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  DevPanelConfig copyWith({
    bool? enabled,
    Set<TriggerMode>? triggerModes,
    List<DevModule>? modules,
    List<Environment>? environments,
    ThemeConfig? themeConfig,
    Locale? locale,
    bool? showInProduction,
    Duration? animationDuration,
  }) {
    return DevPanelConfig(
      enabled: enabled ?? this.enabled,
      triggerModes: triggerModes ?? this.triggerModes,
      modules: modules ?? this.modules,
      environments: environments ?? this.environments,
      themeConfig: themeConfig ?? this.themeConfig,
      locale: locale ?? this.locale,
      showInProduction: showInProduction ?? this.showInProduction,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'triggerModes': triggerModes.map((e) => e.name).toList(),
      'modules': modules.map((e) => e.toJson()).toList(),
      'environments': environments.map((e) => e.toJson()).toList(),
      'themeConfig': themeConfig.toJson(),
      'locale': locale?.languageCode,
      'showInProduction': showInProduction,
      'animationDuration': animationDuration.inMilliseconds,
    };
  }
}