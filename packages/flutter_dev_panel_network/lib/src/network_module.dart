import 'package:flutter/material.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';
import 'package:dio/dio.dart';
import 'network_monitor_controller.dart';
import 'network_interceptor.dart';
import 'ui/network_monitor_page.dart';

class NetworkModule extends DevModule {
  static NetworkModule? _instance;
  static NetworkMonitorController? _controller;

  NetworkModule._() : super(
    id: 'network',
    name: 'Network',
    description: 'Monitor and debug network requests',
    icon: Icons.wifi,
    order: 1,
  );

  factory NetworkModule() {
    _instance ??= NetworkModule._();
    return _instance!;
  }

  static NetworkMonitorController get controller {
    _controller ??= NetworkMonitorController();
    return _controller!;
  }

  static Interceptor createInterceptor() {
    return NetworkInterceptor(controller);
  }

  static void attachToDio(Dio dio) {
    dio.interceptors.add(createInterceptor());
  }

  static void attachToMultipleDio(List<Dio> dioInstances) {
    final interceptor = createInterceptor();
    for (final dio in dioInstances) {
      dio.interceptors.add(interceptor);
    }
  }

  @override
  Widget buildPage(BuildContext context) {
    return NetworkMonitorPage(controller: controller);
  }

  @override
  Widget? buildQuickAction(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.totalRequests == 0) {
          return const SizedBox.shrink();
        }

        final errorCount = controller.errorCount;
        final hasErrors = errorCount > 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: hasErrors 
                ? Colors.red.shade100 
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasErrors ? Icons.error : Icons.wifi,
                size: 16,
                color: hasErrors 
                    ? Colors.red.shade700 
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Text(
                hasErrors 
                    ? '$errorCount errors' 
                    : '${controller.totalRequests} requests',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: hasErrors 
                      ? Colors.red.shade700 
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget? buildFabContent(BuildContext context) {
    // 只有有请求或正在进行的请求时才显示FAB内容
    if (controller.totalRequests > 0 || controller.pendingCount > 0) {
      return _NetworkFabContent(controller: controller);
    }
    return null;
  }
  
  @override
  int get fabPriority => 20; // 中等优先级

  @override
  Future<void> initialize() async {
    _controller ??= NetworkMonitorController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _instance = null;
  }
}

/// Network模块在FAB中的显示内容
class _NetworkFabContent extends StatefulWidget {
  final NetworkMonitorController controller;
  
  const _NetworkFabContent({required this.controller});

  @override
  State<_NetworkFabContent> createState() => _NetworkFabContentState();
}

class _NetworkFabContentState extends State<_NetworkFabContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Duration? _lastRequestDuration;
  double _totalSize = 0; // 总流量 KB
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    widget.controller.addListener(_updateMetrics);
  }
  
  @override
  void dispose() {
    widget.controller.removeListener(_updateMetrics);
    _animationController.dispose();
    super.dispose();
  }
  
  void _updateMetrics() {
    // 获取最新请求的耗时
    if (widget.controller.allRequests.isNotEmpty) {
      final latestRequest = widget.controller.allRequests.first;
      if (latestRequest.duration != null) {
        _lastRequestDuration = latestRequest.duration;
      }
      
      // 计算总流量
      _totalSize = 0;
      for (final req in widget.controller.allRequests) {
        if (req.responseSize != null) {
          _totalSize += req.responseSize! / 1024; // 转换为KB
        }
      }
    }
  }
  
  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    final ms = duration.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
  
  String _formatSize(double sizeKB) {
    if (sizeKB < 1024) return '${sizeKB.toStringAsFixed(0)}K';
    if (sizeKB < 10240) return '${(sizeKB / 1024).toStringAsFixed(1)}M';
    return '${(sizeKB / 1024).toStringAsFixed(0)}M';  // 大于10M时不显示小数
  }
  
  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 10000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '${(count / 1000).toStringAsFixed(0)}k';  // 大于10k时不显示小数
  }
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final pendingCount = widget.controller.pendingCount;
        final errorCount = widget.controller.errorCount;
        final successCount = widget.controller.successCount;
        final totalCount = widget.controller.totalRequests;
        
        // 如果没有任何请求，不显示
        if (totalCount == 0 && pendingCount == 0) {
          return const SizedBox.shrink();
        }
        
        // 如果有pending请求，启动动画
        if (pendingCount > 0) {
          if (!_animationController.isAnimating) {
            _animationController.repeat();
          }
        } else {
          _animationController.stop();
        }
        
        // 计算最慢的请求
        Duration? slowestRequest;
        for (final req in widget.controller.allRequests) {
          if (req.duration != null) {
            if (slowestRequest == null || req.duration!.inMilliseconds > slowestRequest.inMilliseconds) {
              slowestRequest = req.duration;
            }
          }
        }
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：请求统计
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 网络图标 - pending时旋转
                if (pendingCount > 0)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animationController.value * 2 * 3.14159,
                        child: Icon(
                          Icons.sync,
                          size: 11,
                          color: Colors.blue[300],
                        ),
                      );
                    },
                  )
                else
                  Icon(
                    errorCount > 0 ? Icons.warning : Icons.check_circle,
                    size: 11,
                    color: errorCount > 0 ? Colors.orange[300] : Colors.green[300],
                  ),
                const SizedBox(width: 3),
                
                // 请求统计信息 - 使用Flexible防止溢出
                Flexible(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      children: [
                        // Pending请求 - 优先显示
                        if (pendingCount > 0) ...[
                          TextSpan(
                            text: pendingCount > 99 ? '↻99+' : '↻$pendingCount',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' '),
                        ],
                        
                        // 成功/错误统计 - 简化大数字
                        TextSpan(
                          text: _formatCount(successCount),
                          style: TextStyle(
                            color: Colors.green[300],
                            fontSize: 9,
                          ),
                        ),
                        if (errorCount > 0) ...[
                          const TextSpan(text: '/'),
                          TextSpan(
                            text: _formatCount(errorCount),
                            style: TextStyle(
                              color: Colors.red[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        
                        // 最慢请求时间 - 只在特别慢时显示
                        if (slowestRequest != null && slowestRequest.inMilliseconds > 1000) ...[
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '⚡${_formatDuration(slowestRequest)}',
                            style: TextStyle(
                              color: slowestRequest.inMilliseconds > 3000 
                                  ? Colors.red[300] 
                                  : Colors.yellow[300],
                              fontSize: 9,
                            ),
                          ),
                        ],
                        
                        // 流量统计 - 只在较大时显示
                        if (_totalSize > 100) ...[  // 大于100KB才显示
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: '↓${_formatSize(_totalSize)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}