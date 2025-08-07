import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../models/network_request.dart';

class NetworkRequestDetailPage extends StatelessWidget {
  final NetworkRequest request;
  
  const NetworkRequestDetailPage({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${request.method} ${request.statusCode ?? ''}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '概览'),
              Tab(text: '请求'),
              Tab(text: '响应'),
              Tab(text: '错误'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyAllToClipboard(context),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildRequestTab(),
            _buildResponseTab(),
            _buildErrorTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: 'URL',
          child: SelectableText(
            request.uri.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        _buildInfoCard(
          title: '方法',
          child: Text(
            request.method,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        _buildInfoCard(
          title: '状态码',
          child: Text(
            request.statusCode?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getStatusColor(request.statusCode),
            ),
          ),
        ),
        _buildInfoCard(
          title: '开始时间',
          child: Text(
            dateFormat.format(request.startTime),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (request.endTime != null)
          _buildInfoCard(
            title: '结束时间',
            child: Text(
              dateFormat.format(request.endTime!),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        _buildInfoCard(
          title: '耗时',
          child: Text(
            '${request.duration.inMilliseconds} ms',
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (request.requestSize != null)
          _buildInfoCard(
            title: '请求大小',
            child: Text(
              _formatBytes(request.requestSize!),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        if (request.responseSize != null)
          _buildInfoCard(
            title: '响应大小',
            child: Text(
              _formatBytes(request.responseSize!),
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildRequestTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (request.requestHeaders != null) ...[
          _buildSectionTitle('请求头'),
          _buildJsonView(request.requestHeaders!),
          const SizedBox(height: 16),
        ],
        if (request.requestBody != null) ...[
          _buildSectionTitle('请求体'),
          _buildJsonView(request.requestBody),
        ],
      ],
    );
  }

  Widget _buildResponseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (request.responseHeaders != null) ...[
          _buildSectionTitle('响应头'),
          _buildJsonView(request.responseHeaders!),
          const SizedBox(height: 16),
        ],
        if (request.responseBody != null) ...[
          _buildSectionTitle('响应体'),
          _buildJsonView(request.responseBody),
        ],
      ],
    );
  }

  Widget _buildErrorTab() {
    if (request.error == null) {
      return const Center(
        child: Text(
          '无错误信息',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: '错误信息',
          child: SelectableText(
            request.error!,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJsonView(dynamic data) {
    String formatted;
    try {
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          formatted = const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {
          formatted = data;
        }
      } else {
        formatted = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (_) {
      formatted = data.toString();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          formatted,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(int? statusCode) {
    if (statusCode == null) return Colors.grey;
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.orange;
    if (statusCode >= 400) return Colors.red;
    return Colors.grey;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _copyAllToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('=== Network Request Details ===');
    buffer.writeln('URL: ${request.uri}');
    buffer.writeln('Method: ${request.method}');
    buffer.writeln('Status: ${request.statusCode}');
    buffer.writeln('Duration: ${request.duration.inMilliseconds}ms');
    
    if (request.requestHeaders != null) {
      buffer.writeln('\n=== Request Headers ===');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(request.requestHeaders));
    }
    
    if (request.requestBody != null) {
      buffer.writeln('\n=== Request Body ===');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(request.requestBody));
    }
    
    if (request.responseHeaders != null) {
      buffer.writeln('\n=== Response Headers ===');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(request.responseHeaders));
    }
    
    if (request.responseBody != null) {
      buffer.writeln('\n=== Response Body ===');
      buffer.writeln(const JsonEncoder.withIndent('  ').convert(request.responseBody));
    }
    
    if (request.error != null) {
      buffer.writeln('\n=== Error ===');
      buffer.writeln(request.error);
    }
    
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    Get.snackbar(
      '复制成功',
      '请求详情已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}