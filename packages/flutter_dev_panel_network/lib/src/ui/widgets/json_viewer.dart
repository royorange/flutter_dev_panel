import 'dart:convert';
import 'package:flutter/material.dart';

/// JSON查看器，支持字段级别的展开/收起
class JsonViewer extends StatefulWidget {
  final String jsonString;
  final TextStyle? style;
  
  const JsonViewer({
    super.key,
    required this.jsonString,
    this.style,
  });
  
  @override
  State<JsonViewer> createState() => _JsonViewerState();
}

class _JsonViewerState extends State<JsonViewer> {
  dynamic _jsonData;
  final Set<String> _expandedKeys = {};
  
  @override
  void initState() {
    super.initState();
    _parseJson();
    // 默认展开顶层
    _expandedKeys.add('');
  }
  
  @override
  void didUpdateWidget(JsonViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jsonString != widget.jsonString) {
      _parseJson();
    }
  }
  
  void _parseJson() {
    try {
      _jsonData = json.decode(widget.jsonString);
    } catch (e) {
      _jsonData = null; // 不是JSON就显示原始文本
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
    
    return _buildJsonTree(_jsonData, '');
  }
  
  Widget _buildJsonTree(dynamic data, String path) {
    if (data == null) {
      return _buildValue('null', path, Colors.grey);
    }
    
    if (data is bool) {
      return _buildValue(data.toString(), path, Colors.blue);
    }
    
    if (data is num) {
      return _buildValue(data.toString(), path, Colors.purple);
    }
    
    if (data is String) {
      return _buildStringValue(data, path);
    }
    
    if (data is List) {
      return _buildList(data, path);
    }
    
    if (data is Map) {
      return _buildMap(data, path);
    }
    
    return _buildValue(data.toString(), path, null);
  }
  
  Widget _buildStringValue(String value, String path) {
    final theme = Theme.of(context);
    final needsExpansion = value.length > 50 || value.contains('\n'); // 降低阈值
    final isExpanded = _expandedKeys.contains(path);
    
    if (!needsExpansion) {
      return _buildValue('"$value"', path, Colors.green);
    }
    
    // 对于长字符串，提供展开/收起功能
    if (!isExpanded) {
      // 收起状态：显示截断的文本 + 展开按钮
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          SelectableText(
            '"${_truncateString(value)}"',
            style: widget.style?.copyWith(color: Colors.green) ?? 
                   const TextStyle(
                     fontFamily: 'monospace',
                     fontSize: 12,
                     color: Colors.green,
                   ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _expandedKeys.add(path);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'show all',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // 展开状态：显示完整文本 + 收起按钮
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          '"$value"',
          style: widget.style?.copyWith(color: Colors.green) ?? 
                 const TextStyle(
                   fontFamily: 'monospace',
                   fontSize: 12,
                   color: Colors.green,
                 ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () {
            setState(() {
              _expandedKeys.remove(path);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'hide',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  String _truncateString(String value) {
    const maxLength = 40; // 减少长度避免溢出
    if (value.length <= maxLength) return value;
    
    // 如果有换行符，在第一个换行符处截断
    final newlineIndex = value.indexOf('\n');
    if (newlineIndex > 0 && newlineIndex < maxLength) {
      return '${value.substring(0, newlineIndex)}...';
    }
    
    return '${value.substring(0, maxLength)}...';
  }
  
  Widget _buildValue(String value, String path, Color? color) {
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
  
  Widget _buildList(List list, String path) {
    final theme = Theme.of(context);
    final isRoot = path.isEmpty; // 判断是否是顶层
    final isExpanded = _expandedKeys.contains(path);
    
    if (list.isEmpty) {
      return _buildValue('[]', path, null);
    }
    
    // 决定是否需要折叠功能
    final needsCollapse = !isRoot && list.length > 3;
    
    // 未展开时显示折叠状态
    if (needsCollapse && !isExpanded) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          _buildValue('[...', path, null),
          Text(
            ' ${list.length} items ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _buildValue('...]', path, null),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedKeys.add(path);
              });
            },
            child: Text(
              'expand',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildValue('[', path, null),
            // 需要折叠功能且已展开时显示collapse按钮
            if (needsCollapse && isExpanded) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedKeys.remove(path);
                  });
                },
                child: Text(
                  'collapse',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == list.length - 1;
              
              return Wrap(
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  _buildJsonTree(item, '$path[$index]'),
                  if (!isLast)
                    _buildValue(',', '', null),
                ],
              );
            }).toList(),
          ),
        ),
        _buildValue(']', path, null),
      ],
    );
  }
  
  Widget _buildMap(Map map, String path) {
    final theme = Theme.of(context);
    final isRoot = path.isEmpty; // 判断是否是顶层
    final isExpanded = _expandedKeys.contains(path);
    
    if (map.isEmpty) {
      return _buildValue('{}', path, null);
    }
    
    // 决定是否需要折叠功能
    final needsCollapse = !isRoot && map.length > 3;
    
    // 未展开时显示折叠状态
    if (needsCollapse && !isExpanded) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          _buildValue('{...', path, null),
          Text(
            ' ${map.length} fields ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          _buildValue('...}', path, null),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedKeys.add(path);
              });
            },
            child: Text(
              'expand',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildValue('{', path, null),
            // 需要折叠功能且已展开时显示collapse按钮
            if (needsCollapse && isExpanded) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedKeys.remove(path);
                  });
                },
                child: Text(
                  'collapse',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: map.entries.map((entry) {
              final key = entry.key;
              final value = entry.value;
              final isLast = entry.key == map.keys.last;
              final fieldPath = path.isEmpty ? key.toString() : '$path.$key';
              
              // 对于简单值和短字符串，保持在同一行
              final isSimpleValue = value == null || 
                  value is bool || 
                  value is num || 
                  (value is String && value.length < 50 && !value.contains('\n'));
              
              if (isSimpleValue) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      _buildValue('"$key": ', fieldPath, Colors.blue),
                      _buildJsonTree(value, fieldPath),
                      if (!isLast)
                        _buildValue(',', '', null),
                    ],
                  ),
                );
              }
              
              // 对于长字符串，使用 Wrap 允许换行
              if (value is String) {
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      _buildValue('"$key": ', fieldPath, Colors.blue),
                      _buildJsonTree(value, fieldPath),
                      if (!isLast)
                        _buildValue(',', '', null),
                    ],
                  ),
                );
              }
              
              // 对于复杂对象（数组、嵌套对象），使用垂直布局
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildValue('"$key": ', fieldPath, Colors.blue),
                    _buildJsonTree(value, fieldPath),
                    if (!isLast)
                      _buildValue(',', '', null),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        _buildValue('}', path, null),
      ],
    );
  }
}