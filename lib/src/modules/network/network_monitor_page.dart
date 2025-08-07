import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/network_request.dart';
import 'network_monitor_controller.dart';
import 'network_request_detail_page.dart';

class NetworkMonitorPage extends StatelessWidget {
  const NetworkMonitorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NetworkMonitorController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络监控'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('清空请求记录'),
                  content: const Text('确定要清空所有网络请求记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clearRequests();
                        Get.back();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildStatusFilter(controller),
          _buildStatistics(controller),
          Expanded(
            child: _buildRequestList(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(NetworkMonitorController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索 URL、方法或状态码...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: controller.setSearchQuery,
      ),
    );
  }

  Widget _buildStatusFilter(NetworkMonitorController controller) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Obx(() => ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: '全部',
            selected: controller.selectedStatusFilter == null,
            onSelected: (_) => controller.setStatusFilter(null),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '成功',
            selected: controller.selectedStatusFilter == NetworkRequestStatus.success,
            onSelected: (_) => controller.setStatusFilter(NetworkRequestStatus.success),
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '错误',
            selected: controller.selectedStatusFilter == NetworkRequestStatus.error,
            onSelected: (_) => controller.setStatusFilter(NetworkRequestStatus.error),
            color: Colors.red,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: '进行中',
            selected: controller.selectedStatusFilter == NetworkRequestStatus.pending,
            onSelected: (_) => controller.setStatusFilter(NetworkRequestStatus.pending),
            color: Colors.orange,
          ),
        ],
      )),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Function(bool) onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: color?.withValues(alpha: 0.2),
      checkmarkColor: color,
    );
  }

  Widget _buildStatistics(NetworkMonitorController controller) {
    return Obx(() {
      final stats = controller.getStatistics();
      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('总计', stats['total'] ?? 0, Colors.blue),
            _buildStatItem('成功', stats['success'] ?? 0, Colors.green),
            _buildStatItem('错误', stats['error'] ?? 0, Colors.red),
            _buildStatItem('进行中', stats['pending'] ?? 0, Colors.orange),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestList(NetworkMonitorController controller) {
    return Obx(() {
      final requests = controller.requests;
      
      if (requests.isEmpty) {
        return const Center(
          child: Text(
            '暂无网络请求',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      
      return ListView.builder(
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestItem(context, request);
        },
      );
    });
  }

  Widget _buildRequestItem(BuildContext context, NetworkRequest request) {
    final timeFormat = DateFormat('HH:mm:ss.SSS');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Get.to(() => NetworkRequestDetailPage(request: request));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMethodChip(request.method),
                  const SizedBox(width: 8),
                  _buildStatusChip(request),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(request.startTime),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${request.duration.inMilliseconds}ms',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.uri.toString(),
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (request.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  request.error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    Color color;
    switch (method.toUpperCase()) {
      case 'GET':
        color = Colors.blue;
        break;
      case 'POST':
        color = Colors.green;
        break;
      case 'PUT':
        color = Colors.orange;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip(NetworkRequest request) {
    Color color;
    String text;
    
    switch (request.status) {
      case NetworkRequestStatus.success:
        color = Colors.green;
        text = '${request.statusCode}';
        break;
      case NetworkRequestStatus.error:
        color = Colors.red;
        text = request.statusCode?.toString() ?? 'ERROR';
        break;
      case NetworkRequestStatus.pending:
        color = Colors.orange;
        text = '...';
        break;
      case NetworkRequestStatus.cancelled:
        color = Colors.grey;
        text = 'CANCELLED';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}