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
    // 使用统一的启用检查
    if (!DevPanelController.isEnabled || _isPanelOpen) {
      return;
    }

    setState(() {
      _isPanelOpen = true;
    });

    // For GetX and builder pattern, we need to find the Navigator carefully
    BuildContext? navigatorContext;
    
    // Strategy 1: Try the provided context
    if (fabContext != null && Navigator.maybeOf(fabContext) != null) {
      navigatorContext = fabContext;
    }
    // Strategy 2: Try the widget's context
    else if (Navigator.maybeOf(context) != null) {
      navigatorContext = context;
    }
    // Strategy 3: Use the root navigator for GetX apps
    else {
      try {
        // For GetX, we can use Get.context which provides the navigator context
        // This works because GetMaterialApp sets up a global navigator key
        final rootContext = WidgetsBinding.instance.rootElement;
        if (rootContext != null) {
          // Find the first context with a Navigator
          void findNavigator(Element element) {
            if (navigatorContext == null) {
              if (Navigator.maybeOf(element) != null) {
                navigatorContext = element;
              } else {
                element.visitChildren(findNavigator);
              }
            }
          }
          rootContext.visitChildren(findNavigator);
        }
      } catch (e) {
        debugPrint('DevPanel: Error finding navigator - $e');
      }
    }
    
    if (navigatorContext == null) {
      debugPrint('DevPanel: No Navigator found. Make sure DevPanelWrapper is used correctly');
      setState(() {
        _isPanelOpen = false;
      });
      return;
    }

    showModalBottomSheet(
      context: navigatorContext!,  // We've already checked it's not null
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
    // 使用编译时常量，支持 tree shaking
    if (!DevPanelController.isEnabled) {
      return widget.child;
    }
    
    return ListenableBuilder(
      listenable: Listenable.merge([controller, PanelSettings.instance]),
      builder: (context, child) {
        final config = controller.config;
        final settings = PanelSettings.instance;

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
              // ModularMonitoringFab already has its own Positioned widget
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