import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 可展开的键值对项目组件
class ExpandableItem extends StatefulWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final double labelWidth;
  final int maxLines;
  
  const ExpandableItem({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.labelWidth = 150,
    this.maxLines = 2,
  });
  
  @override
  State<ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算文本是否会溢出
        final availableWidth = constraints.maxWidth - widget.labelWidth - 8 - 40; // label宽度 + spacing + 复制按钮
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.value,
            style: widget.valueStyle ?? theme.textTheme.bodySmall,
          ),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);
        
        final isOverflowing = textPainter.didExceedMaxLines;
        
        return Container(
          constraints: const BoxConstraints(minHeight: 48), // 确保最小高度
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
          ),
          child: SelectionArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isOverflowing ? () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                } : null,
                highlightColor: isOverflowing ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1) : Colors.transparent,
                splashColor: isOverflowing ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  child: Row(
                    crossAxisAlignment: _isExpanded 
                        ? CrossAxisAlignment.start  // 展开时顶部对齐
                        : CrossAxisAlignment.center, // 未展开时垂直居中
                    children: [
                      // Label部分 - 始终保持固定位置
                      SizedBox(
                        width: widget.labelWidth,
                        child: Padding(
                          padding: _isExpanded 
                              ? const EdgeInsets.only(top: 0) // 展开时无额外间距
                              : EdgeInsets.zero, // 未展开时无额外间距
                          child: Text(
                            widget.label,
                            style: widget.labelStyle ?? theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Value部分
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.value,
                                style: widget.valueStyle ?? theme.textTheme.bodySmall,
                                maxLines: _isExpanded ? null : widget.maxLines,
                                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOverflowing)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: Icon(
                                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // 复制按钮 - 始终垂直居中
                    Padding(
                      padding: _isExpanded 
                          ? const EdgeInsets.only(top: 0) // 展开时可能需要调整
                          : EdgeInsets.zero,
                      child: IconButton(
                        icon: const Icon(Icons.copy, size: 14),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied ${widget.label}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        iconSize: 14,
                        splashRadius: 14,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}