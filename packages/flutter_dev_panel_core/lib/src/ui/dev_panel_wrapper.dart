import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../models/dev_panel_config.dart';
import 'widgets/modular_monitoring_fab.dart';
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
  bool _isPanelOpen = false;

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
    if (!controller.shouldShowInProduction() || _isPanelOpen) {
      return;
    }

    setState(() {
      _isPanelOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: const DevPanel(),
            ),
          ),
        );
      },
    ).whenComplete(() {
      setState(() {
        _isPanelOpen = false;
      });
    });
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
              ModularMonitoringFab(
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