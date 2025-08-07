import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/dev_panel_controller.dart';
import 'core/module_manager.dart';
import 'models/module.dart';

class DevPanel extends StatelessWidget {
  const DevPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DevPanelController.to;
    final moduleManager = controller.moduleManager;
    
    return GetX<ModuleManager>(
      init: moduleManager,
      builder: (_) {
        final modules = moduleManager.getEnabledModules();
        
        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Flutter Dev Panel'),
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => controller.hide(),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettings(context),
                  ),
                ],
              ),
              body: modules.isEmpty
                  ? _buildEmptyState(context)
                  : _buildModuleGrid(context, modules),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无启用的模块',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请在设置中启用需要的功能模块',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings),
            label: const Text('打开设置'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModuleGrid(BuildContext context, List<DevModule> modules) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(context, module);
      },
    );
  }
  
  Widget _buildModuleCard(BuildContext context, DevModule module) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => module.buildPage(context),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                module.icon,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                module.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                module.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (module.buildQuickAction(context) != null) ...[
                const SizedBox(height: 8),
                module.buildQuickAction(context)!,
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSettings(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('设置'),
        content: const Text('设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}