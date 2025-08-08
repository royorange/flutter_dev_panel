import 'package:flutter/material.dart';

/// 可展开/收起的文本组件
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  
  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
  });
  
  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用宽度（减去展开按钮的宽度）
        final availableWidth = constraints.maxWidth - 32; // 为展开按钮预留空间
        
        // 使用TextPainter来检测文本是否会溢出
        final textPainter = TextPainter(
          text: TextSpan(
            text: widget.text,
            style: widget.style ?? const TextStyle(fontSize: 12),
          ),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: availableWidth);
        
        final isOverflowing = textPainter.didExceedMaxLines;
        
        // 如果文本可以展开，整个区域都可以点击
        Widget content = Row(
          crossAxisAlignment: _isExpanded 
              ? CrossAxisAlignment.start 
              : CrossAxisAlignment.center, // 未展开时垂直居中
          children: [
            Expanded(
              child: SelectableText(
                widget.text,
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLines,
              ),
            ),
            if (isOverflowing)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        );
        
        // 如果有溢出，包装在GestureDetector中使整个区域可点击
        if (isOverflowing) {
          content = GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: content,
          );
        }
        
        return content;
      },
    );
  }
}