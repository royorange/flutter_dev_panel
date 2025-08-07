import 'package:flutter/material.dart';

/// 可拖动的悬浮按钮
class FloatingButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget? child;
  final Color? backgroundColor;
  final double size;

  const FloatingButton({
    super.key,
    required this.onTap,
    this.child,
    this.backgroundColor,
    this.size = 56,
  });

  @override
  State<FloatingButton> createState() => _FloatingButtonState();
}

class _FloatingButtonState extends State<FloatingButton> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
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
            newX = newX.clamp(0, screenSize.width - widget.size);
            newY = newY.clamp(0, screenSize.height - widget.size);

            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            // 吸附到屏幕边缘
            final centerX = _position.dx + widget.size / 2;
            final isLeftSide = centerX < screenSize.width / 2;
            _position = Offset(
              isLeftSide ? 20 : screenSize.width - widget.size - 20,
              _position.dy,
            );
          });
        },
        child: AnimatedContainer(
          duration: _isDragging 
              ? Duration.zero 
              : const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? 
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child ?? 
              Icon(
                Icons.bug_report,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
        ),
      ),
    );
  }
}