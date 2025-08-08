import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/module_registry.dart';
import '../../core/monitoring_data_provider.dart';

/// 模块化的监控悬浮按钮，从各模块获取FAB内容显示
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
  bool _isManuallyCollapsed = false; // 用户手动收起的标志
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  Timer? _refreshTimer;
  List<Widget> _fabContents = [];
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
    
    // 监听数据变化，触发内容更新
    _dataProvider.addListener(_updateFabContents);
    
    // 延迟初始检查
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _updateFabContents();
        
        // 定期检查更新（作为备用机制）
        _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) {
            _updateFabContents();
          }
        });
      }
    });
  }
  
  void _updateFabContents() {
    final modules = ModuleRegistry.instance.getEnabledModules();
    
    // 按优先级排序
    final sortedModules = List.from(modules)
      ..sort((a, b) => a.fabPriority.compareTo(b.fabPriority));
    
    final newContents = <Widget>[];
    
    // 获取每个模块的FAB内容
    for (final module in sortedModules) {
      final content = module.buildFabContent(context);
      if (content != null) {
        newContents.add(content);
      }
    }
    
    final hadContent = _fabContents.isNotEmpty;
    final hasContent = newContents.isNotEmpty;
    
    setState(() {
      _fabContents = newContents;
    });
    
    // 自动展开/收起逻辑
    if (!_isDragging && !_isManuallyCollapsed) {
      if (hasContent && !_isExpanded) {
        // 有内容时自动展开
        _expand();
      } else if (!hasContent && _isExpanded) {
        // 无内容时自动收起
        _collapse();
      }
    }
    
    // 如果从无内容变为有内容，清除手动收起标志
    if (!hadContent && hasContent) {
      _isManuallyCollapsed = false;
    }
  }
  
  void _expand() {
    setState(() {
      _isExpanded = true;
    });
    _animationController.forward();
  }
  
  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _animationController.reverse();
  }
  
  void _toggleManually() {
    if (_fabContents.isEmpty) return;
    
    if (_isExpanded) {
      _collapse();
      _isManuallyCollapsed = true;
    } else {
      _expand();
      _isManuallyCollapsed = false;
    }
  }
  
  @override
  void dispose() {
    _dataProvider.removeListener(_updateFabContents);
    _animationController.dispose();
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
        onTap: widget.onTap,
        onLongPress: _toggleManually,
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
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
          // 拖动结束后更新一次内容
          _updateFabContents();
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
    // 根据是否有内容显示不同的图标状态
    final hasContent = _fabContents.isNotEmpty;
    return Icon(
      Icons.bug_report,
      color: Colors.white.withValues(alpha: hasContent ? 1.0 : 0.7),
      size: 24,
    );
  }
  
  Widget _buildInfo() {
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