import 'package:flutter/material.dart';

/// 开发模块基类
abstract class DevModule {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool enabled;
  final int order;

  const DevModule({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.enabled = true,
    this.order = 0,
  });

  /// 构建模块页面
  Widget buildPage(BuildContext context);
  
  /// 构建快速操作组件（可选）
  Widget? buildQuickAction(BuildContext context) => null;
  
  /// 构建FAB显示内容（可选）
  /// 返回要在FAB中显示的widget，返回null表示不显示
  Widget? buildFabContent(BuildContext context) => null;
  
  /// FAB内容的优先级（数字越小优先级越高）
  int get fabPriority => 100;
  
  /// 初始化模块（可选）
  Future<void> initialize() async {}
  
  /// 销毁模块（可选）
  void dispose() {}
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'enabled': enabled,
      'order': order,
    };
  }
}