import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/network_request.dart';

class RequestDetailDialog extends StatefulWidget {
  final NetworkRequest request;

  const RequestDetailDialog({
    super.key,
    required this.request,
  });

  @override
  State<RequestDetailDialog> createState() => _RequestDetailDialogState();
}

class _RequestDetailDialogState extends State<RequestDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            _buildHeader(context, colorScheme),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Request'),
                Tab(text: 'Response'),
                Tab(text: 'Headers'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildRequestTab(theme),
                  _buildResponseTab(theme),
                  _buildHeadersTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          _buildMethodBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.url,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.request.statusCode != null)
                  Text(
                    '${widget.request.statusCode} ${widget.request.statusMessage ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodBadge() {
    Color backgroundColor;
    Color foregroundColor;
    
    switch (widget.request.method) {
      case RequestMethod.get:
        backgroundColor = Colors.blue;
        foregroundColor = Colors.white;
        break;
      case RequestMethod.post:
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        break;
      case RequestMethod.put:
        backgroundColor = Colors.orange;
        foregroundColor = Colors.white;
        break;
      case RequestMethod.delete:
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        break;
      default:
        backgroundColor = Colors.grey;
        foregroundColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.request.methodString,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final items = <_InfoItem>[
      _InfoItem('URL', widget.request.url),
      _InfoItem('Method', widget.request.methodString),
      if (widget.request.statusCode != null)
        _InfoItem('Status Code', widget.request.statusCode.toString()),
      if (widget.request.statusMessage != null)
        _InfoItem('Status Message', widget.request.statusMessage!),
      _InfoItem('Start Time', _formatDateTime(widget.request.startTime)),
      if (widget.request.endTime != null)
        _InfoItem('End Time', _formatDateTime(widget.request.endTime!)),
      if (widget.request.duration != null)
        _InfoItem('Duration', '${widget.request.duration!.inMilliseconds}ms'),
      if (widget.request.requestSize != null)
        _InfoItem('Request Size', _formatSize(widget.request.requestSize!)),
      if (widget.request.responseSize != null)
        _InfoItem('Response Size', _formatSize(widget.request.responseSize!)),
      if (widget.request.error != null)
        _InfoItem('Error', widget.request.error!),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: items.map((item) => _buildInfoRow(item, theme)).toList(),
    );
  }

  Widget _buildRequestTab(ThemeData theme) {
    final requestBody = widget.request.formattedRequestBody;
    
    return Column(
      children: [
        if (requestBody.isNotEmpty) ...[
          Expanded(
            child: _buildCodeView(requestBody, theme),
          ),
          _buildCopyButton(requestBody),
        ] else
          Expanded(
            child: Center(
              child: Text(
                'No request body',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResponseTab(ThemeData theme) {
    final responseBody = widget.request.formattedResponseBody;
    
    return Column(
      children: [
        if (responseBody.isNotEmpty) ...[
          Expanded(
            child: _buildCodeView(responseBody, theme),
          ),
          _buildCopyButton(responseBody),
        ] else
          Expanded(
            child: Center(
              child: Text(
                'No response body',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeadersTab(ThemeData theme) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Request Headers'),
              Tab(text: 'Response Headers'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHeadersList(widget.request.headers, theme),
                _buildHeadersList(widget.request.responseHeaders, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadersList(Map<String, dynamic> headers, ThemeData theme) {
    if (headers.isEmpty) {
      return Center(
        child: Text(
          'No headers',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: headers.length,
      itemBuilder: (context, index) {
        final key = headers.keys.elementAt(index);
        final value = headers[key];
        return _buildInfoRow(_InfoItem(key, value.toString()), theme);
      },
    );
  }

  Widget _buildInfoRow(_InfoItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              item.value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeView(String code, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton.tonal(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy, size: 16),
              SizedBox(width: 8),
              Text('Copy'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}