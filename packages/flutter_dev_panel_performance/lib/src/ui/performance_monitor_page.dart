import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../performance_monitor_controller.dart';
import 'widgets/fps_chart.dart';
import 'widgets/memory_chart.dart';
import 'widgets/performance_stats_card.dart';
import 'widgets/analysis_tab.dart';

class PerformanceMonitorPage extends StatefulWidget {
  const PerformanceMonitorPage({Key? key}) : super(key: key);

  @override
  State<PerformanceMonitorPage> createState() => _PerformanceMonitorPageState();
}

class _PerformanceMonitorPageState extends State<PerformanceMonitorPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;
  bool _hideInternalTimers = true;  // 默认隐藏内部 Timer
  int _maxTimersToShow = 5;  // 默认显示最多 5 个 Timer

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 从持久化存储加载设置
    _loadSettings();
    
    // 初始化录制动画
    _recordingAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _recordingAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 如果已经在监控中，启动动画
    if (PerformanceMonitorController.instance.isMonitoring) {
      _recordingAnimationController.repeat(reverse: true);
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      // 使用 DevPanel 的持久化存储
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _hideInternalTimers = prefs.getBool('performance.hideInternalTimers') ?? true;
        _maxTimersToShow = prefs.getInt('performance.maxTimersToShow') ?? 5;
      });
    } catch (e) {
      // 忽略错误，使用默认值
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('performance.hideInternalTimers', _hideInternalTimers);
      await prefs.setInt('performance.maxTimersToShow', _maxTimersToShow);
    } catch (e) {
      // 忽略错误
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recordingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider.value(
      value: PerformanceMonitorController.instance,
      child: Consumer<PerformanceMonitorController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              title: Text(
                'Performance Monitor',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                // 监控状态指示器
                if (controller.isMonitoring)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AnimatedBuilder(
                      animation: _recordingAnimation,
                      builder: (context, child) {
                        return Row(
                          children: [
                            FadeTransition(
                              opacity: _recordingAnimation,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'REC',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    controller.isMonitoring
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outlined,
                    color: controller.isMonitoring
                        ? colorScheme.error
                        : colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    if (controller.isMonitoring) {
                      controller.stopMonitoring();
                      _recordingAnimationController.stop();
                    } else {
                      controller.startMonitoring();
                      _recordingAnimationController.repeat(reverse: true);
                    }
                  },
                  tooltip: controller.isMonitoring
                      ? 'Stop Monitoring'
                      : 'Start Monitoring',
                ),
                // 设置按钮（放在中间）
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, size: 20),
                  tooltip: 'Settings',
                  onSelected: (value) {
                    if (value == 'toggle_internal') {
                      setState(() {
                        _hideInternalTimers = !_hideInternalTimers;
                      });
                    } else if (value.startsWith('max_')) {
                      final count = int.tryParse(value.substring(4));
                      if (count != null) {
                        setState(() {
                          _maxTimersToShow = count;
                        });
                        _saveSettings();  // 保存设置
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hide Internal Timers',
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(
                            height: 24,  // 控制 Switch 高度
                            child: Transform.scale(
                              scale: 0.8,  // 稍微缩小 Switch
                              child: Switch(
                                value: _hideInternalTimers,
                                onChanged: (value) {
                                  setState(() {
                                    _hideInternalTimers = value;
                                  });
                                  _saveSettings();  // 保存设置
                                  Navigator.of(context).pop();  // 关闭菜单
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        'Max Timers to Display',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...[ 5, 10, 15, 20].map((count) => 
                      PopupMenuItem<String>(
                        value: 'max_$count',
                        child: Row(
                          children: [
                            if (_maxTimersToShow == count)
                              const Icon(Icons.check, size: 20)
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 12),
                            Text('$count timers'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Metrics'),
                  Tab(text: 'Analysis'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Metrics Tab
                controller.isMonitoring 
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          FpsChart(
                            metrics: controller.metrics,
                            currentFps: controller.currentFps,
                          ),
                          const SizedBox(height: 16),
                          MemoryChart(
                            metrics: controller.metrics,
                            currentMemory: controller.currentMemory,
                          ),
                          const SizedBox(height: 16),
                          PerformanceStatsCard(
                            controller: controller,
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.play_circle_filled,
                              size: 72,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              controller.startMonitoring();
                              _recordingAnimationController.repeat(reverse: true);
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to start monitoring',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                // Analysis Tab
                AnalysisTab(
                  leakDetector: controller.leakDetector,
                  memoryHistory: controller.metrics.dataPoints
                      .map((data) => data.memoryUsage)
                      .toList(),
                  hideInternalTimers: _hideInternalTimers,
                  maxTimersToShow: _maxTimersToShow,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}