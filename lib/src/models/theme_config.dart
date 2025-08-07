import 'package:flutter/material.dart';

enum ThemeType {
  system,
  light,
  dark,
}

class ThemeConfig {
  final ThemeType type;
  final Color? primaryColor;
  final Color? accentColor;
  final bool useMaterial3;

  const ThemeConfig({
    this.type = ThemeType.system,
    this.primaryColor,
    this.accentColor,
    this.useMaterial3 = true,
  });

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.light,
      primaryColor: primaryColor ?? Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor ?? Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.dark,
      primaryColor: primaryColor ?? Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor ?? Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }

  ThemeConfig copyWith({
    ThemeType? type,
    Color? primaryColor,
    Color? accentColor,
    bool? useMaterial3,
  }) {
    return ThemeConfig(
      type: type ?? this.type,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'primaryColor': primaryColor?.value,
      'accentColor': accentColor?.value,
      'useMaterial3': useMaterial3,
    };
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      type: ThemeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ThemeType.system,
      ),
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : null,
      accentColor: json['accentColor'] != null
          ? Color(json['accentColor'] as int)
          : null,
      useMaterial3: json['useMaterial3'] as bool? ?? true,
    );
  }
}