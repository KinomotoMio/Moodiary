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

  /// 获取当前配置的分析策略
  AnalysisStrategy get _currentStrategy {
    final method = _settingsService.analysisMethod;
    return _strategies[method] ?? _strategies[AnalysisMethod.rule]!;
  }

  /// 统一的情绪分析入口
  /// 
  /// 根据用户设置自动选择合适的分析策略
  /// 支持优雅降级：AI分析失败时自动回退到规则分析
  Future<AnalysisResult> analyzeEmotionUnified(String content) async {
    if (content.trim().isEmpty) {
      return AnalysisResult.neutral();
    }

    try {
      final strategy = _currentStrategy;
      
      // 检查策略是否可用
      if (await strategy.isAvailable) {
        if (kDebugMode) {
          debugPrint('Using ${strategy.strategyName} for emotion analysis');
        }
        return await strategy.analyze(content);
      } else {
        if (kDebugMode) {
          debugPrint('${strategy.strategyName} not available, falling back to rule-based');
        }
        // 降级到规则分析
        return await _strategies[AnalysisMethod.rule]!.analyze(content);
      }
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
          return await _strategies[AnalysisMethod.rule]!.analyze(content);
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
  Future<List<AnalysisResult>> analyzeEmotionsUnified(List<String> texts) async {
    final results = <AnalysisResult>[];
    
    for (final text in texts) {
      try {
        final result = await analyzeEmotionUnified(text);
        results.add(result);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Batch analysis failed for text: ${text.substring(0, 20)}..., error: $e');
        }
        // 添加中性结果，避免中断整个批量分析
        results.add(AnalysisResult.neutral());
      }
    }
    
    return results;
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