import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../core/module_registry.dart';
import 'widgets/environment_switcher.dart';
import 'widgets/theme_switcher.dart';

/// Dev Panel main interface
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
              title: const Text('Dev Panel'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text('No modules available'),
            ),
          );
        }

        return DefaultTabController(
          length: modules.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Dev Panel'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Column(
              children: [
                // Environment switcher
                const EnvironmentSwitcher(),
                
                // Theme switcher
                const ThemeSwitcher(),
                
                const Divider(height: 1),
                
                // Module tabs
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: modules.map((module) {
                      return Tab(
                        icon: Icon(module.icon),
                        text: module.name,
                      );
                    }).toList(),
                  ),
                ),
                
                // Module content
                Expanded(
                  child: TabBarView(
                    children: modules.map((module) {
                      return module.buildPage(context);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}