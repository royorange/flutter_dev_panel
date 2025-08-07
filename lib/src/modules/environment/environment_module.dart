import 'package:flutter/material.dart';
import '../../models/module.dart';
import 'environment_switch_page.dart';

class EnvironmentModule extends DevModule {
  EnvironmentModule()
      : super(
          id: 'environment',
          name: '环境切换',
          description: '切换开发、测试、生产环境',
          icon: Icons.dns,
          type: ModuleType.environment,
          enabled: true,
          order: 2,
        );

  @override
  Widget buildPage(BuildContext context) {
    return const EnvironmentSwitchPage();
  }

  @override
  Widget? buildQuickAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.dns,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            '当前环境',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}