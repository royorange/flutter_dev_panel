import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/device_info_data.dart';

class DeviceInfoController extends ChangeNotifier {
  DeviceInfoData? _deviceInfo;
  bool _isLoading = false;
  String? _error;
  
  DeviceInfoData? get deviceInfo => _deviceInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _deviceInfo != null;
  
  Future<void> loadDeviceInfo(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final baseInfo = await DeviceInfoData.collect();
      
      if (context.mounted) {
        final mediaQuery = MediaQuery.of(context);
        final orientation = mediaQuery.orientation == Orientation.portrait 
            ? 'Portrait' 
            : 'Landscape';
        
        _deviceInfo = baseInfo.copyWithScreenInfo(
          screenWidth: mediaQuery.size.width,
          screenHeight: mediaQuery.size.height,
          devicePixelRatio: mediaQuery.devicePixelRatio,
          textScaleFactor: mediaQuery.textScaler.scale(1.0),
          orientation: orientation,
        );
      } else {
        _deviceInfo = baseInfo;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> copyToClipboard(String key, String value) async {
    final text = '$key: $value';
    await Clipboard.setData(ClipboardData(text: text));
  }
  
  Future<void> copyAllToClipboard() async {
    if (_deviceInfo == null) return;
    
    final buffer = StringBuffer();
    final displayMap = _deviceInfo!.toDisplayMap();
    
    for (final entry in displayMap.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }
  
  void refresh(BuildContext context) {
    loadDeviceInfo(context);
  }
}