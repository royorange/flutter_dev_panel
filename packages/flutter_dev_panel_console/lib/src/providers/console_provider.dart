import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dev_panel_core/flutter_dev_panel_core.dart';

/// Console 模块的状态管理
class ConsoleProvider extends GetxController {
  // 日志列表
  final RxList<LogEntry> logs = <LogEntry>[].obs;
  
  // 过滤后的日志列表
  final RxList<LogEntry> filteredLogs = <LogEntry>[].obs;
  
  // 当前选中的日志级别过滤
  final Rx<LogLevel?> selectedLevel = Rx<LogLevel?>(null);
  
  // 搜索关键词
  final RxString searchText = ''.obs;
  
  // 是否自动滚动到底部
  final RxBool autoScroll = true.obs;
  
  // 是否暂停接收新日志
  final RxBool isPaused = false.obs;
  
  // 日志流订阅
  StreamSubscription<LogEntry>? _logSubscription;
  
  // ScrollController for auto-scroll
  final ScrollController scrollController = ScrollController();
  
  @override
  void onInit() {
    super.onInit();
    _loadExistingLogs();
    _startListening();
    _setupFilters();
  }
  
  @override
  void onClose() {
    _logSubscription?.cancel();
    scrollController.dispose();
    super.onClose();
  }
  
  /// 加载已存在的日志
  void _loadExistingLogs() {
    final existingLogs = DevLogger.instance.logs;
    logs.addAll(existingLogs);
    _applyFilters();
  }
  
  /// 开始监听新日志
  void _startListening() {
    _logSubscription = DevLogger.instance.logStream.listen((log) {
      if (!isPaused.value) {
        logs.add(log);
        _applyFilters();
        _scrollToBottom();
      }
    });
  }
  
  /// 设置过滤器监听
  void _setupFilters() {
    // 监听级别过滤变化
    ever(selectedLevel, (_) => _applyFilters());
    
    // 监听搜索文本变化（添加防抖）
    debounce(
      searchText,
      (_) => _applyFilters(),
      time: const Duration(milliseconds: 300),
    );
  }
  
  /// 应用过滤器
  void _applyFilters() {
    var filtered = logs.toList();
    
    // 按日志级别过滤
    if (selectedLevel.value != null) {
      filtered = filtered.where((log) => 
        log.level.index >= selectedLevel.value!.index
      ).toList();
    }
    
    // 按搜索文本过滤
    if (searchText.value.isNotEmpty) {
      final search = searchText.value.toLowerCase();
      filtered = filtered.where((log) =>
        log.message.toLowerCase().contains(search) ||
        (log.error?.toLowerCase().contains(search) ?? false)
      ).toList();
    }
    
    filteredLogs.value = filtered;
  }
  
  /// 滚动到底部
  void _scrollToBottom() {
    if (autoScroll.value && scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }
  
  /// 清空日志
  void clearLogs() {
    logs.clear();
    filteredLogs.clear();
    DevLogger.instance.clear();
  }
  
  /// 切换暂停状态
  void togglePause() {
    isPaused.value = !isPaused.value;
  }
  
  /// 切换自动滚动
  void toggleAutoScroll() {
    autoScroll.value = !autoScroll.value;
    if (autoScroll.value) {
      _scrollToBottom();
    }
  }
  
  /// 设置日志级别过滤
  void setLevelFilter(LogLevel? level) {
    selectedLevel.value = level;
  }
  
  /// 获取日志级别的颜色
  Color getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
  
  /// 获取日志级别的图标
  IconData getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Icons.chat_bubble_outline;
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }
  
  /// 获取日志统计信息
  Map<LogLevel, int> getLogStatistics() {
    final stats = <LogLevel, int>{};
    for (final level in LogLevel.values) {
      stats[level] = logs.where((log) => log.level == level).length;
    }
    return stats;
  }
}