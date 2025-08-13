import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../core/module_registry.dart';
import '../models/panel_settings.dart';
import 'widgets/environment_switcher.dart';
import 'widgets/theme_switcher.dart';
import 'widgets/panel_settings_dialog.dart';

/// Dev Panel main interface
class DevPanel extends StatefulWidget {
  const DevPanel({super.key});

  @override
  State<DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<DevPanel> with SingleTickerProviderStateMixin {
  final controller = DevPanelController.instance;
  final moduleRegistry = ModuleRegistry.instance;
  TabController? _tabController;
  static int _lastTabIndex = 0;  // 静态变量保存上次选中的 tab
  
  @override
  void initState() {
    super.initState();
    _initTabController();
  }
  
  void _initTabController() {
    final modules = moduleRegistry.getEnabledModules();
    if (modules.isNotEmpty) {
      _tabController?.dispose();
      _tabController = TabController(
        length: modules.length,
        vsync: this,
        initialIndex: _lastTabIndex.clamp(0, modules.length - 1),
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          _lastTabIndex = _tabController!.index;
        }
      });
    }
  }
  
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

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
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsDialog(context),
                ),
              ],
            ),
            body: const Center(
              child: Text('No modules available'),
            ),
          );
        }

        // Update tab controller if modules changed
        if (_tabController == null || _tabController!.length != modules.length) {
          _initTabController();
        }
        
        return Scaffold(
            appBar: AppBar(
              title: const Text('Dev Panel'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsDialog(context),
                ),
              ],
            ),
            body: ListenableBuilder(
              listenable: PanelSettings.instance,
              builder: (context, _) {
                final settings = PanelSettings.instance;

                return Column(
                  children: [
                    // Environment switcher (if enabled)
                    if (settings.showEnvironmentSwitcher)
                      const EnvironmentSwitcher(),

                    // Theme switcher (if enabled)
                    if (settings.showThemeSwitcher) const ThemeSwitcher(),

                    // Only show divider if any switcher is visible
                    if (settings.showEnvironmentSwitcher ||
                        settings.showThemeSwitcher)
                      const Divider(height: 1),

                    // Module tabs
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        indicatorPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
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
                        controller: _tabController,
                        children: modules.map((module) {
                          return module.buildPage(context);
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PanelSettingsDialog(),
    );
  }
}
