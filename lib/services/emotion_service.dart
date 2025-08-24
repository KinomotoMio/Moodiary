import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../models/analysis_result.dart';
import '../enums/analysis_method.dart';
import 'analysis/analysis_strategy.dart';
import 'analysis/rule_based_strategy.dart';
import 'analysis/llm_analysis_strategy.dart';
import 'analysis/local_ai_strategy.dart';
import 'settings_service.dart';

class EmotionService {
  static EmotionService? _instance;
  static EmotionService get instance => _instance ??= EmotionService._();
  
  EmotionService._();

  final SettingsService _settingsService = SettingsService.instance;
  
  // 策略实例缓存
  final Map<AnalysisMethod, AnalysisStrategy> _strategies = {
    AnalysisMethod.rule: RuleBasedStrategy(),
    AnalysisMethod.llm: LLMAnalysisStrategy(),
    AnalysisMethod.local: LocalAIStrategy(),
  };

  // 分析结果缓存
  final Map<String, CachedAnalysisResult> _cache = {};
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(hours: 24);

  /// 获取当前配置的分析策略
  AnalysisStrategy get _currentStrategy {
    final method = _settingsService.analysisMethod;
    return _strategies[method] ?? _strategies[AnalysisMethod.rule]!;
  }

  /// 统一的情绪分析入口
  /// 
  /// 根据用户设置自动选择合适的分析策略
  /// 支持优雅降级：AI分析失败时自动回退到规则分析
  /// 支持结果缓存：相同内容和策略的分析结果会被缓存
  Future<AnalysisResult> analyzeEmotionUnified(String content) async {
    if (content.trim().isEmpty) {
      return AnalysisResult.neutral();
    }

    final currentMethod = _settingsService.analysisMethod;
    final cacheKey = _generateCacheKey(content, currentMethod);

    // 检查缓存
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        debugPrint('Using cached result for analysis');
      }
      return cached;
    }

    try {
      final strategy = _currentStrategy;
      AnalysisResult result;
      
      // 检查策略是否可用
      if (await strategy.isAvailable) {
        if (kDebugMode) {
          debugPrint('Using ${strategy.strategyName} for emotion analysis');
        }
        result = await strategy.analyze(content);
      } else {
        if (kDebugMode) {
          debugPrint('${strategy.strategyName} not available, falling back to rule-based');
        }
        // 降级到规则分析
        result = await _strategies[AnalysisMethod.rule]!.analyze(content);
      }

      // 缓存结果（只缓存成功的分析结果）
      _addToCache(cacheKey, result);
      return result;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Analysis failed with ${_currentStrategy.strategyName}: $e');
      }
      
      // 如果当前不是规则分析，则降级到规则分析
      if (_settingsService.analysisMethod != AnalysisMethod.rule) {
        try {
          if (kDebugMode) {
            debugPrint('Falling back to rule-based analysis');
          }
          final fallbackResult = await _strategies[AnalysisMethod.rule]!.analyze(content);
          
          // 缓存降级结果
          _addToCache(cacheKey, fallbackResult);
          return fallbackResult;
        } catch (fallbackError) {
          if (kDebugMode) {
            debugPrint('Fallback analysis also failed: $fallbackError');
          }
          return AnalysisResult.neutral();
        }
      } else {
        // 规则分析也失败了，返回中性结果
        return AnalysisResult.neutral();
      }
    }
  }

  /// 生成缓存键
  String _generateCacheKey(String content, AnalysisMethod method) {
    // 使用内容和方法生成唯一键，对长内容进行hash
    final contentKey = content.length > 100 ? 
      content.hashCode.toString() : 
      content.toLowerCase().trim();
    return '${method.name}_$contentKey';
  }

  /// 从缓存获取结果
  AnalysisResult? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached == null) return null;

    // 检查是否过期
    if (DateTime.now().isAfter(cached.expiry)) {
      _cache.remove(key);
      return null;
    }

    return cached.result;
  }

  /// 添加到缓存
  void _addToCache(String key, AnalysisResult result) {
    // 如果缓存已满，移除最旧的条目
    if (_cache.length >= _maxCacheSize) {
      _evictOldestCacheEntry();
    }

    _cache[key] = CachedAnalysisResult(
      result: result,
      expiry: DateTime.now().add(_cacheExpiry),
    );

    if (kDebugMode) {
      debugPrint('Cached analysis result, cache size: ${_cache.length}');
    }
  }

  /// 清除过期的缓存条目
  void _evictOldestCacheEntry() {
    if (_cache.isEmpty) return;

    // 找到最旧的条目
    String? oldestKey;
    DateTime? oldestTime;

    for (final entry in _cache.entries) {
      if (oldestTime == null || entry.value.expiry.isBefore(oldestTime)) {
        oldestTime = entry.value.expiry;
        oldestKey = entry.key;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
    }
  }

  /// 清除所有缓存
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('Analysis cache cleared');
    }
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    
    for (final cached in _cache.values) {
      if (now.isAfter(cached.expiry)) {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'expiredEntries': expiredCount,
      'validEntries': _cache.length - expiredCount,
      'maxSize': _maxCacheSize,
      'cacheHitRate': '需要统计', // 后续可以添加统计功能
    };
  }
  
  /// 向后兼容的分析方法
  /// 
  /// 保留原有接口，仅用于规则分析（同步调用）
  /// 新代码应使用analyzeEmotionUnified方法
  @Deprecated('Use analyzeEmotionUnified for better AI analysis support')
  EmotionAnalysisResult analyzeEmotion(String text) {
    // 直接使用规则分析策略，保持同步调用兼容性
    final ruleStrategy = _strategies[AnalysisMethod.rule] as RuleBasedStrategy;
    final result = ruleStrategy.analyzeSync(text);
    
    return EmotionAnalysisResult(
      moodType: result.moodType,
      score: result.emotionScore,
      confidence: result.confidence ?? 0.5,
    );
  }
  
  /// 批量分析多条文本（新版本，使用统一接口）
  /// 
  /// 支持智能批量处理：
  /// - 优先检查缓存，避免重复分析
  /// - LLM策略支持真正的批量API调用
  /// - 并发处理提升性能
  Future<List<AnalysisResult>> analyzeEmotionsUnified(List<String> texts) async {
    if (texts.isEmpty) return [];

    final results = <AnalysisResult>[];
    final uncachedTexts = <String>[];
    final uncachedIndices = <int>[];
    
    final currentMethod = _settingsService.analysisMethod;

    // 第一步：检查缓存，收集未缓存的文本
    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      if (text.trim().isEmpty) {
        results.add(AnalysisResult.neutral());
        continue;
      }

      final cacheKey = _generateCacheKey(text, currentMethod);
      final cached = _getFromCache(cacheKey);
      
      if (cached != null) {
        results.add(cached);
      } else {
        // 占位，稍后填充
        results.add(AnalysisResult.neutral());
        uncachedTexts.add(text);
        uncachedIndices.add(i);
      }
    }

    if (uncachedTexts.isEmpty) {
      if (kDebugMode) {
        debugPrint('All ${texts.length} texts found in cache');
      }
      return results;
    }

    if (kDebugMode) {
      debugPrint('Processing ${uncachedTexts.length} uncached texts out of ${texts.length}');
    }

    try {
      final strategy = _currentStrategy;
      List<AnalysisResult> uncachedResults;

      // 第二步：批量分析未缓存的文本
      if (strategy is LLMAnalysisStrategy && uncachedTexts.length > 1) {
        // LLM策略支持批量分析
        if (await strategy.isAvailable) {
          try {
            uncachedResults = await strategy.analyzeBatch(uncachedTexts);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('LLM batch analysis failed: $e, falling back to individual');
            }
            // 降级到逐个分析
            uncachedResults = await _processIndividually(uncachedTexts);
          }
        } else {
          // LLM不可用，使用规则分析
          uncachedResults = await _processIndividually(uncachedTexts, forceRule: true);
        }
      } else {
        // 规则分析或单个文本，使用并发个别分析
        uncachedResults = await _processIndividually(uncachedTexts);
      }

      // 第三步：填充结果并更新缓存
      for (int i = 0; i < uncachedResults.length; i++) {
        final resultIndex = uncachedIndices[i];
        final result = uncachedResults[i];
        results[resultIndex] = result;

        // 缓存成功的分析结果
        final cacheKey = _generateCacheKey(uncachedTexts[i], currentMethod);
        _addToCache(cacheKey, result);
      }

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Batch analysis failed: $e');
      }
      
      // 错误情况下，将所有未缓存的位置设置为中性结果
      for (final index in uncachedIndices) {
        results[index] = AnalysisResult.neutral();
      }
    }

    return results;
  }

  /// 并发处理个别文本分析
  Future<List<AnalysisResult>> _processIndividually(
    List<String> texts, {
    bool forceRule = false,
  }) async {
    if (texts.isEmpty) return [];

    // 简单的并发处理，避免递归调用
    final futures = texts.map((text) {
      if (forceRule) {
        return _strategies[AnalysisMethod.rule]!.analyze(text);
      } else {
        // 直接调用策略分析，避免递归
        return _currentStrategy.analyze(text).catchError((_) {
          // 失败时降级到规则分析
          return _strategies[AnalysisMethod.rule]!.analyze(text);
        });
      }
    }).toList();

    try {
      return await Future.wait(futures);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Concurrent analysis failed: $e');
      }
      // 返回中性结果
      return List.filled(texts.length, AnalysisResult.neutral());
    }
  }

  /// 向后兼容的批量分析
  @Deprecated('Use analyzeEmotionsUnified for better AI analysis support')
  Future<List<EmotionAnalysisResult>> analyzeEmotions(List<String> texts) async {
    return texts.map((text) => analyzeEmotion(text)).toList();
  }
  
  /// 检查当前分析策略状态
  /// 
  /// 返回分析策略的可用性和错误信息，用于UI显示
  Future<AnalysisStrategyStatus> getStrategyStatus() async {
    final currentMethod = _settingsService.analysisMethod;
    final strategy = _strategies[currentMethod]!;
    
    try {
      final isAvailable = await strategy.isAvailable;
      
      if (isAvailable) {
        return AnalysisStrategyStatus(
          method: currentMethod,
          isAvailable: true,
          statusMessage: '${currentMethod.displayName}分析正常',
          canFallback: false,
        );
      } else {
        // 策略不可用，检查是否可以降级
        final canFallback = currentMethod != AnalysisMethod.rule;
        final fallbackAvailable = canFallback ? 
          await _strategies[AnalysisMethod.rule]!.isAvailable : false;
            
        return AnalysisStrategyStatus(
          method: currentMethod,
          isAvailable: false,
          statusMessage: canFallback && fallbackAvailable ? 
            '${currentMethod.displayName}不可用，将使用规则分析' :
            '${currentMethod.displayName}暂时不可用',
          canFallback: canFallback && fallbackAvailable,
        );
      }
    } catch (e) {
      return AnalysisStrategyStatus(
        method: currentMethod,
        isAvailable: false,
        statusMessage: '检查${currentMethod.displayName}状态时出错',
        canFallback: currentMethod != AnalysisMethod.rule,
        errorDetails: e.toString(),
      );
    }
  }

  /// 获取情绪建议
  String getEmotionAdvice(MoodType moodType, int score) {
    switch (moodType) {
      case MoodType.positive:
        if (score >= 80) {
          return '你现在的心情非常棒！继续保持这种积极的状态，分享你的快乐给身边的人吧～';
        } else if (score >= 60) {
          return '心情不错呢！可以做一些自己喜欢的事情来延续这份美好。';
        } else {
          return '有一些正面情绪，试着放大这些积极的感受，给自己一个小奖励吧！';
        }
        
      case MoodType.negative:
        if (score <= 20) {
          return '感觉你现在比较难受，建议找信任的朋友聊聊，或者做一些放松的活动。如果持续低落，考虑寻求专业帮助。';
        } else if (score <= 40) {
          return '情绪有些低落，试着做一些让自己开心的事情，比如听音乐、散步或看喜欢的电影。';
        } else {
          return '有一些负面情绪很正常，深呼吸，给自己一些时间，明天会更好的。';
        }
        
      case MoodType.neutral:
        return '心情比较平静，这也很好。可以尝试做一些有趣的事情，给生活增加一些色彩。';
    }
  }
}

// 情绪分析结果
class EmotionAnalysisResult {
  final MoodType moodType;
  final int score; // 0-100 情绪强度
  final double confidence; // 0-1 分析置信度
  
  const EmotionAnalysisResult({
    required this.moodType,
    required this.score,
    required this.confidence,
  });
  
  @override
  String toString() {
    return 'EmotionAnalysisResult(moodType: $moodType, score: $score, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// 分析策略状态信息
class AnalysisStrategyStatus {
  /// 当前使用的分析方法
  final AnalysisMethod method;
  
  /// 是否可用
  final bool isAvailable;
  
  /// 状态描述信息
  final String statusMessage;
  
  /// 是否可以降级到其他策略
  final bool canFallback;
  
  /// 错误详细信息（可选）
  final String? errorDetails;

  const AnalysisStrategyStatus({
    required this.method,
    required this.isAvailable,
    required this.statusMessage,
    required this.canFallback,
    this.errorDetails,
  });

  @override
  String toString() {
    return 'AnalysisStrategyStatus(method: $method, available: $isAvailable, message: $statusMessage)';
  }
}

/// 缓存的分析结果
class CachedAnalysisResult {
  final AnalysisResult result;
  final DateTime expiry;

  const CachedAnalysisResult({
    required this.result,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}