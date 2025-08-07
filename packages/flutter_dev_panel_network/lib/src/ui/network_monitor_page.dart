import 'package:flutter/material.dart';
import '../network_monitor_controller.dart';
import '../models/network_request.dart';
import '../models/network_filter.dart';
import 'widgets/request_list_item.dart';
import 'widgets/request_detail_dialog.dart';

class NetworkMonitorPage extends StatefulWidget {
  final NetworkMonitorController controller;

  const NetworkMonitorPage({
    super.key,
    required this.controller,
  });

  @override
  State<NetworkMonitorPage> createState() => _NetworkMonitorPageState();
}

class _NetworkMonitorPageState extends State<NetworkMonitorPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.filter.searchQuery ?? '';
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.controller.updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Column(
        children: [
          _buildToolbar(theme),
          _buildStatsBar(theme),
          Expanded(
            child: _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search URL, method or status',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterButtons(),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Errors Only'),
              selected: widget.controller.filter.showOnlyErrors,
              onSelected: (selected) {
                widget.controller.setShowOnlyErrors(selected);
              },
              avatar: widget.controller.filter.showOnlyErrors
                  ? const Icon(Icons.check, size: 16)
                  : null,
              visualDensity: VisualDensity.compact,
            ),
            PopupMenuButton<RequestMethod?>(
              tooltip: 'Filter by method',
              child: Chip(
                label: Text(
                  widget.controller.filter.method?.name.toUpperCase() ?? 'All Methods',
                  style: const TextStyle(fontSize: 13),
                ),
                avatar: const Icon(Icons.filter_list, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All Methods'),
                ),
                const PopupMenuDivider(),
                ...RequestMethod.values.map((method) => PopupMenuItem(
                  value: method,
                  child: Text(method.name.toUpperCase()),
                )),
              ],
              onSelected: (method) {
                widget.controller.setMethodFilter(method);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Row(
          children: [
            IconButton(
              icon: Icon(
                widget.controller.isPaused ? Icons.play_arrow : Icons.pause,
              ),
              tooltip: widget.controller.isPaused ? 'Resume' : 'Pause',
              onPressed: widget.controller.togglePause,
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all',
              onPressed: widget.controller.requests.isEmpty
                  ? null
                  : () => _showClearConfirmation(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              _buildStatChip(
                'Total',
                widget.controller.totalRequests,
                Icons.list,
                theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                'Success',
                widget.controller.successCount,
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                'Errors',
                widget.controller.errorCount,
                Icons.error,
                Colors.red,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                'Pending',
                widget.controller.pendingCount,
                Icons.hourglass_empty,
                Colors.orange,
              ),
              const Spacer(),
              if (widget.controller.filter.hasActiveFilters)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear Filters'),
                  onPressed: () {
                    widget.controller.clearFilters();
                    _searchController.clear();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final requests = widget.controller.requests;
        
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.controller.filter.hasActiveFilters
                      ? 'No requests match the current filters'
                      : 'No network requests yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return RequestListItem(
              key: ValueKey(request.id),
              request: request,
              onTap: () => _showRequestDetail(context, request),
            );
          },
        );
      },
    );
  }

  void _showRequestDetail(BuildContext context, NetworkRequest request) {
    showDialog(
      context: context,
      builder: (context) => RequestDetailDialog(request: request),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Requests'),
        content: const Text('Are you sure you want to clear all network requests?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.controller.clearRequests();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Monitor Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Maximum Requests'),
              subtitle: Text('Currently: ${widget.controller.maxRequests}'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  controller: TextEditingController(
                    text: widget.controller.maxRequests.toString(),
                  ),
                  onSubmitted: (value) {
                    final max = int.tryParse(value);
                    if (max != null && max > 0) {
                      widget.controller.setMaxRequests(max);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}