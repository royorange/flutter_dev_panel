library flutter_dev_panel;

// Core exports
export 'src/dev_panel.dart';
export 'src/core/dev_panel_controller.dart';
export 'src/core/environment_manager.dart';
export 'src/core/module_manager.dart';

// Model exports
export 'src/models/dev_panel_config.dart';
export 'src/models/environment.dart';
export 'src/models/module.dart';
export 'src/models/theme_config.dart';
export 'src/models/network_request.dart';

// Module exports
export 'src/modules/network/network_module.dart';
export 'src/modules/network/network_interceptor.dart';
export 'src/modules/network/network_monitor_controller.dart';
export 'src/modules/environment/environment_module.dart';
export 'src/modules/device_info/device_info_module.dart';
export 'src/modules/performance/performance_module.dart';
export 'src/modules/performance/fps_monitor.dart';

// Widget exports
export 'src/ui/widgets/floating_button.dart';
export 'src/ui/widgets/shake_detector.dart';

// Main initialization class
export 'src/flutter_dev_panel.dart';