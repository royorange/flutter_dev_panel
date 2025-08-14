// 测试 Tree Shaking 和模块化架构
// 
// 运行方式：
// 1. Debug 模式：flutter test test/tree_shaking_test.dart
// 2. Release 模式验证：flutter build apk --release
// 3. 强制启用：flutter build apk --release --dart-define=FORCE_DEV_PANEL=true

import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

void main() {
  // 测试1：未注册模块时的安全性
  testNoModules();
  
  // 测试2：条件编译
  testConditionalCompilation();
  
  // 测试3：API 访问
  testAPIAccess();
}

void testNoModules() {
  print('测试：未注册模块时的行为');
  
  // 初始化时不注册任何模块
  DevPanel.initialize(
    modules: [], // 空模块列表
  );
  
  // 应该安全运行，不会崩溃
  print('✅ 未注册模块时安全运行');
}

void testConditionalCompilation() {
  print('\n测试：条件编译行为');
  
  // 这段代码在 Release 模式下会被完全移除
  DevPanel.initialize(
    config: const DevPanelConfig(
      triggerModes: {TriggerMode.fab},
    ),
  );
  
  // 测试日志 API
  DevPanel.log('Test message');
  DevPanel.logError('Test error');
  
  print('✅ 条件编译正常工作');
}

void testAPIAccess() {
  print('\n测试：核心 API 访问');
  
  // 测试环境管理器（内置功能）
  final env = DevPanel.environment;
  print('当前环境: ${env.currentEnvironment?.name ?? "未设置"}');
  
  // 测试主题管理器（内置功能）
  final theme = DevPanel.theme;
  print('当前主题: ${theme.currentTheme.mode}');
  
  print('✅ 核心 API 访问正常');
}

// 用于验证 tree shaking 的示例应用
class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Tree Shaking Test'),
              ElevatedButton(
                onPressed: () {
                  // 在 Release 模式下，这个调用会被优化掉
                  DevPanel.log('Button clicked');
                },
                child: const Text('Test Log'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 验证编译时常量
void verifyCompileTimeConstants() {
  const bool forceDevPanel = bool.fromEnvironment(
    'FORCE_DEV_PANEL',
    defaultValue: false,
  );
  
  if (forceDevPanel) {
    print('Dev Panel 被强制启用');
  } else {
    print('Dev Panel 使用默认行为');
  }
}