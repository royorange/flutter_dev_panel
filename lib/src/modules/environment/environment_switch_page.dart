import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/environment_manager.dart';
import '../../models/environment.dart';
import 'environment_edit_dialog.dart';

class EnvironmentSwitchPage extends StatelessWidget {
  const EnvironmentSwitchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EnvironmentManager>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('环境切换'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEnvironmentDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        final environments = controller.environments;
        final currentEnv = controller.currentEnvironment;
        
        if (environments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.dns_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  '暂无环境配置',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddEnvironmentDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('添加环境'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: environments.length,
          itemBuilder: (context, index) {
            final env = environments[index];
            final isActive = currentEnv?.name == env.name;
            
            return Card(
              elevation: isActive ? 4 : 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.withValues(alpha: 0.3),
                  child: Icon(
                    Icons.dns,
                    color: isActive ? Colors.white : Colors.grey,
                  ),
                ),
                title: Text(
                  env.name,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (env.config['api_url'] != null)
                      Text(
                        'API: ${env.config['api_url']}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (env.lastUsed != null)
                      Text(
                        '最后使用: ${_formatLastUsed(env.lastUsed!)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'activate':
                            controller.switchEnvironment(env.name);
                            Get.snackbar(
                              '环境已切换',
                              '已切换到 ${env.name}',
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 2),
                            );
                            break;
                          case 'edit':
                            _showEditEnvironmentDialog(context, env);
                            break;
                          case 'delete':
                            _confirmDelete(context, controller, env);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isActive)
                          const PopupMenuItem(
                            value: 'activate',
                            child: Text('激活'),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('编辑'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除'),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  if (!isActive) {
                    controller.switchEnvironment(env.name);
                    Get.snackbar(
                      '环境已切换',
                      '已切换到 ${env.name}',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _loadDefaultEnvironments(context),
        icon: const Icon(Icons.restore),
        label: const Text('加载默认环境'),
      ),
    );
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }

  void _showAddEnvironmentDialog(BuildContext context) {
    Get.dialog(const EnvironmentEditDialog());
  }

  void _showEditEnvironmentDialog(BuildContext context, Environment env) {
    Get.dialog(EnvironmentEditDialog(environment: env));
  }

  void _confirmDelete(BuildContext context, EnvironmentManager controller, Environment env) {
    Get.dialog(
      AlertDialog(
        title: const Text('删除环境'),
        content: Text('确定要删除环境 "${env.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              controller.removeEnvironment(env.name);
              Get.back();
              Get.snackbar(
                '已删除',
                '环境 "${env.name}" 已删除',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _loadDefaultEnvironments(BuildContext context) {
    final controller = Get.find<EnvironmentManager>();
    final defaults = Environment.defaultEnvironments();
    
    for (final env in defaults) {
      if (!controller.environments.any((e) => e.name == env.name)) {
        controller.addEnvironment(env);
      }
    }
    
    Get.snackbar(
      '默认环境已加载',
      '已添加 ${defaults.length} 个默认环境',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}