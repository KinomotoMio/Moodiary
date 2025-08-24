import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final void Function(String tagName)? onTagTap;

  const HighlightedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium!;
    final tagStyle = baseStyle.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      decoration: onTagTap != null ? TextDecoration.underline : null,
      decorationColor: theme.colorScheme.primary.withValues(alpha: 0.6),
    );

    // 使用正则表达式匹配#标签（支持中文、英文、数字）
    final regex = RegExp(r'(#[\u4e00-\u9fff\w]+)', caseSensitive: false);
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      // 没有标签，直接显示普通文本
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // 构建带有高亮标签的RichText
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // 添加标签前的普通文本
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // 添加标签文本
      final tagText = match.group(0)!;
      final tagName = tagText.substring(1); // 移除#号
      
      spans.add(TextSpan(
        text: tagText,
        style: tagStyle,
        recognizer: onTagTap != null 
          ? (TapGestureRecognizer()
              ..onTap = () => onTagTap!(tagName))
          : null,
      ));

      lastIndex = match.end;
    }

    // 添加最后剩余的普通文本
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}