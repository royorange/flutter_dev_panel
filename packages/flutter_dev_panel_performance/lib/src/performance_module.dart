import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'ui/performance_monitor_page.dart';
import 'performance_monitor_controller.dart';

class PerformanceModule extends DevModule {
  const PerformanceModule()
      : super(
          id: 'performance',
          name: 'Performance',
          description: 'Monitor app performance metrics including FPS and memory usage',
          icon: Icons.speed,
          order: 30,
        );

  @override
  Widget buildPage(BuildContext context) {
    return const PerformanceMonitorPage();
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // 只有在监控开启时才返回FAB内容
    if (PerformanceMonitorController.instance.isMonitoring) {
      return const _PerformanceFabContent();
    }
    return null;
  }
  
  @override
  int get fabPriority => 10; // 高优先级
}

/// Performance模块在FAB中的显示内容
class _PerformanceFabContent extends StatefulWidget {
  const _PerformanceFabContent();

  @override
  State<_PerformanceFabContent> createState() => _PerformanceFabContentState();
}

class _PerformanceFabContentState extends State<_PerformanceFabContent> {
  final _dataProvider = MonitoringDataProvider.instance;
  
  @override
  void initState() {
    super.initState();
    _dataProvider.addListener(_onDataChanged);
  }
  
  @override
  void dispose() {
    _dataProvider.removeListener(_onDataChanged);
    super.dispose();
  }
  
  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 只有在监控开启时才显示数据
    // 通过检查是否有数据来判断监控状态
    final fps = _dataProvider.fps;
    final memory = _dataProvider.memory;
    final batteryLevel = PerformanceMonitorController.instance.currentBatteryLevel;
    
    // 如果没有数据（监控未开启），返回空widget
    if (fps == null && memory == null && batteryLevel <= 0) {
      return const SizedBox.shrink();
    }
    
    // 使用RichText分别显示颜色
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (fps != null) TextSpan(
            text: '${fps.toStringAsFixed(0)}FPS',
            style: TextStyle(color: _getFpsColor(fps)),
          ),
          if (fps != null && memory != null) const TextSpan(
            text: '  ',  // 2个空格
          ),
          if (memory != null) TextSpan(
            text: '${memory.toStringAsFixed(0)}MB',
            style: TextStyle(color: _getMemoryColor(memory)),
          ),
          if ((fps != null || memory != null) && batteryLevel > 0) const TextSpan(
            text: '  ',  // 2个空格
          ),
          if (batteryLevel > 0) TextSpan(
            text: '⚡${batteryLevel}%',
            style: TextStyle(color: _getBatteryColor(batteryLevel)),
          ),
        ],
      ),
    );
  }
  
  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.lightGreenAccent;
    if (fps >= 30) return Colors.amberAccent;
    return Colors.redAccent;
  }
  
  Color _getMemoryColor(double memory) {
    if (memory <= 300) return Colors.lightGreenAccent;
    if (memory <= 500) return Colors.amberAccent;
    return Colors.redAccent;
  }
  
  Color _getBatteryColor(int level) {
    if (level <= 20) return Colors.redAccent;
    if (level <= 50) return Colors.orangeAccent;
    return Colors.cyanAccent;
  }
}