import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'fps_monitor.dart';
import 'dart:math' as math;

class PerformanceMonitorPage extends StatefulWidget {
  const PerformanceMonitorPage({super.key});

  @override
  State<PerformanceMonitorPage> createState() => _PerformanceMonitorPageState();
}

class _PerformanceMonitorPageState extends State<PerformanceMonitorPage> {
  late FPSMonitor _fpsMonitor;
  
  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FPSMonitor>()) {
      Get.put(FPSMonitor());
    }
    _fpsMonitor = FPSMonitor.to;
    _fpsMonitor.startMonitoring();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('性能监控'),
        actions: [
          Obx(() => IconButton(
            icon: Icon(_fpsMonitor.isMonitoring ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              if (_fpsMonitor.isMonitoring) {
                _fpsMonitor.stopMonitoring();
              } else {
                _fpsMonitor.startMonitoring();
              }
            },
          )),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fpsMonitor.reset();
              if (!_fpsMonitor.isMonitoring) {
                _fpsMonitor.startMonitoring();
              }
            },
          ),
        ],
      ),
      body: Obx(() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFPSCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildFPSChart(),
          const SizedBox(height: 16),
          _buildMemoryInfo(),
        ],
      )),
    );
  }
  
  Widget _buildFPSCard() {
    final fps = _fpsMonitor.fps;
    final status = _fpsMonitor.getFPSStatus();
    final color = _fpsMonitor.getFPSColor();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '当前 FPS',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fps.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    'fps',
                    style: TextStyle(
                      fontSize: 20,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: fps / 60.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统计数据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('最小 FPS', _fpsMonitor.minFps.toStringAsFixed(1), Colors.red),
            _buildStatRow('平均 FPS', _fpsMonitor.avgFps.toStringAsFixed(1), Colors.orange),
            _buildStatRow('最大 FPS', _fpsMonitor.maxFps.toStringAsFixed(1), Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFPSChart() {
    final history = _fpsMonitor.frameHistory;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FPS 历史',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: history.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无数据',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : CustomPaint(
                      size: const Size(double.infinity, 150),
                      painter: FPSChartPainter(history),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMemoryInfo() {
    // This is a placeholder for memory info
    // In a real implementation, you might want to use a plugin
    // or platform channels to get actual memory usage
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '内存信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '提示：内存监控需要平台特定实现',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Trigger garbage collection (for demonstration)
                // In production, this would need proper implementation
                Get.snackbar(
                  '提示',
                  '内存监控功能需要额外配置',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('查看内存详情'),
            ),
          ],
        ),
      ),
    );
  }
}

class FPSChartPainter extends CustomPainter {
  final List<double> data;
  
  FPSChartPainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw grid lines
    for (int i = 0; i <= 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Draw FPS line
    final path = Path();
    final maxFps = 60.0;
    final xStep = size.width / (data.length - 1);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - (data[i] / maxFps * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw 60 FPS line
    final targetPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, 0),
      targetPaint,
    );
    
    // Draw 30 FPS line
    final warningPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final y30 = size.height * (1 - 30 / maxFps);
    canvas.drawLine(
      Offset(0, y30),
      Offset(size.width, y30),
      warningPaint,
    );
  }
  
  @override
  bool shouldRepaint(FPSChartPainter oldDelegate) {
    return data != oldDelegate.data;
  }
}