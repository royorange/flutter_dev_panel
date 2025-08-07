import 'package:flutter/material.dart';
import '../../models/module.dart';
import 'device_info_page.dart';

class DeviceInfoModule extends DevModule {
  DeviceInfoModule()
      : super(
          id: 'device_info',
          name: '设备信息',
          description: '查看设备和应用信息',
          icon: Icons.phone_android,
          type: ModuleType.deviceInfo,
          enabled: true,
          order: 3,
        );

  @override
  Widget buildPage(BuildContext context) {
    return const DeviceInfoPage();
  }

  @override
  Widget? buildQuickAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_android,
            size: 16,
            color: Colors.blue,
          ),
          SizedBox(width: 4),
          Text(
            '设备信息',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}