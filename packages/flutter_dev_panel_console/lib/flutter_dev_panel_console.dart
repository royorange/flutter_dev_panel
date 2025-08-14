library flutter_dev_panel_console;

export 'src/console_module.dart';
export 'src/models/log_entry.dart';
export 'src/providers/console_provider.dart';

// Logger package integration (no dependency required)
export 'src/integrations/logger_integration.dart' 
    show DevPanelLogger;