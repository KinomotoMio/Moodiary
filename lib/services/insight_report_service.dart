import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/insight_report.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../events/app_events.dart';
import 'storage_service.dart';
import 'fragment_storage_service.dart';
import 'llm/llm_client.dart';
import 'llm/providers/base_llm_provider.dart'; // 导入LLMException
import 'llm/prompt_templates/insight_report_prompt.dart';
import 'settings_service.dart';

/// 心理洞察报告服务
///
/// 功能：
/// 1. 生成周报/月报（基于CBT框架的AI分析）
/// 2. 本地缓存管理
/// 3. 历史报告查看
class InsightReportService {
  static InsightReportService? _instance;
  static InsightReportService get instance => _instance ??= InsightReportService._();

  InsightReportService._();

  // 依赖服务
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final LLMClient _llmClient = LLMClient.instance;
  final SettingsService _settingsService = SettingsService.instance;

  // 本地存储key
  static const String _storageKey = 'insight_reports';

  // 内存缓存
  final Map<String, InsightReport> _cache = {};

  /// 初始化服务
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        debugPrint('InsightReportService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing InsightReportService: $e');
      }
    }
  }

  /// 生成当前周报
  Future<InsightReport> generateCurrentWeeklyReport({bool forceRegenerate = false}) async {
    final now = DateTime.now();
    final startOfWeek = _getStartOfWeek(now);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return generateReport(
      type: ReportType.weekly,
      startDate: startOfWeek,
      endDate: endOfWeek,
      forceRegenerate: forceRegenerate,
    );
  }

  /// 生成当前月报
  Future<InsightReport> generateCurrentMonthlyReport({bool forceRegenerate = false}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return generateReport(
      type: ReportType.monthly,
      startDate: startOfMonth,
      endDate: endOfMonth,
      forceRegenerate: forceRegenerate,
    );
  }

  /// 生成指定周期的洞察报告
  Future<InsightReport> generateReport({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    bool forceRegenerate = false,
  }) async {
    // 生成报告ID
    final reportId = _generateReportId(type, startDate);

    // 检查缓存
    if (!forceRegenerate) {
      final cached = await _getFromCache(reportId);
      if (cached != null) {
        if (kDebugMode) {
          debugPrint('Using cached report: $reportId');
        }
        return cached;
      }
    }

    // 获取周期内的所有Fragment
    final fragments = await _getFragmentsInRange(startDate, endDate);

    // 计算统计数据
    final stats = _calculateStats(fragments);

    // 如果记录数量不足，使用默认内容
    if (fragments.length < 3) {
      if (kDebugMode) {
        debugPrint('Insufficient data for report (${fragments.length} entries)');
      }

      final defaultContent = InsightReportPrompt.getDefaultContent(type);
      final report = InsightReport.create(
        type: type,
        startDate: startDate,
        endDate: endDate,
        stats: stats,
        coreInsight: defaultContent['core_insight']!,
        emotionPattern: defaultContent['emotion_pattern']!,
        behaviorSuggestion: defaultContent['behavior_suggestion']!,
      );

      await _saveToCache(report);
      return report;
    }

    // 调用LLM生成内容
    try {
      final content = await _generateContentWithLLM(fragments, stats, type);

      final report = InsightReport.create(
        type: type,
        startDate: startDate,
        endDate: endDate,
        stats: stats,
        coreInsight: content['core_insight']!,
        emotionPattern: content['emotion_pattern']!,
        behaviorSuggestion: content['behavior_suggestion']!,
      );

      await _saveToCache(report);

      // 触发事件通知
      StorageService.eventBus.fire(MoodDataChangedEvent());

      if (kDebugMode) {
        debugPrint('Generated new report: $reportId');
      }

      return report;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating report with LLM: $e');
      }

      // LLM调用失败，使用默认内容
      final defaultContent = InsightReportPrompt.getDefaultContent(type);
      final report = InsightReport.create(
        type: type,
        startDate: startDate,
        endDate: endDate,
        stats: stats,
        coreInsight: defaultContent['core_insight']!,
        emotionPattern: '这${type == ReportType.weekly ? '周' : '个月'}记录了${fragments.length}条心情。因为技术原因，暂时无法生成个性化的洞察，但你的记录都安全地保存着。',
        behaviorSuggestion: defaultContent['behavior_suggestion']!,
      );

      await _saveToCache(report);

      if (kDebugMode) {
        debugPrint('Saved fallback report for $reportId (LLM failed)');
      }

      return report;
    }
  }

  /// 获取指定日期范围内的所有Fragment
  Future<List<MoodFragment>> _getFragmentsInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allFragments = await _fragmentStorage.getAllFragments();

    return allFragments.where((fragment) {
      final timestamp = fragment.timestamp;
      return timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 计算统计数据
  ReportStats _calculateStats(List<MoodFragment> fragments) {
    if (fragments.isEmpty) {
      return const ReportStats(
        totalEntries: 0,
        averageScore: 0,
        dominantMood: null,
        moodDistribution: {},
        highestScore: 0,
        lowestScore: 0,
        emotionVolatility: 0,
        topTags: [],
      );
    }

    // 计算平均分
    final totalScore = fragments.fold<int>(
      0,
      (sum, fragment) => sum + fragment.emotionScore,
    );
    final averageScore = totalScore / fragments.length;

    // 统计情绪分布
    final moodCounts = <MoodType, int>{};
    for (final fragment in fragments) {
      moodCounts[fragment.mood] = (moodCounts[fragment.mood] ?? 0) + 1;
    }

    // 主导情绪
    MoodType? dominantMood;
    if (moodCounts.isNotEmpty) {
      final dominantEntry = moodCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      dominantMood = dominantEntry.key;
    }

    // 最高分和最低分
    final scores = fragments.map((f) => f.emotionScore).toList();
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);

    // 计算情绪波动度（标准差）
    final variance = scores.fold<double>(
      0,
      (sum, score) => sum + pow(score - averageScore, 2),
    ) / scores.length;
    final emotionVolatility = sqrt(variance);

    // 统计高频标签
    final tagCounts = <String, int>{};
    for (final fragment in fragments) {
      for (final tag in fragment.topicTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 按使用频率排序，取前5
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = sortedTags.take(5).map((e) => e.key).toList();

    return ReportStats(
      totalEntries: fragments.length,
      averageScore: averageScore,
      dominantMood: dominantMood,
      moodDistribution: moodCounts,
      highestScore: highestScore,
      lowestScore: lowestScore,
      emotionVolatility: emotionVolatility,
      topTags: topTags,
    );
  }

  /// 使用LLM生成内容（带重试机制）
  Future<Map<String, String>> _generateContentWithLLM(
    List<MoodFragment> fragments,
    ReportStats stats,
    ReportType type,
  ) async {
    const maxRetries = 3; // 最多重试3次
    const initialBackoffMs = 1000; // 初始退避时间1秒

    LLMException? lastException;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // 计算指数退避时间：1秒、2秒、4秒
          final backoffMs = initialBackoffMs * (1 << (attempt - 1));
          if (kDebugMode) {
            debugPrint('Retrying LLM call (attempt ${attempt + 1}/$maxRetries) after ${backoffMs}ms...');
          }
          await Future.delayed(Duration(milliseconds: backoffMs));
        }

        // 生成prompt
        final prompt = InsightReportPrompt.generateInsightPrompt(
          fragments: fragments,
          stats: stats,
          reportType: type,
        );

        // 获取LLM提供商和API密钥
        final settings = _settingsService.currentSettings;
        final providerName = settings.llmProvider ?? 'siliconflow';
        final apiKey = settings.llmApiKey;

        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('LLM API key not configured');
        }

        // 调用LLM
        if (kDebugMode) {
          debugPrint('Calling LLM with provider: $providerName (attempt ${attempt + 1}/$maxRetries)');
          debugPrint('Prompt length: ${prompt.length} characters');
        }

        final response = await _llmClient.generateText(
          providerName: providerName,
          prompt: prompt,
          apiKey: apiKey,
          parameters: {
            'temperature': 0.7,
            'max_tokens': 3000, // 增加token限制以支持详细内容生成（约1500-2000字）
          },
        );

        if (kDebugMode) {
          debugPrint('LLM response length: ${response.length} characters');
          debugPrint('LLM response preview: ${response.substring(0, min(200, response.length))}...');
        }

        // 解析响应
        final content = InsightReportPrompt.parseResponse(response);
        if (content == null) {
          if (kDebugMode) {
            debugPrint('Failed to parse LLM response. Raw response:');
            debugPrint(response.substring(0, min(500, response.length)));
          }
          throw Exception('Failed to parse LLM response - invalid JSON format');
        }

        if (kDebugMode) {
          debugPrint('Parsed content lengths:');
          debugPrint('  core_insight: ${content['core_insight']?.length ?? 0}');
          debugPrint('  emotion_pattern: ${content['emotion_pattern']?.length ?? 0}');
          debugPrint('  behavior_suggestion: ${content['behavior_suggestion']?.length ?? 0}');
        }

        // 验证内容质量
        if (!InsightReportPrompt.validateContent(content)) {
          if (kDebugMode) {
            debugPrint('Content quality validation failed:');
            debugPrint('  core_insight length: ${content['core_insight']?.length ?? 0} (expected: 150-700)');
            debugPrint('  emotion_pattern length: ${content['emotion_pattern']?.length ?? 0} (expected: 300-1500)');
            debugPrint('  behavior_suggestion length: ${content['behavior_suggestion']?.length ?? 0} (expected: 200-1200)');
          }
          throw Exception('Generated content quality check failed - length out of range');
        }

        if (kDebugMode) {
          debugPrint('✓ Report content validation passed (attempt ${attempt + 1})');
        }

        return content;
      } on LLMException catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('LLM call failed (attempt ${attempt + 1}/$maxRetries): $e');
        }

        // 如果是超时或网络错误，可以重试
        if (e.message.contains('超时') || e.message.contains('网络') || e.message.contains('timeout')) {
          if (attempt < maxRetries - 1) {
            continue; // 继续重试
          }
        } else {
          // 其他错误（如API密钥错误、参数错误）不重试
          rethrow;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Unexpected error during LLM call (attempt ${attempt + 1}/$maxRetries): $e');
        }
        // 非LLM异常也尝试重试
        if (attempt < maxRetries - 1) {
          continue;
        }
        rethrow;
      }
    }

    // 所有重试都失败了
    if (lastException != null) {
      throw lastException;
    } else {
      throw Exception('Failed to generate report after $maxRetries attempts');
    }
  }

  /// 获取历史报告列表
  Future<List<InsightReport>> getHistoryReports({
    ReportType? filterType,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final reports = <InsightReport>[];

      for (final entry in data.entries) {
        try {
          final report = InsightReport.fromJson(entry.value as Map<String, dynamic>);

          // 应用过滤条件
          if (filterType != null && report.type != filterType) {
            continue;
          }

          reports.add(report);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error parsing report ${entry.key}: $e');
          }
        }
      }

      // 按生成时间倒序排序
      reports.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      // 限制数量
      return reports.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading history reports: $e');
      }
      return [];
    }
  }

  /// 标记报告为已读
  Future<void> markAsRead(String reportId) async {
    final report = await _getFromCache(reportId);
    if (report == null) return;

    final updated = report.copyWith(isRead: true);
    await _saveToCache(updated);
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String reportId) async {
    final report = await _getFromCache(reportId);
    if (report == null) return;

    final updated = report.copyWith(isFavorite: !report.isFavorite);
    await _saveToCache(updated);
  }

  /// 从缓存获取报告
  Future<InsightReport?> _getFromCache(String id) async {
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
        final report = InsightReport.fromJson(data[id] as Map<String, dynamic>);

        // 加载到内存缓存
        _cache[id] = report;

        return report;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading report from cache: $e');
      }
    }

    return null;
  }

  /// 保存报告到缓存
  Future<void> _saveToCache(InsightReport report) async {
    // 更新内存缓存
    _cache[report.id] = report;

    // 持久化存储
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    Map<String, dynamic> data = {};
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        data = jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing existing reports: $e');
        }
      }
    }

    // 添加/更新报告
    data[report.id] = report.toJson();

    // 清理过期的报告（保留最近90天，或收藏的）
    _cleanupOldReports(data);

    // 保存
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  /// 清理旧报告
  void _cleanupOldReports(Map<String, dynamic> data) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 90));

    final keysToRemove = <String>[];

    for (final entry in data.entries) {
      try {
        final report = InsightReport.fromJson(entry.value as Map<String, dynamic>);
        if (report.endDate.isBefore(cutoffDate) && !report.isFavorite) {
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
      debugPrint('Cleaned up ${keysToRemove.length} old reports');
    }
  }

  /// 清除所有缓存
  Future<void> clearCache() async {
    _cache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);

    if (kDebugMode) {
      debugPrint('All reports cache cleared');
    }
  }

  /// 获取周的起始日期（周一）
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day).subtract(
      Duration(days: weekday - 1),
    );
  }

  /// 生成报告ID
  String _generateReportId(ReportType type, DateTime startDate) {
    if (type == ReportType.weekly) {
      // 计算周数
      final weekNumber = _getWeekNumber(startDate);
      return 'weekly_${startDate.year}_W${weekNumber.toString().padLeft(2, '0')}';
    } else {
      return 'monthly_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}';
    }
  }

  /// 计算周数（简化版）
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }
}
