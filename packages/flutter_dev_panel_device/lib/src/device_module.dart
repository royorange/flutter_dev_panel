import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'ui/device_info_page.dart';

class DeviceModule extends DevModule {
  const DeviceModule()
      : super(
          id: 'device_info',
          name: 'Device Info',
          description: 'Display device and application information',
          icon: Icons.devices,
          enabled: true,
          order: 1,
        );
  
  @override
  Widget buildPage(BuildContext context) {
    return const DeviceInfoPage();
  }
}