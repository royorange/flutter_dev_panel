import 'package:flutter/material.dart';
import '../../core/environment_manager.dart';
import '../../models/environment.dart';

class EnvironmentEditDialog extends StatefulWidget {
  final Environment? environment;
  
  const EnvironmentEditDialog({
    super.key,
    this.environment,
  });

  @override
  State<EnvironmentEditDialog> createState() => _EnvironmentEditDialogState();
}

class _EnvironmentEditDialogState extends State<EnvironmentEditDialog> {
  final _nameController = TextEditingController();
  final _configControllers = <String, TextEditingController>{};
  final _newKeyController = TextEditingController();
  final _newValueController = TextEditingController();
  
  late Map<String, dynamic> _config;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.environment != null) {
      _nameController.text = widget.environment!.name;
      _config = Map<String, dynamic>.from(widget.environment!.config);
    } else {
      _config = {
        'api_url': '',
        'timeout': '30000',
        'debug': 'true',
      };
    }
    
    // Create controllers for each config entry
    _config.forEach((key, value) {
      _configControllers[key] = TextEditingController(text: value.toString());
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _newKeyController.dispose();
    _newValueController.dispose();
    for (final controller in _configControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.environment == null ? '添加环境' : '编辑环境'),
      content: SingleChildScrollView(
        child: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '环境名称',
                  hintText: '例如: 开发环境',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '配置参数',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._buildConfigFields(),
              const SizedBox(height: 8),
              _buildAddConfigField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.environment == null ? '添加' : '保存'),
        ),
      ],
    );
  }
  
  List<Widget> _buildConfigFields() {
    return _configControllers.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  hintText: '输入值',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        _configControllers.remove(entry.key);
                        _config.remove(entry.key);
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Widget _buildAddConfigField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '添加新参数',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newKeyController,
                    decoration: const InputDecoration(
                      hintText: '键',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _newValueController,
                    decoration: const InputDecoration(
                      hintText: '值',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addNewConfig,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _addNewConfig() {
    final key = _newKeyController.text.trim();
    final value = _newValueController.text.trim();
    
    if (key.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入键和值'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    if (_configControllers.containsKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('参数 "$key" 已存在'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _configControllers[key] = TextEditingController(text: value);
      _config[key] = value;
      _newKeyController.clear();
      _newValueController.clear();
    });
  }
  
  void _save() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入环境名称'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Update config from controllers
    final updatedConfig = <String, dynamic>{};
    _configControllers.forEach((key, controller) {
      final value = controller.text.trim();
      if (value.isNotEmpty) {
        // Try to parse as number or boolean
        if (value == 'true' || value == 'false') {
          updatedConfig[key] = value == 'true';
        } else if (int.tryParse(value) != null) {
          updatedConfig[key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          updatedConfig[key] = double.parse(value);
        } else {
          updatedConfig[key] = value;
        }
      }
    });
    
    final controller = EnvironmentManager.instance;
    
    if (widget.environment == null) {
      // Add new environment
      final env = Environment(
        name: name,
        config: updatedConfig,
      );
      controller.addEnvironment(env);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('环境 "$name" 已添加'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Update existing environment
      controller.updateEnvironment(widget.environment!.name, updatedConfig);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('环境 "$name" 已更新'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}