import 'package:flutter/material.dart';

enum ModuleType {
  network,
  performance,
  deviceInfo,
  environment,
  custom,
}

abstract class DevModule {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final ModuleType type;
  final bool enabled;
  final int order;

  const DevModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.enabled = true,
    this.order = 0,
  });

  Widget buildPage(BuildContext context);
  
  Widget? buildQuickAction(BuildContext context) => null;
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'enabled': enabled,
      'order': order,
    };
  }
}