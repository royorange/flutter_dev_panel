import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../core/module_registry.dart';

/// 开发面板主界面
class DevPanel extends StatefulWidget {
  const DevPanel({super.key});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> {
  final controller = DevPanelController.instance;
  final moduleRegistry = ModuleRegistry.instance;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: moduleRegistry,
      builder: (context, _) {
        final modules = moduleRegistry.getEnabledModules();
        
        if (modules.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('开发面板'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text('暂无可用模块'),
            ),
          );
        }

        return DefaultTabController(
          length: modules.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('开发面板'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              bottom: TabBar(
                isScrollable: true,
                tabs: modules.map((module) {
                  return Tab(
                    icon: Icon(module.icon),
                    text: module.name,
                  );
                }).toList(),
              ),
            ),
            body: TabBarView(
              children: modules.map((module) {
                return module.buildPage(context);
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}