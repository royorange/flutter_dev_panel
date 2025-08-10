# Flutter Dev Panel - Device Module

[![pub package](https://img.shields.io/pub/v/flutter_dev_panel_device.svg)](https://pub.dev/packages/flutter_dev_panel_device)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%89%A53.10.0-blue)](https://flutter.dev)

A comprehensive device information module for Flutter Dev Panel that provides detailed insights into device specifications, system information, and application details.

## Features

### Device Information
- **Hardware details** - Device model, manufacturer, and unique identifiers
- **Screen metrics** - Resolution, pixel density, aspect ratio, and physical size
- **System info** - Operating system version, SDK levels, and system features
- **Memory status** - Available and total RAM, storage information
- **Battery status** - Battery level and charging state

### Application Information
- **App details** - Package name, version, build number
- **Platform info** - Platform-specific identifiers and capabilities
- **Permissions** - Current app permissions and status
- **Build mode** - Debug, profile, or release mode detection

### Display Metrics
- **PPI calculation** - Accurate pixels per inch calculation
- **Screen dimensions** - Width, height in both pixels and physical units
- **Safe areas** - System UI insets and safe area boundaries
- **Text scale** - System text scale factor and accessibility settings

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_dev_panel_device:
    git:
      url: https://github.com/yourusername/flutter_dev_panel
      path: packages/flutter_dev_panel_device
```

Or if using a local path:

```yaml
dependencies:
  flutter_dev_panel_device:
    path: ../packages/flutter_dev_panel_device
```

## Usage

### Basic Setup

```dart
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';

void main() {
  // Initialize with device module
  FlutterDevPanel.initialize(
    modules: [
      DeviceModule(),
      // Add other modules as needed
    ],
  );
  
  runApp(MyApp());
}
```

### Accessing Device Information

```dart
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';

// Get device information controller
final controller = DeviceInfoController.instance;

// Load device information
await controller.loadDeviceInfo();

// Access device data
final deviceInfo = controller.deviceInfo;
if (deviceInfo != null) {
  print('Device: ${deviceInfo.deviceModel}');
  print('OS: ${deviceInfo.operatingSystem} ${deviceInfo.osVersion}');
  print('Screen: ${deviceInfo.screenWidth}x${deviceInfo.screenHeight}');
  print('PPI: ${deviceInfo.pixelsPerInch}');
}

// Listen to updates
controller.addListener(() {
  final info = controller.deviceInfo;
  // Handle updates
});
```

### Displaying Device Info Page

```dart
// Navigate to device info page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DeviceInfoPage(),
  ),
);

// Or use within Dev Panel
FlutterDevPanel.show(context, initialModule: 'Device Info');
```

## API Reference

### DeviceModule

The main module class that integrates with Flutter Dev Panel:

```dart
class DeviceModule extends DevModule {
  @override
  String get name => 'Device Info';
  
  @override
  IconData get icon => Icons.phone_android;
  
  @override
  Widget buildPage(BuildContext context);
}
```

### DeviceInfoController

Controls device information loading and caching:

```dart
class DeviceInfoController extends ChangeNotifier {
  static DeviceInfoController get instance;
  
  DeviceInfoData? get deviceInfo;
  bool get isLoading;
  
  Future<void> loadDeviceInfo();
  void refresh();
}
```

### DeviceInfoData

Contains all device information:

```dart
class DeviceInfoData {
  // Device basics
  final String deviceModel;
  final String manufacturer;
  final String deviceId;
  final bool isPhysicalDevice;
  
  // System information
  final String operatingSystem;
  final String osVersion;
  final int sdkInt; // Android only
  final String systemVersion; // iOS only
  
  // Screen information
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;
  final double pixelsPerInch;
  final double physicalWidth;
  final double physicalHeight;
  
  // App information
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  
  // Memory information
  final int totalMemory;
  final int freeMemory;
  final int usedMemory;
  
  // Additional platform info
  final Map<String, dynamic> additionalInfo;
}
```

## Platform-Specific Information

### Android
- Device manufacturer and model
- Android version and SDK int
- Device ID and fingerprint
- Hardware features and capabilities
- Memory and storage details

### iOS
- Device model and name
- iOS version and system name
- Unique identifier (vendor ID)
- Device orientation and idiom
- System capabilities

### Web
- Browser information
- User agent string
- Screen resolution and color depth
- Platform and vendor details
- Language preferences

### Desktop (Windows/macOS/Linux)
- Computer name and model
- Operating system details
- Processor information
- Memory specifications
- Display configuration

## Display Information

### Screen Metrics

```dart
final info = controller.deviceInfo;

// Pixel dimensions
print('Resolution: ${info.screenWidth}x${info.screenHeight}');

// Physical dimensions
print('Physical size: ${info.physicalWidth}x${info.physicalHeight} inches');

// Pixel density
print('Pixel ratio: ${info.pixelRatio}');
print('PPI: ${info.pixelsPerInch}');

// Aspect ratio
final aspectRatio = info.screenWidth / info.screenHeight;
print('Aspect ratio: ${aspectRatio.toStringAsFixed(2)}');
```

### Safe Areas and Insets

```dart
// Get safe area insets
final mediaQuery = MediaQuery.of(context);
final padding = mediaQuery.padding;
final viewInsets = mediaQuery.viewInsets;

print('Top safe area: ${padding.top}');
print('Bottom safe area: ${padding.bottom}');
print('Keyboard height: ${viewInsets.bottom}');
```

## Memory Information

```dart
final info = controller.deviceInfo;

// Memory status
print('Total RAM: ${_formatBytes(info.totalMemory)}');
print('Free RAM: ${_formatBytes(info.freeMemory)}');
print('Used RAM: ${_formatBytes(info.usedMemory)}');

// Memory percentage
final usedPercentage = (info.usedMemory / info.totalMemory * 100);
print('Memory usage: ${usedPercentage.toStringAsFixed(1)}%');

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:flutter_dev_panel_device/flutter_dev_panel_device.dart';

void main() {
  FlutterDevPanel.initialize(
    modules: [DeviceModule()],
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterDevPanel.wrap(
      child: MaterialApp(
        title: 'Device Info Demo',
        home: DeviceInfoDemo(),
      ),
    );
  }
}

class DeviceInfoDemo extends StatefulWidget {
  @override
  _DeviceInfoDemoState createState() => _DeviceInfoDemoState();
}

class _DeviceInfoDemoState extends State<DeviceInfoDemo> {
  final controller = DeviceInfoController.instance;
  
  @override
  void initState() {
    super.initState();
    controller.loadDeviceInfo();
    controller.addListener(_update);
  }
  
  @override
  void dispose() {
    controller.removeListener(_update);
    super.dispose();
  }
  
  void _update() {
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final info = controller.deviceInfo;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Information'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: controller.refresh,
          ),
        ],
      ),
      body: controller.isLoading
          ? Center(child: CircularProgressIndicator())
          : info == null
              ? Center(child: Text('Failed to load device info'))
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    _buildInfoCard('Device', [
                      _buildInfoRow('Model', info.deviceModel),
                      _buildInfoRow('Manufacturer', info.manufacturer),
                      _buildInfoRow('Physical Device', 
                        info.isPhysicalDevice ? 'Yes' : 'No (Emulator)'),
                    ]),
                    _buildInfoCard('System', [
                      _buildInfoRow('OS', info.operatingSystem),
                      _buildInfoRow('Version', info.osVersion),
                    ]),
                    _buildInfoCard('Display', [
                      _buildInfoRow('Resolution', 
                        '${info.screenWidth.toInt()}x${info.screenHeight.toInt()}'),
                      _buildInfoRow('PPI', info.pixelsPerInch.toStringAsFixed(0)),
                      _buildInfoRow('Pixel Ratio', info.pixelRatio.toString()),
                    ]),
                    _buildInfoCard('Application', [
                      _buildInfoRow('Name', info.appName),
                      _buildInfoRow('Package', info.packageName),
                      _buildInfoRow('Version', '${info.version} (${info.buildNumber})'),
                    ]),
                  ],
                ),
    );
  }
  
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
```

## Customization

### Custom Device Info Display

```dart
class CustomDeviceInfoWidget extends StatelessWidget {
  final DeviceInfoData info;
  
  const CustomDeviceInfoWidget({Key? key, required this.info}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom layout for device information
        DeviceHeader(info: info),
        SystemDetails(info: info),
        MemoryIndicator(info: info),
        // Add more custom widgets
      ],
    );
  }
}
```

### Extending Device Information

```dart
// Add custom device information
class ExtendedDeviceInfo extends DeviceInfoData {
  final String customField;
  
  ExtendedDeviceInfo({
    required super.deviceModel,
    // ... other required fields
    required this.customField,
  });
  
  factory ExtendedDeviceInfo.fromPlatformInfo(Map<String, dynamic> data) {
    // Parse platform-specific data
    return ExtendedDeviceInfo(
      // ... map fields
      customField: data['custom'] ?? 'Unknown',
    );
  }
}
```

## Performance Considerations

- Device information is cached after first load
- Refresh manually when needed to avoid repeated platform calls
- Consider lazy loading for expensive operations
- Use listeners efficiently to avoid unnecessary rebuilds

## Best Practices

1. **Cache device info** - Load once and reuse to minimize platform calls
2. **Handle failures gracefully** - Some information may not be available on all platforms
3. **Respect privacy** - Be mindful of sensitive device identifiers
4. **Test on real devices** - Emulator/simulator info may differ from physical devices
5. **Platform-specific code** - Use platform checks when accessing platform-specific features

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or suggestions, please file an issue on the [GitHub repository](https://github.com/yourusername/flutter_dev_panel/issues).