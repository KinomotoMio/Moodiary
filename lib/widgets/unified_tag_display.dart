import 'package:flutter/material.dart';
import '../utils/tag_utils.dart';

/// 统一的标签显示组件
/// 
/// 提供一致的标签展示体验，支持多种显示样式和交互模式
class UnifiedTagDisplay extends StatelessWidget {
  final List<String> tags;
  final TagChipStyle style;
  final Function(String)? onTagTap;
  final int? maxVisibleTags;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final bool showMoreIndicator;
  final String source;

  const UnifiedTagDisplay({
    super.key,
    required this.tags,
    this.style = TagChipStyle.normal,
    this.onTagTap,
    this.maxVisibleTags,
    this.spacing = 8.0,
    this.runSpacing = 4.0,
    this.alignment = WrapAlignment.start,
    this.showMoreIndicator = true,
    this.source = 'unified_display',
  });

  /// 从文本内容创建标签显示
  factory UnifiedTagDisplay.fromContent(
    String content, {
    TagChipStyle style = TagChipStyle.normal,
    Function(String)? onTagTap,
    int? maxVisibleTags,
    double spacing = 8.0,
    double runSpacing = 4.0,
    WrapAlignment alignment = WrapAlignment.start,
    String source = 'content_display',
  }) {
    final tags = TagUtils.extractTags(content);
    return UnifiedTagDisplay(
      tags: tags,
      style: style,
      onTagTap: onTagTap,
      maxVisibleTags: maxVisibleTags,
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      source: source,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final displayTags = maxVisibleTags != null && tags.length > maxVisibleTags!
        ? tags.take(maxVisibleTags!).toList()
        : tags;

    final widgets = <Widget>[];

    // 添加标签芯片
    for (final tag in displayTags) {
      widgets.add(
        TagUtils.createTagChip(
          context,
          tag,
          onTap: onTagTap != null 
            ? () => onTagTap!(tag) 
            : () => TagUtils.navigateToTag(context, tag, source: source),
          style: style,
        ),
      );
    }

    // 添加"更多"指示器
    if (maxVisibleTags != null && 
        tags.length > maxVisibleTags! && 
        showMoreIndicator) {
      widgets.add(_buildMoreIndicator(context));
    }

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: widgets,
    );
  }

  Widget _buildMoreIndicator(BuildContext context) {
    final remainingCount = tags.length - maxVisibleTags!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '+$remainingCount',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          fontSize: _getFontSizeForStyle(style),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  double _getFontSizeForStyle(TagChipStyle style) {
    switch (style) {
      case TagChipStyle.small:
        return 11;
      case TagChipStyle.large:
        return 14;
      case TagChipStyle.normal:
        return 12;
    }
  }
}

/// 简化的标签列表展示组件
/// 
/// 用于需要简单标签列表的场景
class SimpleTagList extends StatelessWidget {
  final List<String> tags;
  final Function(String)? onTagTap;
  final String separator;
  final int maxTags;
  final TextStyle? textStyle;

  const SimpleTagList({
    super.key,
    required this.tags,
    this.onTagTap,
    this.separator = ' · ',
    this.maxTags = 5,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final displayTags = tags.length > maxTags
        ? tags.take(maxTags).toList()
        : tags;

    final spans = <TextSpan>[];
    
    for (int i = 0; i < displayTags.length; i++) {
      final tag = displayTags[i];
      
      // 添加标签
      spans.add(
        TextSpan(
          text: '#$tag',
          style: (textStyle ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          recognizer: onTagTap != null
            ? (TapGestureRecognizer()..onTap = () => onTagTap!(tag))
            : null,
        ),
      );
      
      // 添加分隔符（除了最后一个）
      if (i < displayTags.length - 1) {
        spans.add(
          TextSpan(
            text: separator,
            style: textStyle ?? Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
    }

    // 添加"更多"指示器
    if (tags.length > maxTags) {
      spans.add(
        TextSpan(
          text: '$separator+${tags.length - maxTags}',
          style: (textStyle ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// 标签统计显示组件
/// 
/// 用于显示标签的使用统计信息
class TagStatsDisplay extends StatelessWidget {
  final Map<String, int> tagStats;
  final int maxDisplayTags;
  final Function(String)? onTagTap;

  const TagStatsDisplay({
    super.key,
    required this.tagStats,
    this.maxDisplayTags = 10,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tagStats.isEmpty) return const SizedBox.shrink();

    final sortedEntries = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayEntries = sortedEntries.take(maxDisplayTags).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '热门标签',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: displayEntries.map((entry) {
            return _buildStatChip(context, entry.key, entry.value);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String tag, int count) {
    return GestureDetector(
      onTap: onTagTap != null ? () => onTagTap!(tag) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: 12,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 需要导入手势识别器
import 'package:flutter/gestures.dart';