import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../models/dev_panel_config.dart';
import 'widgets/floating_button.dart';
import 'widgets/shake_detector.dart';
import 'dev_panel.dart';

/// 开发面板包装器，提供触发入口
class DevPanelWrapper extends StatefulWidget {
  final Widget child;
  final DevPanelConfig? config;

  const DevPanelWrapper({
    super.key,
    required this.child,
    this.config,
  });

  @override
  State<DevPanelWrapper> createState() => _DevPanelWrapperState();
}

class _DevPanelWrapperState extends State<DevPanelWrapper> {
  final controller = DevPanelController.instance;

  @override
  void initState() {
    super.initState();
    controller.initialize(config: widget.config);
  }

  @override
  void didUpdateWidget(DevPanelWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config && widget.config != null) {
      controller.updateConfig(widget.config!);
    }
  }

  void _openPanel() {
    if (!controller.shouldShowInProduction()) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const DevPanel(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final config = controller.config;
        
        if (!config.enabled || !controller.shouldShowInProduction()) {
          return widget.child;
        }

        Widget result = widget.child;

        // 添加摇一摇检测
        if (config.triggerModes.contains(TriggerMode.shake)) {
          result = ShakeDetector(
            onShake: _openPanel,
            child: result,
          );
        }

        // 添加悬浮按钮
        if (config.triggerModes.contains(TriggerMode.fab)) {
          result = Stack(
            children: [
              result,
              FloatingButton(
                onTap: _openPanel,
              ),
            ],
          );
        }

        return result;
      },
    );
  }
}