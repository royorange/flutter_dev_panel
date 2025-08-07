import 'package:flutter/foundation.dart';

@immutable
class Environment {
  final String name;
  final Map<String, dynamic> config;
  final bool isActive;
  final DateTime? lastUsed;

  const Environment({
    required this.name,
    required this.config,
    this.isActive = false,
    this.lastUsed,
  });

  Environment copyWith({
    String? name,
    Map<String, dynamic>? config,
    bool? isActive,
    DateTime? lastUsed,
  }) {
    return Environment(
      name: name ?? this.name,
      config: config ?? this.config,
      isActive: isActive ?? this.isActive,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'config': config,
      'isActive': isActive,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  factory Environment.fromJson(Map<String, dynamic> json) {
    return Environment(
      name: json['name'] as String,
      config: Map<String, dynamic>.from(json['config'] as Map),
      isActive: json['isActive'] as bool? ?? false,
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
    );
  }

  static List<Environment> defaultEnvironments() {
    return [
      const Environment(
        name: '开发环境',
        config: {
          'api_url': 'https://dev.api.example.com',
          'timeout': 30000,
          'debug': true,
        },
      ),
      const Environment(
        name: '测试环境',
        config: {
          'api_url': 'https://test.api.example.com',
          'timeout': 30000,
          'debug': true,
        },
      ),
      const Environment(
        name: '生产环境',
        config: {
          'api_url': 'https://api.example.com',
          'timeout': 10000,
          'debug': false,
        },
      ),
    ];
  }
}