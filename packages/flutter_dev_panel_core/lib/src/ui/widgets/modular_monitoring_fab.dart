import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/module_registry.dart';

/// 模块化的监控悬浮按钮
class ModularMonitoringFab extends StatefulWidget {
  final VoidCallback onTap;
  
  const ModularMonitoringFab({
    super.key,
    required this.onTap,
  });

  @override
  State<ModularMonitoringFab> createState() => _ModularMonitoringFabState();
}

class _ModularMonitoringFabState extends State<ModularMonitoringFab> with SingleTickerProviderStateMixin {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;
  bool _isExpanded = false;
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  Timer? _collapseTimer;
  Timer? _refreshTimer;
  List<Widget> _fabContents = [];
  bool _hasAutoExpanded = false; // 记录是否已经自动展开过
  
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
    
    // 延迟初始化，避免启动时立即展开
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _buildFabContents();
        
        // 定期刷新FAB内容
        _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (mounted) {
            _buildFabContents();
          }
        });
      }
    });
  }
  
  void _buildFabContents() {
    final modules = ModuleRegistry.instance.getEnabledModules();
    
    // 按优先级排序
    final sortedModules = List.from(modules)
      ..sort((a, b) => a.fabPriority.compareTo(b.fabPriority));
    
    final newContents = <Widget>[];
    for (final module in sortedModules) {
      final content = module.buildFabContent(context);
      // 只添加非null的内容
      if (content != null) {
        newContents.add(content);
      }
    }
    
    // 检查内容变化
    final hadContent = _fabContents.isNotEmpty;
    final hasContent = newContents.isNotEmpty;
    
    setState(() {
      _fabContents = newContents;
    });
    
    // 只在内容从无到有且之前没有自动展开过时才自动展开
    if (!hadContent && hasContent && !_isExpanded && !_isDragging && !_hasAutoExpanded) {
      _expandWithoutAutoCollapse();
      _hasAutoExpanded = true;
    }
    // 如果没有内容且已展开，收起
    else if (!hasContent && _isExpanded && !_isDragging) {
      _collapse();
      // 重置自动展开标志，下次有内容时可以再次自动展开
      _hasAutoExpanded = false;
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
    _animationController.dispose();
    _collapseTimer?.cancel();
    _refreshTimer?.cancel();
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
                      padding: EdgeInsets.symmetric(
                        horizontal: _expandAnimation.value > 0.7 ? 12 : 0,
                      ),
                      child: _expandAnimation.value > 0.7
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIcon(),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FadeTransition(
                                    opacity: _expandAnimation,
                                    child: ClipRect(
                                      child: _buildInfo(),
                                    ),
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
    return const Icon(
      Icons.bug_report,
      color: Colors.white,
      size: 24,
    );
  }
  
  Widget _buildInfo() {
    // 即使有内容也先返回空，避免显示空白
    if (_fabContents.isEmpty) {
      return const Text(
        'Dev Panel',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    
    // 显示所有模块的FAB内容
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _fabContents.length; i++) ...[
          _fabContents[i],
          if (i < _fabContents.length - 1) const SizedBox(height: 2),
        ],
      ],
    );
  }
}