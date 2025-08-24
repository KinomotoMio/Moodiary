import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/tag_utils.dart';
import 'fragment_storage_service.dart';

/// 智能标签提取服务
/// 
/// 分析文本内容，识别潜在的标签关键词并提供智能标签化建议
class SmartTagExtractorService {
  static final SmartTagExtractorService _instance = SmartTagExtractorService._internal();
  factory SmartTagExtractorService() => _instance;
  SmartTagExtractorService._internal();

  static SmartTagExtractorService get instance => _instance;

  // 停用词列表
  static const Set<String> _stopWords = {
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一',
    '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没', '看',
    '好', '自己', '这', '那', '他', '她', '它', '们', '什么', '怎么', '为什么',
    '因为', '所以', '但是', '然后', '还是', '或者', '如果', '虽然', '可能',
    '应该', '必须', '今天', '昨天', '明天', '现在', '以前', '以后', '时候',
    '地方', '东西', '事情', '问题', '方法', '时间', '开始', '结束', '感觉'
  };

  // 情绪相关词汇（可以作为优质标签候选）
  static const Set<String> _emotionWords = {
    '开心', '高兴', '快乐', '兴奋', '激动', '满意', '幸福', '愉悦', '喜悦',
    '难过', '伤心', '沮丧', '失落', '郁闷', '烦躁', '焦虑', '紧张', '担心',
    '愤怒', '生气', '恼火', '烦恼', '无奈', '疲惫', '累', '困', '放松',
    '平静', '淡定', '冷静', '安静', '舒服', '温暖', '感动', '惊喜', '意外',
    '压力', '困难', '挑战', '机会', '希望', '梦想', '目标', '成功', '失败'
  };

  // 常见场所和活动词汇
  static const Set<String> _contextWords = {
    '工作', '上班', '下班', '公司', '办公室', '会议', '项目', '任务', '客户',
    '学习', '上课', '考试', '作业', '复习', '书', '图书馆', '学校', '老师',
    '家', '房间', '客厅', '厨房', '卧室', '家人', '父母', '孩子', '宠物',
    '朋友', '同事', '同学', '聚会', '聊天', '电话', '微信', '约会', '见面',
    '运动', '跑步', '健身', '游泳', '篮球', '足球', '瑜伽', '散步', '爬山',
    '吃饭', '做饭', '外卖', '餐厅', '咖啡', '奶茶', '电影', '音乐', '游戏',
    '旅行', '出差', '度假', '景点', '酒店', '飞机', '火车', '地铁', '公交',
    '购物', '买', '卖', '钱', '价格', '便宜', '贵', '优惠', '促销', '商场',
    '医院', '医生', '看病', '吃药', '健康', '身体', '头疼', '感冒', '发烧',
    '天气', '下雨', '晴天', '阴天', '热', '冷', '温度', '空气', '风', '雪'
  };

  /// 分析文本并提取智能标签建议
  /// 
  /// 返回一个包含建议关键词和其在文本中位置的列表
  Future<SmartTagSuggestion> extractSmartTags(String text) async {
    if (text.trim().isEmpty) {
      return SmartTagSuggestion(suggestions: [], originalText: text);
    }

    // 1. 获取用户历史标签用于匹配
    final historicalTags = await _getHistoricalTags();
    
    // 2. 提取当前已有的标签
    final existingTags = TagUtils.extractTags(text).toSet();
    
    // 3. 分析文本，识别潜在关键词
    final candidates = _extractKeywordCandidates(text);
    
    // 4. 过滤和评分
    final suggestions = _filterAndScoreCandidates(
      candidates, 
      existingTags, 
      historicalTags,
    );
    
    // 5. 按评分排序，返回前10个建议
    suggestions.sort((a, b) => b.score.compareTo(a.score));
    final topSuggestions = suggestions.take(10).toList();
    
    debugPrint('Smart tag extraction: found ${topSuggestions.length} suggestions for "${text.substring(0, min(50, text.length))}..."');
    
    return SmartTagSuggestion(
      suggestions: topSuggestions,
      originalText: text,
    );
  }

  /// 获取用户历史使用的标签
  Future<Set<String>> _getHistoricalTags() async {
    try {
      final fragments = await FragmentStorageService.instance.getAllFragments();
      final historicalTags = <String>{};
      
      for (final fragment in fragments) {
        if (fragment.hasTopicTags) {
          historicalTags.addAll(fragment.topicTags);
        }
      }
      
      return historicalTags;
    } catch (e) {
      debugPrint('Error getting historical tags: $e');
      return <String>{};
    }
  }

  /// 提取关键词候选
  List<KeywordCandidate> _extractKeywordCandidates(String text) {
    final candidates = <String, KeywordCandidate>{};
    
    // 使用正则表达式提取中文词汇（2-6个字符）
    final chineseWordRegex = RegExp(r'[\u4e00-\u9fff]{2,6}');
    final matches = chineseWordRegex.allMatches(text);
    
    for (final match in matches) {
      final word = match.group(0)!;
      final startIndex = match.start;
      
      // 跳过停用词
      if (_stopWords.contains(word)) continue;
      
      if (candidates.containsKey(word)) {
        candidates[word]!.positions.add(startIndex);
        candidates[word]!.frequency++;
      } else {
        candidates[word] = KeywordCandidate(
          word: word,
          positions: [startIndex],
          frequency: 1,
        );
      }
    }
    
    // 也提取一些英文单词（可能是品牌、地名等）
    final englishWordRegex = RegExp(r'[A-Za-z]{2,15}');
    final englishMatches = englishWordRegex.allMatches(text);
    
    for (final match in englishMatches) {
      final word = match.group(0)!.toLowerCase();
      final startIndex = match.start;
      
      // 跳过常见英文停用词
      if (['the', 'and', 'you', 'are', 'for', 'not', 'with', 'this', 'that'].contains(word)) continue;
      
      if (candidates.containsKey(word)) {
        candidates[word]!.positions.add(startIndex);
        candidates[word]!.frequency++;
      } else {
        candidates[word] = KeywordCandidate(
          word: word,
          positions: [startIndex],
          frequency: 1,
        );
      }
    }
    
    return candidates.values.toList();
  }

  /// 过滤和评分候选关键词
  List<TagSuggestionItem> _filterAndScoreCandidates(
    List<KeywordCandidate> candidates,
    Set<String> existingTags,
    Set<String> historicalTags,
  ) {
    final suggestions = <TagSuggestionItem>[];
    
    for (final candidate in candidates) {
      final word = candidate.word;
      
      // 跳过已经存在的标签
      if (existingTags.contains(word)) continue;
      
      // 计算评分
      double score = 0.0;
      String reason = '';
      
      // 1. 基础频率分数（频率越高分数越高）
      score += candidate.frequency * 0.3;
      
      // 2. 历史标签匹配（如果用户之前用过这个标签，大幅加分）
      if (historicalTags.contains(word)) {
        score += 2.0;
        reason = '常用标签';
      }
      // 3. 情绪词汇加分
      else if (_emotionWords.contains(word)) {
        score += 1.5;
        reason = '情绪相关';
      }
      // 4. 场景词汇加分
      else if (_contextWords.contains(word)) {
        score += 1.0;
        reason = '场景活动';
      }
      // 5. 词长度影响（2-4字比较适合做标签）
      else if (word.length >= 2 && word.length <= 4) {
        score += 0.5;
        reason = '关键词';
      }
      
      // 6. 词汇长度惩罚（过长或过短的词降分）
      if (word.length < 2) {
        score -= 0.5;
      } else if (word.length > 6) {
        score -= 0.3;
      }
      
      // 只保留评分大于0的候选
      if (score > 0) {
        suggestions.add(TagSuggestionItem(
          keyword: word,
          score: score,
          positions: candidate.positions,
          reason: reason.isEmpty ? '关键词' : reason,
        ));
      }
    }
    
    return suggestions;
  }

  /// 将选中的关键词转换为标签并插入原文
  String convertKeywordsToTags(String originalText, List<String> selectedKeywords) {
    String modifiedText = originalText;
    
    // 从后往前替换，避免位置偏移问题
    final sortedKeywords = <String>[];
    final keywordPositions = <String, List<int>>{};
    
    // 找到每个关键词在文本中的所有位置
    for (final keyword in selectedKeywords) {
      final positions = <int>[];
      int startIndex = 0;
      
      while (true) {
        final index = originalText.indexOf(keyword, startIndex);
        if (index == -1) break;
        positions.add(index);
        startIndex = index + 1;
      }
      
      if (positions.isNotEmpty) {
        keywordPositions[keyword] = positions;
        sortedKeywords.add(keyword);
      }
    }
    
    // 收集所有替换操作，按位置从后往前排序
    final replacements = <_Replacement>[];
    
    for (final keyword in sortedKeywords) {
      final positions = keywordPositions[keyword]!;
      for (final position in positions) {
        // 检查这个位置的词是否已经是标签了
        final wordStart = position;
        final wordEnd = position + keyword.length;
        
        // 向前查看是否已经有#
        bool alreadyTagged = false;
        if (wordStart > 0 && originalText[wordStart - 1] == '#') {
          alreadyTagged = true;
        }
        
        if (!alreadyTagged) {
          replacements.add(_Replacement(
            start: wordStart,
            end: wordEnd,
            original: keyword,
            replacement: '#$keyword',
          ));
        }
      }
    }
    
    // 按位置从后往前排序
    replacements.sort((a, b) => b.start.compareTo(a.start));
    
    // 执行替换
    for (final replacement in replacements) {
      modifiedText = modifiedText.replaceRange(
        replacement.start, 
        replacement.end, 
        replacement.replacement,
      );
    }
    
    return modifiedText;
  }
}

/// 智能标签建议结果
class SmartTagSuggestion {
  final List<TagSuggestionItem> suggestions;
  final String originalText;

  SmartTagSuggestion({
    required this.suggestions,
    required this.originalText,
  });

  bool get hasSuggestions => suggestions.isNotEmpty;
  int get suggestionCount => suggestions.length;
}

/// 标签建议项
class TagSuggestionItem {
  final String keyword;
  final double score;
  final List<int> positions;
  final String reason;

  TagSuggestionItem({
    required this.keyword,
    required this.score,
    required this.positions,
    required this.reason,
  });

  @override
  String toString() => '$keyword (分数: ${score.toStringAsFixed(1)}, 原因: $reason)';
}

/// 关键词候选
class KeywordCandidate {
  final String word;
  final List<int> positions;
  int frequency;

  KeywordCandidate({
    required this.word,
    required this.positions,
    required this.frequency,
  });
}

/// 文本替换操作
class _Replacement {
  final int start;
  final int end;
  final String original;
  final String replacement;

  _Replacement({
    required this.start,
    required this.end,
    required this.original,
    required this.replacement,
  });
}