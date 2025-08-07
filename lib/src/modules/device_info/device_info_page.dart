import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:get/get.dart';

class DeviceInfoPage extends StatefulWidget {
  const DeviceInfoPage({super.key});

  @override
  State<DeviceInfoPage> createState() => _DeviceInfoPageState();
}

class _DeviceInfoPageState extends State<DeviceInfoPage> {
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _packageInfo = {};
  Map<String, dynamic> _screenInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllInfo();
  }

  Future<void> _loadAllInfo() async {
    await Future.wait([
      _loadDeviceInfo(),
      _loadPackageInfo(),
      _loadScreenInfo(),
    ]);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceData = {
          '设备类型': 'Android',
          '品牌': androidInfo.brand,
          '型号': androidInfo.model,
          '设备名称': androidInfo.device,
          'Android版本': androidInfo.version.release,
          'SDK版本': androidInfo.version.sdkInt.toString(),
          '制造商': androidInfo.manufacturer,
          '产品': androidInfo.product,
          '硬件': androidInfo.hardware,
          '主机': androidInfo.host,
          '物理设备': androidInfo.isPhysicalDevice ? '是' : '否',
          '设备ID': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          '设备类型': 'iOS',
          '设备名称': iosInfo.name,
          '系统名称': iosInfo.systemName,
          '系统版本': iosInfo.systemVersion,
          '型号': iosInfo.model,
          '本地化型号': iosInfo.localizedModel,
          '标识符': iosInfo.identifierForVendor ?? 'N/A',
          '物理设备': iosInfo.isPhysicalDevice ? '是' : '否',
          'utsname.sysname': iosInfo.utsname.sysname,
          'utsname.nodename': iosInfo.utsname.nodename,
          'utsname.release': iosInfo.utsname.release,
          'utsname.version': iosInfo.utsname.version,
          'utsname.machine': iosInfo.utsname.machine,
        };
      }
    } catch (e) {
      deviceData = {'错误': e.toString()};
    }

    setState(() {
      _deviceInfo = deviceData;
    });
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = {
          '应用名称': packageInfo.appName,
          '包名': packageInfo.packageName,
          '版本号': packageInfo.version,
          '构建号': packageInfo.buildNumber,
          '构建签名': packageInfo.buildSignature,
          '安装来源': packageInfo.installerStore ?? 'N/A',
        };
      });
    } catch (e) {
      setState(() {
        _packageInfo = {'错误': e.toString()};
      });
    }
  }

  Future<void> _loadScreenInfo() async {
    final mediaQuery = MediaQuery.of(context);
    setState(() {
      _screenInfo = {
        '屏幕宽度': '${mediaQuery.size.width.toStringAsFixed(1)} dp',
        '屏幕高度': '${mediaQuery.size.height.toStringAsFixed(1)} dp',
        '设备像素比': mediaQuery.devicePixelRatio.toStringAsFixed(2),
        '物理宽度': '${(mediaQuery.size.width * mediaQuery.devicePixelRatio).toStringAsFixed(0)} px',
        '物理高度': '${(mediaQuery.size.height * mediaQuery.devicePixelRatio).toStringAsFixed(0)} px',
        '顶部安全区': '${mediaQuery.padding.top.toStringAsFixed(1)} dp',
        '底部安全区': '${mediaQuery.padding.bottom.toStringAsFixed(1)} dp',
        '文字缩放因子': mediaQuery.textScaleFactor.toStringAsFixed(2),
        '屏幕方向': mediaQuery.orientation == Orientation.portrait ? '竖屏' : '横屏',
        '亮度模式': mediaQuery.platformBrightness == Brightness.light ? '浅色' : '深色',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备信息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAllInfo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildInfoSection('设备信息', _deviceInfo, Icons.phone_android),
                _buildInfoSection('应用信息', _packageInfo, Icons.apps),
                _buildInfoSection('屏幕信息', _screenInfo, Icons.aspect_ratio),
              ],
            ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic> info, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${info.length} 项'),
        initiallyExpanded: true,
        children: info.entries.map((entry) {
          return ListTile(
            dense: true,
            title: Text(
              entry.key,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            trailing: SelectableText(
              entry.value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: entry.value.toString()));
              Get.snackbar(
                '已复制',
                '${entry.key}: ${entry.value}',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 2),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  void _copyAllInfo() {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 设备信息 ===');
    _deviceInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    buffer.writeln('\n=== 应用信息 ===');
    _packageInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    buffer.writeln('\n=== 屏幕信息 ===');
    _screenInfo.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    Get.snackbar(
      '复制成功',
      '所有设备信息已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}