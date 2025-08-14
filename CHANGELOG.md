# Changelog

## 0.0.3 (Unreleased)

### Breaking Changes
* **Simplified configuration**: Removed `enabled` field from `DevPanelConfig`
  - Panel is now controlled by compile-time constants for optimal tree shaking
  - Debug mode: Always enabled automatically
  - Release mode: Disabled by default, can be forced via `--dart-define=FORCE_DEV_PANEL=true`
  
  **Migration Guide:**
  ```dart
  // Before:
  DevPanelConfig(
    enabled: true,
    showInProduction: false,
  )
  
  // After:
  DevPanelConfig()  // Automatic behavior based on build mode
  
  // To force enable in production:
  // Use: flutter build --dart-define=FORCE_DEV_PANEL=true
  ```

### Performance Improvements
* **Zero overhead in production**: All dev panel code is removed by tree shaking in release builds
* **Compile-time optimization**: Uses `kDebugMode` and environment constants for optimal performance
* **Unified enable check**: Single source of truth for panel state reduces runtime overhead

## 0.0.2

* Fixed Flutter version requirement to 3.10.0 across all packages
* Improved documentation with theme integration examples  
* Synchronized Chinese README with English documentation

## 0.0.1

* Initial release
* Core modular debug panel framework
* Support for multiple debug modules
* Environment switching capability
* Theme management (Light/Dark/System)
* Shake gesture and FAB triggers
* Module registry system