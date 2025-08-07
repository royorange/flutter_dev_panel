import 'package:flutter/material.dart';
import '../device_info_controller.dart';

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});
  
  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  late final DeviceInfoController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = DeviceInfoController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadDeviceInfo(context);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.refresh(context),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.copy_all),
            onPressed: _controller.hasData
                ? () async {
                    await _controller.copyAllToClipboard();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All device info copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
            tooltip: 'Copy All',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (_controller.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading device information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _controller.refresh(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          if (!_controller.hasData) {
            return const Center(
              child: Text('No device information available'),
            );
          }
          
          final displayMap = _controller.deviceInfo!.toDisplayMap();
          final categories = _categorizeInfo(displayMap);
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: categories.entries.map((category) {
              return _buildCategoryCard(
                context,
                category.key,
                category.value,
              );
            }).toList(),
          );
        },
      ),
    );
  }
  
  Map<String, Map<String, String>> _categorizeInfo(Map<String, String> info) {
    final categories = <String, Map<String, String>>{
      'Device': {},
      'Application': {},
      'Screen': {},
    };
    
    final deviceKeys = ['Platform', 'Device Model', 'Manufacturer', 'OS Version', 'Physical Device', 'Device ID'];
    final appKeys = ['App Name', 'Package Name', 'Version', 'Build Number', 'Installer Store'];
    final screenKeys = ['Screen Width', 'Screen Height', 'Device Pixel Ratio', 'Text Scale Factor', 'Orientation'];
    
    for (final entry in info.entries) {
      if (deviceKeys.contains(entry.key)) {
        categories['Device']![entry.key] = entry.value;
      } else if (appKeys.contains(entry.key)) {
        categories['Application']![entry.key] = entry.value;
      } else if (screenKeys.contains(entry.key)) {
        categories['Screen']![entry.key] = entry.value;
      }
    }
    
    return categories;
  }
  
  Widget _buildCategoryCard(BuildContext context, String title, Map<String, String> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _getCategoryIcon(title);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...items.entries.map((entry) {
            return _buildInfoTile(context, entry.key, entry.value);
          }),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Device':
        return Icons.devices;
      case 'Application':
        return Icons.apps;
      case 'Screen':
        return Icons.aspect_ratio;
      default:
        return Icons.info;
    }
  }
  
  Widget _buildInfoTile(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () async {
        await _controller.copyToClipboard(label, value);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label copied to clipboard'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}