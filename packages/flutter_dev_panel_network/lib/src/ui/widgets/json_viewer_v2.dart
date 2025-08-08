import 'dart:convert';
import 'package:flutter/material.dart';

/// 改进版的JSON查看器，更好地处理深度嵌套的对象
class JsonViewerV2 extends StatefulWidget {
  final String jsonString;
  final TextStyle? style;
  
  const JsonViewerV2({
    super.key,
    required this.jsonString,
    this.style,
  });
  
  @override
  State<JsonViewerV2> createState() => _JsonViewerV2State();
}

class _JsonViewerV2State extends State<JsonViewerV2> {
  dynamic _jsonData;
  final Set<String> _expandedKeys = {};
  
  @override
  void initState() {
    super.initState();
    _parseJson();
    // 默认展开第一层
    _expandedKeys.add('root');
  }
  
  @override
  void didUpdateWidget(JsonViewerV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonString != widget.jsonString) {
      _parseJson();
    }
  }
  
  void _parseJson() {
    try {
      _jsonData = json.decode(widget.jsonString);
    } catch (e) {
      _jsonData = null;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_jsonData == null) {
      // 不是JSON，显示原始文本
      return SelectableText(
        widget.jsonString,
        style: widget.style ?? TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    
    return Container(
      constraints: const BoxConstraints(maxWidth: double.infinity),
      child: _buildJsonTree(_jsonData, 'root', 0),
    );
  }
  
  Widget _buildJsonTree(dynamic data, String path, int depth) {
    if (data == null) {
      return _buildPrimitiveValue('null', Colors.grey);
    }
    
    if (data is bool) {
      return _buildPrimitiveValue(data.toString(), Colors.blue);
    }
    
    if (data is num) {
      return _buildPrimitiveValue(data.toString(), Colors.purple);
    }
    
    if (data is String) {
      return _buildStringValue(data);
    }
    
    if (data is List) {
      return _buildListView(data, path, depth);
    }
    
    if (data is Map) {
      return _buildMapView(data, path, depth);
    }
    
    return _buildPrimitiveValue(data.toString(), null);
  }
  
  Widget _buildPrimitiveValue(String value, Color? color) {
    return SelectableText(
      value,
      style: widget.style?.copyWith(color: color) ?? 
             TextStyle(
               fontFamily: 'monospace',
               fontSize: 12,
               color: color ?? Theme.of(context).colorScheme.onSurface,
             ),
    );
  }
  
  Widget _buildStringValue(String value) {
    final needsTruncate = value.length > 100;
    final displayValue = needsTruncate ? '"${value.substring(0, 100)}..."' : '"$value"';
    
    if (!needsTruncate) {
      return _buildPrimitiveValue(displayValue, Colors.green);
    }
    
    return Tooltip(
      message: value,
      child: _buildPrimitiveValue(displayValue, Colors.green),
    );
  }
  
  Widget _buildListView(List list, String path, int depth) {
    if (list.isEmpty) {
      return _buildPrimitiveValue('[]', null);
    }
    
    final isExpanded = _expandedKeys.contains(path);
    
    // 简单值的列表可以内联显示
    final hasOnlyPrimitives = list.every((item) => 
      item == null || item is bool || item is num || item is String);
    
    if (hasOnlyPrimitives && list.length <= 3 && !isExpanded) {
      // 内联显示简单列表
      final items = list.map((item) => _formatPrimitive(item)).join(', ');
      return _buildPrimitiveValue('[$items]', null);
    }
    
    // 复杂列表或长列表
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedKeys.remove(path);
                  } else {
                    _expandedKeys.add(path);
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _buildPrimitiveValue('[', null),
                  if (!isExpanded)
                    Text(
                      ' ${list.length} items ]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: list.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == list.length - 1;
                
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$index:',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Flexible(
                        child: _buildJsonTree(item, '$path[$index]', depth + 1),
                      ),
                      if (!isLast)
                        _buildPrimitiveValue(',', null),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          _buildPrimitiveValue(']', null),
        ],
      ],
    );
  }
  
  Widget _buildMapView(Map map, String path, int depth) {
    if (map.isEmpty) {
      return _buildPrimitiveValue('{}', null);
    }
    
    final isExpanded = _expandedKeys.contains(path);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedKeys.remove(path);
                  } else {
                    _expandedKeys.add(path);
                  }
                });
              },
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _buildPrimitiveValue('{', null),
                  if (!isExpanded)
                    Text(
                      ' ${map.length} fields }',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (isExpanded) ...[
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: map.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                final isLast = entry.key == map.keys.last;
                final fieldPath = '$path.$key';
                
                // 对于简单值，内联显示
                final isSimpleValue = value == null || 
                    value is bool || 
                    value is num || 
                    (value is String && value.length < 50);
                
                if (isSimpleValue) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrimitiveValue('"$key": ', Colors.blue),
                        Flexible(
                          child: _buildJsonTree(value, fieldPath, depth + 1),
                        ),
                        if (!isLast)
                          _buildPrimitiveValue(',', null),
                      ],
                    ),
                  );
                }
                
                // 对于复杂值，使用可折叠的显示
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildPrimitiveValue('"$key": ', Colors.blue),
                          Flexible(
                            child: _buildJsonTree(value, fieldPath, depth + 1),
                          ),
                          if (!isLast)
                            _buildPrimitiveValue(',', null),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          _buildPrimitiveValue('}', null),
        ],
      ],
    );
  }
  
  String _formatPrimitive(dynamic value) {
    if (value == null) return 'null';
    if (value is String) {
      if (value.length > 20) {
        return '"${value.substring(0, 20)}..."';
      }
      return '"$value"';
    }
    return value.toString();
  }
}