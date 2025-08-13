import 'package:flutter/material.dart';
import '../core/dev_panel_controller.dart';
import '../models/dev_panel_config.dart';
import '../models/panel_settings.dart';
import 'widgets/modular_monitoring_fab.dart';
import 'widgets/shake_detector.dart';
import 'dev_panel.dart';

/// Dev Panel wrapper that provides trigger entry
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

  void _openPanel([BuildContext? fabContext]) {
    if (!controller.shouldShowInProduction() || _isPanelOpen) {
      return;
    }

    setState(() {
      _isPanelOpen = true;
    });

    // Use the provided context (from FAB) or fallback to widget context
    final navContext = fabContext ?? context;
    
    // Check if we have a valid Navigator in the context
    final navigator = Navigator.maybeOf(navContext);
    if (navigator == null) {
      debugPrint('DevPanel: No Navigator found in context');
      setState(() {
        _isPanelOpen = false;
      });
      return;
    }

    showModalBottomSheet(
      context: navContext,
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
      if (mounted) {
        setState(() {
          _isPanelOpen = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, PanelSettings.instance]),
      builder: (context, child) {
        final config = controller.config;
        final settings = PanelSettings.instance;
        
        if (!config.enabled || !controller.shouldShowInProduction()) {
          return widget.child;
        }

        Widget result = widget.child;

        // Add shake detector (if enabled in both config and settings)
        if (config.triggerModes.contains(TriggerMode.shake) && settings.enableShake) {
          result = ShakeDetector(
            onShake: _openPanel,
            child: result,
          );
        }

        // Add floating button (if enabled in both config and settings)
        if (config.triggerModes.contains(TriggerMode.fab) && settings.showFab) {
          result = Stack(
            children: [
              result,
              Builder(
                builder: (fabContext) {
                  return ModularMonitoringFab(
                    onTap: () => _openPanel(fabContext),
                  );
                },
              ),
            ],
          );
        }

        return result;
      },
    );
  }
}