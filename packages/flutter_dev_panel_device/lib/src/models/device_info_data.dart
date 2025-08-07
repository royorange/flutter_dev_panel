import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoData {
  final String platform;
  final String deviceModel;
  final String deviceId;
  final String osVersion;
  final String manufacturer;
  final bool isPhysicalDevice;
  final Map<String, dynamic> rawData;
  
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String? installerStore;
  
  final double screenWidth;
  final double screenHeight;
  final double devicePixelRatio;
  final double textScaleFactor;
  final String orientation;
  
  DeviceInfoData({
    required this.platform,
    required this.deviceModel,
    required this.deviceId,
    required this.osVersion,
    required this.manufacturer,
    required this.isPhysicalDevice,
    required this.rawData,
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    this.installerStore,
    required this.screenWidth,
    required this.screenHeight,
    required this.devicePixelRatio,
    required this.textScaleFactor,
    required this.orientation,
  });
  
  static Future<DeviceInfoData> collect() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    String platform = '';
    String deviceModel = '';
    String deviceId = '';
    String osVersion = '';
    String manufacturer = '';
    bool isPhysicalDevice = true;
    Map<String, dynamic> rawData = {};
    
    if (kIsWeb) {
      platform = 'Web';
      final webInfo = await deviceInfo.webBrowserInfo;
      deviceModel = webInfo.browserName.name;
      deviceId = webInfo.userAgent ?? '';
      osVersion = webInfo.platform ?? '';
      manufacturer = webInfo.vendor ?? '';
      rawData = webInfo.data;
    } else if (Platform.isAndroid) {
      platform = 'Android';
      final androidInfo = await deviceInfo.androidInfo;
      deviceModel = androidInfo.model;
      deviceId = androidInfo.id;
      osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      manufacturer = androidInfo.manufacturer;
      isPhysicalDevice = androidInfo.isPhysicalDevice;
      rawData = androidInfo.data;
    } else if (Platform.isIOS) {
      platform = 'iOS';
      final iosInfo = await deviceInfo.iosInfo;
      deviceModel = iosInfo.model;
      deviceId = iosInfo.identifierForVendor ?? '';
      osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      manufacturer = 'Apple';
      isPhysicalDevice = iosInfo.isPhysicalDevice;
      rawData = iosInfo.data;
    } else if (Platform.isMacOS) {
      platform = 'macOS';
      final macInfo = await deviceInfo.macOsInfo;
      deviceModel = macInfo.model;
      deviceId = macInfo.systemGUID ?? '';
      osVersion = 'macOS ${macInfo.majorVersion}.${macInfo.minorVersion}.${macInfo.patchVersion}';
      manufacturer = 'Apple';
      rawData = macInfo.data;
    } else if (Platform.isWindows) {
      platform = 'Windows';
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceModel = windowsInfo.computerName;
      deviceId = windowsInfo.deviceId;
      osVersion = 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion} (Build ${windowsInfo.buildNumber})';
      manufacturer = 'Microsoft';
      rawData = windowsInfo.data;
    } else if (Platform.isLinux) {
      platform = 'Linux';
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceModel = linuxInfo.name;
      deviceId = linuxInfo.machineId ?? '';
      osVersion = '${linuxInfo.name} ${linuxInfo.version}';
      manufacturer = linuxInfo.variant ?? '';
      rawData = linuxInfo.data;
    }
    
    return DeviceInfoData(
      platform: platform,
      deviceModel: deviceModel,
      deviceId: deviceId,
      osVersion: osVersion,
      manufacturer: manufacturer,
      isPhysicalDevice: isPhysicalDevice,
      rawData: rawData,
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      installerStore: packageInfo.installerStore,
      screenWidth: 0,
      screenHeight: 0,
      devicePixelRatio: 0,
      textScaleFactor: 0,
      orientation: '',
    );
  }
  
  DeviceInfoData copyWithScreenInfo({
    required double screenWidth,
    required double screenHeight,
    required double devicePixelRatio,
    required double textScaleFactor,
    required String orientation,
  }) {
    return DeviceInfoData(
      platform: platform,
      deviceModel: deviceModel,
      deviceId: deviceId,
      osVersion: osVersion,
      manufacturer: manufacturer,
      isPhysicalDevice: isPhysicalDevice,
      rawData: rawData,
      appName: appName,
      packageName: packageName,
      version: version,
      buildNumber: buildNumber,
      installerStore: installerStore,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      devicePixelRatio: devicePixelRatio,
      textScaleFactor: textScaleFactor,
      orientation: orientation,
    );
  }
  
  Map<String, String> toDisplayMap() {
    return {
      'Platform': platform,
      'Device Model': deviceModel,
      'Manufacturer': manufacturer,
      'OS Version': osVersion,
      'Physical Device': isPhysicalDevice ? 'Yes' : 'No',
      'Device ID': deviceId,
      'App Name': appName,
      'Package Name': packageName,
      'Version': version,
      'Build Number': buildNumber,
      if (installerStore != null) 'Installer Store': installerStore!,
      'Screen Width': '${screenWidth.toStringAsFixed(0)} px',
      'Screen Height': '${screenHeight.toStringAsFixed(0)} px',
      'Device Pixel Ratio': devicePixelRatio.toStringAsFixed(2),
      'Text Scale Factor': textScaleFactor.toStringAsFixed(2),
      'Orientation': orientation,
    };
  }
}