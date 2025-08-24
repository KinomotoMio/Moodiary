import 'package:flutter/material.dart';
import '../models/mood_fragment.dart';
import '../screens/topic_tags_screen.dart';

/// 统一的标签交互和处理工具类
/// 
/// 提供标签提取、显示、导航和缓存等功能
class TagUtils {
  // 标签提取的正则表达式（支持中英文）
  static final RegExp _tagRegex = RegExp(r'#([\u4e00-\u9fff\w]+)');
  
  // 标签提取结果缓存
  static final Map<String, List<String>> _extractCache = {};
  static final Map<String, String> _displayCache = {};

  /// 从文本中提取标签列表
  /// 
  /// `content` - 要提取标签的文本内容
  /// `useCache` - 是否使用缓存，默认true
  /// 
  /// Returns: List`<String>` - 提取的标签名列表（不包含#）
  static List<String> extractTags(String content, {bool useCache = true}) {
    if (content.isEmpty) return [];
    
    // 检查缓存
    if (useCache && _extractCache.containsKey(content)) {
      return _extractCache[content]!;
    }
    
    final matches = _tagRegex.allMatches(content);
    final tags = matches
        .map((match) => match.group(1)!)
        .toSet() // 去重
        .toList();
    
    // 存储到缓存
    if (useCache) {
      _extractCache[content] = tags;
    }
    
    return tags;
  }

  /// 获取去除标签后的纯净显示内容
  /// 
  /// `content` - 原始文本内容
  /// `useCache` - 是否使用缓存，默认true
  /// 
  /// Returns: String - 去除标签后的文本
  static String getDisplayContent(String content, {bool useCache = true}) {
    if (content.isEmpty) return '';
    
    // 检查缓存
    if (useCache && _displayCache.containsKey(content)) {
      return _displayCache[content]!;
    }
    
    // 移除所有标签并清理多余空格
    String displayContent = content.replaceAll(_tagRegex, '').trim();
    displayContent = displayContent.replaceAll(RegExp(r'\s+'), ' ');
    
    // 存储到缓存
    if (useCache) {
      _displayCache[content] = displayContent;
    }
    
    return displayContent;
  }

  /// 检查文本是否包含特定标签
  /// 
  /// `content` - 文本内容
  /// `tagName` - 标签名（不包含#）
  /// 
  /// Returns: bool - 是否包含该标签
  static bool containsTag(String content, String tagName) {
    final tags = extractTags(content);
    return tags.contains(tagName);
  }

  /// 统一的标签点击导航处理
  /// 
  /// `context` - 导航上下文
  /// `tagName` - 被点击的标签名
  /// `source` - 来源标识，用于分析和调试
  /// 
  static void navigateToTag(
    BuildContext context, 
    String tagName, {
    String source = 'unknown',
  }) {
    // 添加简单的分析日志
    debugPrint('Tag navigation: $tagName from $source');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TopicTagsScreen(initialSearchQuery: tagName),
      ),
    );
  }

  /// 创建标签芯片组件
  /// 
  /// `context` - 构建上下文
  /// `tagName` - 标签名
  /// `onTap` - 点击回调
  /// `style` - 显示样式
  /// 
  /// Returns: Widget - 标签芯片组件
  static Widget createTagChip(
    BuildContext context,
    String tagName, {
    VoidCallback? onTap,
    TagChipStyle style = TagChipStyle.normal,
  }) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    EdgeInsets padding;
    double fontSize;
    
    switch (style) {
      case TagChipStyle.small:
        backgroundColor = theme.colorScheme.secondaryContainer.withValues(alpha: 0.6);
        textColor = theme.colorScheme.onSecondaryContainer;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        fontSize = 11;
        break;
      case TagChipStyle.large:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        fontSize = 14;
        break;
      case TagChipStyle.normal:
        backgroundColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.8);
        textColor = theme.colorScheme.onPrimaryContainer;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
        fontSize = 12;
        break;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: fontSize,
              color: textColor.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 2),
            Text(
              tagName,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 为文本内容构建标签列表
  /// 
  /// `context` - 构建上下文
  /// `content` - 文本内容
  /// `onTagTap` - 标签点击回调
  /// `style` - 显示样式
  /// `maxTags` - 最大显示标签数量
  /// 
  /// Returns: List`<Widget>` - 标签组件列表
  static List<Widget> buildTagWidgets(
    BuildContext context,
    String content, {
    Function(String)? onTagTap,
    TagChipStyle style = TagChipStyle.small,
    int? maxTags,
  }) {
    final tags = extractTags(content);
    if (tags.isEmpty) return [];
    
    final displayTags = maxTags != null && tags.length > maxTags
        ? tags.take(maxTags).toList()
        : tags;
    
    final widgets = displayTags.map((tag) => createTagChip(
      context,
      tag,
      onTap: onTagTap != null ? () => onTagTap(tag) : null,
      style: style,
    )).toList();
    
    // 如果有更多标签，添加省略指示器
    if (maxTags != null && tags.length > maxTags) {
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '+${tags.length - maxTags}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    return widgets;
  }

  /// 计算标签使用统计
  /// 
  /// `fragments` - Fragment列表
  /// 
  /// Returns: Map`<String, int>` - 标签名到使用次数的映射
  static Map<String, int> calculateTagStats(List<MoodFragment> fragments) {
    final stats = <String, int>{};
    
    for (final fragment in fragments) {
      if (fragment.textContent != null) {
        final tags = extractTags(fragment.textContent!);
        for (final tag in tags) {
          stats[tag] = (stats[tag] ?? 0) + 1;
        }
      }
    }
    
    return stats;
  }

  /// 获取热门标签列表
  /// 
  /// `fragments` - Fragment列表
  /// `limit` - 返回数量限制
  /// 
  /// Returns: List`<MapEntry<String, int>>` - 按使用频率排序的标签列表
  static List<MapEntry<String, int>> getPopularTags(
    List<MoodFragment> fragments, {
    int limit = 10,
  }) {
    final stats = calculateTagStats(fragments);
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).toList();
  }

  /// 清除缓存
  /// 
  /// 在数据变更时调用，确保缓存一致性
  static void clearCache() {
    _extractCache.clear();
    _displayCache.clear();
  }

  /// 获取缓存统计信息
  /// 
  /// Returns: Map`<String, int>` - 缓存统计信息
  static Map<String, int> getCacheStats() {
    return {
      'extractCache': _extractCache.length,
      'displayCache': _displayCache.length,
    };
  }

  /// 预热缓存
  /// 
  /// `contents` - 要预处理的文本列表
  /// 
  /// 在应用启动或数据加载时调用，提前构建缓存
  static void preloadCache(List<String> contents) {
    for (final content in contents) {
      if (content.isNotEmpty) {
        extractTags(content, useCache: true);
        getDisplayContent(content, useCache: true);
      }
    }
  }
}

/// 标签芯片显示样式枚举
enum TagChipStyle {
  small,   // 小号样式，用于列表项
  normal,  // 普通样式，用于一般显示
  large,   // 大号样式，用于重点展示
}

/// 标签相关的扩展方法
extension TagExtensions on String {
  /// 检查字符串是否包含标签
  bool get hasTags => TagUtils.extractTags(this).isNotEmpty;
  
  /// 获取字符串中的所有标签
  List<String> get tags => TagUtils.extractTags(this);
  
  /// 获取去除标签的显示内容
  String get displayContent => TagUtils.getDisplayContent(this);
}