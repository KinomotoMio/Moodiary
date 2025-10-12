import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_summary.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../events/app_events.dart';
import 'storage_service.dart';
import 'fragment_storage_service.dart';
import 'llm/llm_client.dart';
import 'llm/prompt_templates/bedtime_summary_prompt.dart';
import 'settings_service.dart';

/// 每日睡前阅读摘要服务
///
/// 功能：
/// 1. 生成每日睡前阅读内容（事件回顾 + 情绪流向 + 冥想引导）
/// 2. 本地缓存管理（避免重复生成）
/// 3. 历史睡前内容查看
class DailySummaryService {
  static DailySummaryService? _instance;
  static DailySummaryService get instance =>
      _instance ??= DailySummaryService._();

  DailySummaryService._();

  // 依赖服务
  final FragmentStorageService _fragmentStorage =
      FragmentStorageService.instance;
  final LLMClient _llmClient = LLMClient.instance;
  final SettingsService _settingsService = SettingsService.instance;

  // 本地存储key
  static const String _storageKey = 'daily_summaries';
  static const String _favoritesKey = 'favorite_summaries';

  // 内存缓存
  final Map<String, DailySummary> _cache = {};
  final Set<String> _favorites = {};

  /// 初始化服务
  Future<void> initialize() async {
    try {
      await _loadFavorites();
      if (kDebugMode) {
        debugPrint('DailySummaryService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing DailySummaryService: $e');
      }
    }
  }

  /// 生成今日睡前阅读内容
  ///
  /// 如果已有缓存且未过期，直接返回缓存
  /// [forceRegenerate] 强制重新生成（忽略缓存）
  Future<DailySummary> generateTodaySummary({
    bool forceRegenerate = false,
  }) async {
    final today = DateTime.now();
    return generateSummaryForDate(today, forceRegenerate: forceRegenerate);
  }

  /// 生成指定日期的睡前阅读内容
  ///
  /// [date] 指定日期
  /// [forceRegenerate] 强制重新生成（忽略缓存）
  Future<DailySummary> generateSummaryForDate(
    DateTime date, {
    bool forceRegenerate = false,
  }) async {
    final dateId = DailySummary.getIdFromDate(date);

    // 检查缓存
    if (!forceRegenerate) {
      final cached = await _getFromCache(dateId);
      if (cached != null && cached.isValid) {
        if (kDebugMode) {
          debugPrint('Using cached summary for $dateId');
        }
        return cached;
      }
    }

    // 获取当天的所有Fragment
    final fragments = await _getFragmentsForDate(date);

    // 计算统计数据
    final stats = _calculateStats(fragments);

    // 如果没有记录，使用默认内容
    if (fragments.isEmpty) {
      final defaultContent = BedtimeSummaryPrompt.getDefaultContent();
      final summary = DailySummary.create(
        date: date,
        fragmentCount: 0,
        eventSummary: defaultContent['event_summary']!,
        emotionReview: defaultContent['emotion_review']!,
        meditationGuide: defaultContent['meditation_guide']!,
      );

      await _saveToCache(summary);
      return summary;
    }

    // 调用LLM生成内容
    try {
      final content = await _generateContentWithLLM(
        fragments,
        stats['dominantMood'] as String?,
        stats['averageScore'] as double?,
      );

      final summary = DailySummary.create(
        date: date,
        fragmentCount: fragments.length,
        eventSummary: content['event_summary']!,
        emotionReview: content['emotion_review']!,
        meditationGuide: content['meditation_guide']!,
        dominantMood: stats['dominantMoodType'] as MoodType?,
        averageScore: stats['averageScore'] as double?,
      );

      await _saveToCache(summary);

      // 触发事件通知
      StorageService.eventBus.fire(MoodDataChangedEvent());

      if (kDebugMode) {
        debugPrint('Generated new summary for $dateId');
      }

      return summary;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating summary with LLM: $e');
      }

      // LLM调用失败，使用默认内容
      final defaultContent = BedtimeSummaryPrompt.getDefaultContent();
      final summary = DailySummary.create(
        date: date,
        fragmentCount: fragments.length,
        eventSummary: defaultContent['event_summary']!,
        emotionReview:
            '今天记录了${fragments.length}条心情。因为技术原因，暂时无法生成个性化的回顾，但你的记录都安全地保存着。明天可以再试试看。',
        meditationGuide: defaultContent['meditation_guide']!,
        dominantMood: stats['dominantMoodType'] as MoodType?,
        averageScore: stats['averageScore'] as double?,
      );

      // 即使生成失败，也保存到缓存，避免重复生成
      // 用户可以通过"重新生成"按钮手动刷新
      await _saveToCache(summary);

      if (kDebugMode) {
        debugPrint('Saved fallback summary for $dateId (LLM failed)');
      }

      return summary;
    }
  }

  /// 获取指定日期的所有Fragment
  Future<List<MoodFragment>> _getFragmentsForDate(DateTime date) async {
    final allFragments = await _fragmentStorage.getAllFragments();

    // 筛选当天的记录
    return allFragments.where((fragment) {
      final fragmentDate = fragment.timestamp;
      return fragmentDate.year == date.year &&
          fragmentDate.month == date.month &&
          fragmentDate.day == date.day;
    }).toList();
  }

  /// 计算统计数据
  Map<String, dynamic> _calculateStats(List<MoodFragment> fragments) {
    if (fragments.isEmpty) {
      return {
        'dominantMood': null,
        'dominantMoodType': null,
        'averageScore': null,
      };
    }

    // 计算平均情绪评分
    final totalScore = fragments.fold<int>(
      0,
      (sum, fragment) => sum + fragment.emotionScore,
    );
    final averageScore = totalScore / fragments.length;

    // 统计主导情绪
    final moodCounts = <MoodType, int>{};
    for (final fragment in fragments) {
      moodCounts[fragment.mood] = (moodCounts[fragment.mood] ?? 0) + 1;
    }

    final dominantMoodEntry = moodCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final dominantMoodType = dominantMoodEntry.key;
    final dominantMood = dominantMoodType.displayName;

    return {
      'dominantMood': dominantMood,
      'dominantMoodType': dominantMoodType,
      'averageScore': averageScore,
    };
  }

  /// 使用LLM生成内容
  Future<Map<String, String>> _generateContentWithLLM(
    List<MoodFragment> fragments,
    String? dominantMood,
    double? averageScore,
  ) async {
    // 生成prompt
    final prompt = BedtimeSummaryPrompt.generateSummaryPrompt(
      fragments: fragments,
      dominantMood: dominantMood,
      averageScore: averageScore,
    );

    // 获取LLM提供商和API密钥
    final settings = _settingsService.currentSettings;
    final providerName = settings.llmProvider ?? 'siliconflow';
    final apiKey = settings.llmApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('LLM API key not configured');
    }

    // 调用LLM
    final response = await _llmClient.generateText(
      providerName: providerName,
      prompt: prompt,
      apiKey: apiKey,
      parameters: {
        'temperature': 0.7, // 稍微提高创造性
        'max_tokens': 800, // 足够的token数量
      },
    );

    // 解析响应
    final content = BedtimeSummaryPrompt.parseResponse(response);
    if (content == null) {
      throw Exception('Failed to parse LLM response');
    }

    // 验证内容质量
    if (!BedtimeSummaryPrompt.validateContent(content)) {
      throw Exception('Generated content quality check failed');
    }

    return content;
  }

  /// 获取历史睡前阅读列表
  ///
  /// [limit] 返回的最大数量
  /// [onlyFavorites] 只返回收藏的内容
  Future<List<DailySummary>> getHistorySummaries({
    int limit = 30,
    bool onlyFavorites = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final summaries = <DailySummary>[];

      for (final entry in data.entries) {
        try {
          final summary = DailySummary.fromJson(
            entry.value as Map<String, dynamic>,
          );

          // 应用过滤条件
          if (onlyFavorites && !summary.isFavorite) {
            continue;
          }

          summaries.add(summary);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing summary ${entry.key}: $e');
          }
        }
      }

      // 按日期倒序排序
      summaries.sort((a, b) => b.date.compareTo(a.date));

      // 限制数量
      return summaries.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading history summaries: $e');
      }
      return [];
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String summaryId) async {
    // 从缓存获取
    final summary = await _getFromCache(summaryId);
    if (summary == null) return;

    // 更新收藏状态
    final updated = summary.copyWith(isFavorite: !summary.isFavorite);

    // 保存
    await _saveToCache(updated);

    // 更新收藏集合
    if (updated.isFavorite) {
      _favorites.add(summaryId);
    } else {
      _favorites.remove(summaryId);
    }

    await _saveFavorites();
  }

  /// 从缓存获取摘要
  Future<DailySummary?> _getFromCache(String id) async {
    // 先检查内存缓存
    if (_cache.containsKey(id)) {
      return _cache[id];
    }

    // 从持久化存储加载
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      if (data.containsKey(id)) {
        final summary = DailySummary.fromJson(data[id] as Map<String, dynamic>);

        // 加载到内存缓存
        _cache[id] = summary;

        return summary;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading summary from cache: $e');
      }
    }

    return null;
  }

  /// 保存摘要到缓存
  Future<void> _saveToCache(DailySummary summary) async {
    // 更新内存缓存
    _cache[summary.id] = summary;

    // 持久化存储
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    Map<String, dynamic> data = {};
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        data = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing existing summaries: $e');
        }
      }
    }

    // 添加/更新摘要
    data[summary.id] = summary.toJson();

    // 清理过期的摘要（保留最近60天）
    _cleanupOldSummaries(data);

    // 保存
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// 清理旧摘要
  void _cleanupOldSummaries(Map<String, dynamic> data) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 60));

    final keysToRemove = <String>[];

    for (final entry in data.entries) {
      try {
        final summary = DailySummary.fromJson(
          entry.value as Map<String, dynamic>,
        );
        if (summary.date.isBefore(cutoffDate) && !summary.isFavorite) {
          keysToRemove.add(entry.key);
        }
      } catch (e) {
        // 解析失败的也删除
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      data.remove(key);
      _cache.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${keysToRemove.length} old summaries');
    }
  }

  /// 加载收藏列表
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson != null && favoritesJson.isNotEmpty) {
      try {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        _favorites.addAll(favoritesList.cast<String>());
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error loading favorites: $e');
        }
      }
    }
  }

  /// 保存收藏列表
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoritesKey, jsonEncode(_favorites.toList()));
  }

  /// 清除所有睡前摘要及收藏
  Future<void> clearAllSummaries() async {
    _cache.clear();
    _favorites.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_favoritesKey);

    StorageService.eventBus.fire(DataClearedEvent());
    StorageService.eventBus.fire(MoodDataChangedEvent());

    if (kDebugMode) {
      debugPrint('Daily summaries cleared');
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (kDebugMode) {
      debugPrint('All summaries cache cleared');
    }
  }

  /// 获取缓存统计信息
  Future<Map<String, dynamic>> getCacheStats() async {
    final summaries = await getHistorySummaries(limit: 1000);

    return {
      'totalSummaries': summaries.length,
      'favoritesCount': summaries.where((s) => s.isFavorite).length,
      'oldestDate': summaries.isNotEmpty ? summaries.last.date : null,
      'newestDate': summaries.isNotEmpty ? summaries.first.date : null,
    };
  }
}
