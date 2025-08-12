# Flutter Dev Panel Tests

## Running Tests

### Run All Tests
```bash
# From project root
./test/run_all_tests.sh

# Or using Flutter directly
flutter test
```

### Run Individual Module Tests
```bash
# Core package tests
flutter test test/

# Console module tests
flutter test packages/flutter_dev_panel_console/test

# Network module tests  
flutter test packages/flutter_dev_panel_network/test

# Device module tests
flutter test packages/flutter_dev_panel_device/test

# Performance module tests
flutter test packages/flutter_dev_panel_performance/test
```

## Test Coverage

- **Core Package**: 18 tests
  - Module registration (4 tests)
  - Configuration management (3 tests)
  - Network integration (2 tests)
  - Environment management (6 tests)
  - DevLogger functionality (3 tests)

- **Console Module**: 23 tests
  - Log capture and filtering
  - Configuration persistence
  - Log level management

- **Network Module**: 25 tests
  - Request/response tracking
  - Session statistics
  - Dio/GraphQL integration

- **Device Module**: 1 test
  - Module registration

- **Performance Module**: 22 tests
  - FPS monitoring
  - Memory tracking
  - Metrics calculation

## Notes

- SharedPreferences warnings in tests are expected and can be ignored
- Tests run in isolation and don't affect production code
- All modules are tested independently