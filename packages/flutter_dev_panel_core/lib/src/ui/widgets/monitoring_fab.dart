import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/monitoring_data_provider.dart';

/// 带监控信息的悬浮按钮
class MonitoringFab extends StatefulWidget {
  final VoidCallback onTap;
  
  const MonitoringFab({
    super.key,
    required this.onTap,
  });

  @override
  State<MonitoringFab> createState() => _MonitoringFabState();
}

class _MonitoringFabState extends State<MonitoringFab> with SingleTickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  bool _isExpanded = false;
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  Timer? _collapseTimer;
  final _dataProvider = MonitoringDataProvider.instance;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 监听监控数据
    _dataProvider.addListener(_onDataChanged);
  }
  
  void _onDataChanged() {
    if (mounted) {
      setState(() {});
      
      // 有性能数据时自动展开并保持展开
      if (_dataProvider.fps != null || _dataProvider.memory != null) {
        if (!_isExpanded && !_isDragging) {
          _expandWithoutAutoCollapse();
        }
      } else if (_dataProvider.totalRequests == 0 && _dataProvider.errorRequests == 0) {
        // 没有任何数据时收起
        if (_isExpanded && !_isDragging) {
          _collapse();
        }
      }
    }
  }
  
  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    
    // 3秒后自动收起
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        _collapse();
      }
    });
  }
  
  void _expandWithoutAutoCollapse() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
    _collapseTimer?.cancel(); // 不设置自动收起
  }
  
  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
    _collapseTimer?.cancel();
  }
  
  @override
  void dispose() {
    _dataProvider.removeListener(_onDataChanged);
    _animationController.dispose();
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 固定的尺寸值
    const collapsedWidth = 56.0;
    const expandedWidth = 180.0;
    const fabHeight = 56.0;
    
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          // 打开面板后收起FAB（如果已展开）
          if (_isExpanded) {
            _collapse();
          }
        },
        onLongPress: () {
          if (_isExpanded) {
            _collapse();
          } else {
            _expand();
          }
        },
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
          _collapseTimer?.cancel();
        },
        onPanUpdate: (details) {
          setState(() {
            double newX = _position.dx + details.delta.dx;
            double newY = _position.dy + details.delta.dy;
            
            // 限制在屏幕范围内
            final currentWidth = _isExpanded ? expandedWidth : collapsedWidth;
            newX = newX.clamp(0, screenSize.width - currentWidth);
            newY = newY.clamp(0, screenSize.height - fabHeight);
            
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            // 吸附到屏幕边缘
            final centerX = _position.dx + collapsedWidth / 2;
            final isLeftSide = centerX < screenSize.width / 2;
            final currentWidth = _isExpanded ? expandedWidth : collapsedWidth;
            _position = Offset(
              isLeftSide ? 16 : screenSize.width - currentWidth - 16,
              _position.dy,
            );
          });
        },
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final currentWidth = collapsedWidth + (_expandAnimation.value * (expandedWidth - collapsedWidth));
            return Container(
              width: currentWidth,
              height: fabHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: null, // 由外层GestureDetector统一处理
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      alignment: _expandAnimation.value > 0.1 
                          ? Alignment.centerLeft 
                          : Alignment.center,
                      padding: _expandAnimation.value > 0.1
                          ? const EdgeInsets.symmetric(horizontal: 12)
                          : EdgeInsets.zero,
                      child: _expandAnimation.value > 0.1
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIcon(),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FadeTransition(
                                    opacity: _expandAnimation,
                                    child: _buildInfo(),
                                  ),
                                ),
                              ],
                            )
                          : Center(child: _buildIcon()),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildIcon() {
    final hasIssues = (_dataProvider.fps ?? 60) < 30 || _dataProvider.errorRequests > 0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.bug_report,
          color: Colors.white,
          size: 24,
        ),
        if (hasIssues)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildInfo() {
    final fps = _dataProvider.fps;
    final memory = _dataProvider.memory;
    final totalRequests = _dataProvider.totalRequests;
    final errorRequests = _dataProvider.errorRequests;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // FPS和内存放在一行
        if (fps != null || memory != null) 
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fps != null) ...[
                Text(
                  '${fps.toStringAsFixed(0)}FPS',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getFpsColor(fps),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (memory != null) const SizedBox(width: 6),
              ],
              if (memory != null)
                Text(
                  '${memory.toStringAsFixed(0)}MB',
                  style: TextStyle(
                    fontSize: 11,
                    color: _getMemoryColor(memory),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          )
        else
          const Text(
            'Monitoring...',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        // 网络请求信息
        if (totalRequests > 0 || errorRequests > 0) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.swap_vert,
                size: 12,
                color: errorRequests > 0 ? Colors.orange[300] : Colors.white70,
              ),
              const SizedBox(width: 2),
              Text(
                errorRequests > 0 
                    ? '$totalRequests/$errorRequests'
                    : '$totalRequests',
                style: TextStyle(
                  fontSize: 10,
                  color: errorRequests > 0 ? Colors.orange[300] : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  
  Color _getFpsColor(double? fps) {
    if (fps == null) return Colors.white70;
    if (fps >= 55) return Colors.green[300]!;
    if (fps >= 30) return Colors.yellow[300]!;
    return Colors.red[300]!;
  }
  
  Color _getMemoryColor(double? memory) {
    if (memory == null) return Colors.white70;
    if (memory <= 300) return Colors.green[300]!;
    if (memory <= 500) return Colors.yellow[300]!;
    return Colors.red[300]!;
  }
}