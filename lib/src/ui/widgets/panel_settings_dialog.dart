import 'package:flutter/material.dart';
import '../../models/panel_settings.dart';

/// Panel settings dialog
class PanelSettingsDialog extends StatefulWidget {
  const PanelSettingsDialog({super.key});

  @override
  State<PanelSettingsDialog> createState() => _PanelSettingsDialogState();
}

class _PanelSettingsDialogState extends State<PanelSettingsDialog> {
  late bool _showEnvironmentSwitcher;
  late bool _showThemeSwitcher;
  late bool _showFab;
  late bool _enableShake;
  
  @override
  void initState() {
    super.initState();
    final settings = PanelSettings.instance;
    _showEnvironmentSwitcher = settings.showEnvironmentSwitcher;
    _showThemeSwitcher = settings.showThemeSwitcher;
    _showFab = settings.showFab;
    _enableShake = settings.enableShake;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings, size: 24),
          SizedBox(width: 8),
          Text('Panel Settings'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: const Text('Environment Switcher'),
              subtitle: const Text('Show environment selector in panel'),
              value: _showEnvironmentSwitcher,
              onChanged: (value) {
                setState(() {
                  _showEnvironmentSwitcher = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Theme Switcher'),
              subtitle: const Text('Show theme selector in panel'),
              value: _showThemeSwitcher,
              onChanged: (value) {
                setState(() {
                  _showThemeSwitcher = value;
                });
              },
            ),
            
            const Divider(),
            
            Text(
              'Access Methods',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            SwitchListTile(
              title: const Text('Floating Button'),
              subtitle: const Text('Show draggable FAB button'),
              value: _showFab,
              onChanged: (value) {
                setState(() {
                  _showFab = value;
                });
              },
            ),
            
            SwitchListTile(
              title: const Text('Shake to Open'),
              subtitle: const Text('Open panel by shaking device'),
              value: _enableShake,
              onChanged: (value) {
                setState(() {
                  _enableShake = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset to defaults
            setState(() {
              _showEnvironmentSwitcher = true;
              _showThemeSwitcher = true;
              _showFab = true;
              _enableShake = true;
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Save settings
            PanelSettings.instance.updateSettings(
              showEnvironmentSwitcher: _showEnvironmentSwitcher,
              showThemeSwitcher: _showThemeSwitcher,
              showFab: _showFab,
              enableShake: _enableShake,
            );
            Navigator.of(context).pop();
            
            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}