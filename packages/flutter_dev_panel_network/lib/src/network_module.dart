import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:graphql_flutter/graphql_flutter.dart' as gql;
import 'network_monitor_controller.dart';
import 'network_interceptor.dart';
import 'interceptors/http_client_interceptor.dart';
import 'interceptors/base_interceptor.dart';
import 'interceptors/graphql_interceptor.dart';
import 'ui/network_monitor_page.dart';
import 'network_api.dart';

class NetworkModule extends DevModule {
  static NetworkModule? _instance;
  static NetworkMonitorController? _controller;

  NetworkModule._() : super(
    id: 'network',
    name: 'Network',
    description: 'Monitor and debug network requests',
    icon: Icons.wifi,
    order: 10,
  );

  factory NetworkModule() {
    _instance ??= NetworkModule._();
    return _instance!;
  }

  static NetworkMonitorController get controller {
    _controller ??= NetworkMonitorController();
    return _controller!;
  }
  
  /// 获取模块的 API
  NetworkAPI get api => NetworkAPI.instance;

  // ============ Dio 集成 ============
  static Interceptor createInterceptor() {
    return NetworkInterceptor(controller);
  }

  static void attachToDio(Dio dio) {
    // 只在调试模式下添加拦截器
    if (kDebugMode) {
      dio.interceptors.add(createInterceptor());
    }
  }

  static void attachToMultipleDio(List<Dio> dioInstances) {
    // 只在调试模式下添加拦截器
    if (kDebugMode) {
      final interceptor = createInterceptor();
      for (final dio in dioInstances) {
        dio.interceptors.add(interceptor);
      }
    }
  }
  
  // ============ http 包集成 ============
  static http.Client createHttpClient({http.Client? innerClient}) {
    // 生产模式下返回原始客户端
    if (!kDebugMode) {
      return innerClient ?? http.Client();
    }
    return MonitoredHttpClient(
      client: innerClient,
      controller: controller,
    );
  }
  
  static http.Client wrapHttpClient(http.Client client) {
    // 生产模式下返回原始客户端
    if (!kDebugMode) {
      return client;
    }
    return createHttpClient(innerClient: client);
  }
  
  // ============ GraphQL 集成 ============
  /// 创建带监控的 GraphQL Link（推荐方式）
  /// 
  /// 使用方法 1 - 单个 Link：
  /// ```dart
  /// final link = NetworkModule.createGraphQLLink(
  ///   HttpLink('https://api.example.com/graphql'),
  /// );
  /// ```
  /// 
  /// 使用方法 2 - 多个 Link 组合：
  /// ```dart
  /// final httpLink = HttpLink('https://api.example.com/graphql');
  /// final authLink = AuthLink(getToken: () async => 'Bearer $token');
  /// 
  /// // 先组合你的 Links
  /// final combinedLink = Link.from([authLink, httpLink]);
  /// 
  /// // 然后添加监控
  /// final link = NetworkModule.createGraphQLLink(combinedLink);
  /// ```
  /// 
  /// 使用方法 3 - 只监控 HttpLink：
  /// ```dart
  /// final httpLink = HttpLink('https://api.example.com/graphql');
  /// final monitoredHttpLink = NetworkModule.createGraphQLLink(httpLink);
  /// final authLink = AuthLink(getToken: () async => 'Bearer $token');
  /// 
  /// // 监控在 auth 之后
  /// final link = Link.from([authLink, monitoredHttpLink]);
  /// ```
  static gql.Link createGraphQLLink(gql.Link link, {String? endpoint}) {
    // 生产模式下返回原始 link
    if (!kDebugMode) {
      return link;
    }
    
    final interceptor = GraphQLInterceptor(
      controller: controller,
      endpoint: endpoint,
    );
    return gql.Link.from([interceptor, link]);
  }
  
  /// 包装现有的 GraphQL 客户端（返回新客户端）
  /// 
  /// 注意：由于 GraphQL 客户端的设计，无法直接修改原客户端，
  /// 必须返回新客户端。请使用返回的客户端替换原客户端。
  /// 
  /// 使用方法：
  /// ```dart
  /// GraphQLClient client = GraphQLClient(...);
  /// client = NetworkModule.wrapGraphQLClient(client); // 重新赋值
  /// ```
  /// 
  /// 或者使用 createGraphQLLink 在创建客户端时就加入监控（推荐）
  static gql.GraphQLClient wrapGraphQLClient(gql.GraphQLClient client, {String? endpoint}) {
    // 生产模式下返回原始客户端
    if (!kDebugMode) {
      return client;
    }
    
    final wrappedLink = createGraphQLLink(client.link, endpoint: endpoint);
    
    // 返回新的客户端，保留原有配置
    return gql.GraphQLClient(
      link: wrappedLink,
      cache: client.cache,
      defaultPolicies: client.defaultPolicies,
    );
  }
  
  
  /// 创建带监控的GraphQL客户端
  static gql.GraphQLClient createGraphQLClient({
    required String endpoint,
    String? subscriptionEndpoint,
    Map<String, String>? defaultHeaders,
    gql.GraphQLCache? cache,
  }) {
    return MonitoredGraphQLClient.create(
      endpoint: endpoint,
      subscriptionEndpoint: subscriptionEndpoint,
      defaultHeaders: defaultHeaders,
      cache: cache,
    );
  }
  
  /// 包装现有的GraphQL Link
  static gql.Link wrapGraphQLLink(gql.Link link) {
    // 生产模式下返回原始link
    if (!kDebugMode) {
      return link;
    }
    // 暂时直接返回原链接，需要实现包装逻辑
    return link;
  }
  
  /// 获取GraphQL拦截器Link（用于自定义集成）
  static gql.Link createGraphQLInterceptor({String? endpoint}) {
    return GraphQLInterceptor(controller: controller, endpoint: endpoint);
  }
  
  // ============ 通用集成 ============
  /// 获取基础拦截器，用于自定义集成
  static BaseNetworkInterceptor getBaseInterceptor() {
    return _NetworkInterceptorImpl(controller);
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
    // 只有当前会话有活动时才显示FAB内容
    // 历史记录不应该触发FAB显示
    if (controller.hasSessionActivity) {
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
  
  // 最近一批请求的统计（惰性计算）
  int _recentRequestCount = 0;
  double _recentTotalSize = 0; // KB
  int _recentAvgDuration = 0; // ms
  DateTime? _lastBatchEndTime; // 最后一批请求的结束时间
  bool _hasBatchData = false; // 是否有批次数据
  
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
  
  void _updateMetrics({bool skipSetState = false}) {
    // 策略：显示最近一批请求的统计，持续显示直到有新批次
    final now = DateTime.now();
    
    // 定义批次窗口：3秒内的请求算作一批
    final batchWindow = const Duration(seconds: 3);
    final recentThreshold = now.subtract(batchWindow);
    
    // 计算当前时间窗口内的请求
    int currentBatchCount = 0;
    double currentBatchSize = 0;
    int currentTotalDuration = 0;
    int currentDurationCount = 0;
    DateTime? latestEndTime;
    
    for (final req in widget.controller.allRequests) {
      if (req.endTime != null && req.endTime!.isAfter(recentThreshold)) {
        currentBatchCount++;
        if (req.responseSize != null) {
          currentBatchSize += req.responseSize! / 1024; // 转换为KB
        }
        if (req.duration != null) {
          currentTotalDuration += req.duration!.inMilliseconds;
          currentDurationCount++;
        }
        // 记录最新的结束时间
        if (latestEndTime == null || req.endTime!.isAfter(latestEndTime)) {
          latestEndTime = req.endTime;
        }
      }
    }
    
    // 如果有新的批次数据，更新统计
    if (currentBatchCount > 0) {
      _recentRequestCount = currentBatchCount;
      _recentTotalSize = currentBatchSize;
      if (currentDurationCount > 0) {
        _recentAvgDuration = currentTotalDuration ~/ currentDurationCount;
      }
      _lastBatchEndTime = latestEndTime;
      _hasBatchData = true;
    }
    // 否则保持之前的统计数据（如果有）
    // 这样即使超过3秒，统计信息也会保持显示
    
    // 触发UI更新（除非在 build 中调用）
    if (!skipSetState && mounted) {
      setState(() {});
    }
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
        // 每次 build 时都重新计算最近的请求统计（跳过 setState）
        _updateMetrics(skipSetState: true);
        
        // 使用会话统计而不是总统计
        final pendingCount = widget.controller.sessionPendingCount;
        final errorCount = widget.controller.sessionErrorCount;
        final successCount = widget.controller.sessionSuccessCount;
        final totalCount = widget.controller.sessionRequestCount;
        
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
                        child: const Icon(
                          Icons.sync,
                          size: 11,
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                else
                  Icon(
                    errorCount > 0 ? Icons.warning : Icons.check_circle,
                    size: 11,
                    color: errorCount > 0 ? Colors.orangeAccent : Colors.lightGreenAccent,
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
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        // Pending请求 - 优先显示
                        if (pendingCount > 0) ...[
                          TextSpan(
                            text: pendingCount > 99 ? '↻99+' : '↻$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: ' '),
                        ],
                        
                        // 如果有批次数据，优先显示统计信息（常驻）
                        if (_hasBatchData) ...[  
                          // 显示最近一批请求的统计: Nreq/xxxK avgMs
                          TextSpan(
                            text: '${_recentRequestCount}req',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_recentTotalSize > 1) ...[ // 大于1KB才显示流量
                            TextSpan(
                              text: '/${_formatSize(_recentTotalSize)}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 9,
                              ),
                            ),
                          ],
                          if (_recentAvgDuration > 0) ...[ // 显示平均耗时
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: _recentAvgDuration < 1000 
                                  ? '${_recentAvgDuration}ms'
                                  : '${(_recentAvgDuration / 1000).toStringAsFixed(1)}s',
                              style: TextStyle(
                                color: _recentAvgDuration > 1000 
                                    ? Colors.amberAccent 
                                    : Colors.white54,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ] else ...[
                          // 没有最近请求时，显示会话总统计
                          TextSpan(
                            text: _formatCount(successCount),
                            style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 9,
                            ),
                          ),
                          if (errorCount > 0) ...[
                            const TextSpan(text: '/'),
                            TextSpan(
                              text: _formatCount(errorCount),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

/// BaseNetworkInterceptor的简单实现
class _NetworkInterceptorImpl extends BaseNetworkInterceptor {
  _NetworkInterceptorImpl(NetworkMonitorController controller) : super(controller);
}