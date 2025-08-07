import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/dev_panel_controller.dart';

class DevPanelFloatingButton extends StatefulWidget {
  final Widget? child;
  
  const DevPanelFloatingButton({
    super.key,
    this.child,
  });

  @override
  State<DevPanelFloatingButton> createState() => _DevPanelFloatingButtonState();
}

class _DevPanelFloatingButtonState extends State<DevPanelFloatingButton> {
  Offset _position = const Offset(20, 100);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                final size = MediaQuery.of(context).size;
                double newX = _position.dx + details.delta.dx;
                double newY = _position.dy + details.delta.dy;
                
                // Keep button within screen bounds
                newX = newX.clamp(0, size.width - 56);
                newY = newY.clamp(0, size.height - 56);
                
                _position = Offset(newX, newY);
              });
            },
            onPanEnd: (_) {
              setState(() {
                _isDragging = false;
              });
            },
            onTap: _isDragging ? null : () {
              DevPanelController.to.toggle();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: _isDragging ? 12 : 8,
                    spreadRadius: _isDragging ? 2 : 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.white,
                    size: _isDragging ? 28 : 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}