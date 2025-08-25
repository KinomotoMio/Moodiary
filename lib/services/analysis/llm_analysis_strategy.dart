import 'package:flutter/foundation.dart';
import '../../models/analysis_result.dart';
import '../../models/mood_entry.dart';
import '../../enums/analysis_method.dart';
import '../llm/llm_client.dart';
import '../llm/providers/base_llm_provider.dart';
import '../llm/prompt_templates/emotion_analysis_prompt.dart';
import '../settings_service.dart';
import 'analysis_strategy.dart';

/// 基于大语言模型的AI情绪分析策略
/// 
/// 调用远程AI服务进行智能情绪分析
/// 注意：依然保持三分类结果(positive/negative/neutral)，确保与现有系统兼容
class LLMAnalysisStrategy implements AnalysisStrategy {
  final LLMClient _llmClient = LLMClient.instance;
  final SettingsService _settingsService = SettingsService.instance;

  @override
  String get strategyName => 'llm_analysis';

  @override
  String get description => '使用AI大模型进行智能分析，需要网络连接';

  @override
  bool get requiresNetwork => true;

  @override
  Future<bool> get isAvailable async {
    try {
      final settings = _settingsService.currentSettings;
      
      // 检查是否配置了LLM服务
      if (!settings.isLLMConfigured) {
        return false;
      }
      
      // 测试连接
      return await _llmClient.testProviderConnection(
        providerName: settings.llmProvider!,
        apiKey: settings.llmApiKey,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LLM availability check failed: $e');
      }
      return false;
    }
  }

  @override
  List<String> get requiredConfigs => ['llm_provider', 'llm_api_key'];

  @override
  int get estimatedDurationMs => 5000; // AI分析预计5秒

  @override
  double get confidenceBaseline => 0.8; // AI分析置信度较高

  @override
  Future<AnalysisResult> analyze(String content) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Content cannot be empty for LLM analysis');
    }

    try {
      final settings = _settingsService.currentSettings;
      
      if (!settings.isLLMConfigured) {
        throw const LLMException('LLM provider or API key not configured');
      }

      // 生成提示词
      final prompt = EmotionAnalysisPrompt.generatePrompt(content);
      
      if (kDebugMode) {
        debugPrint('LLM Analysis - Provider: ${settings.llmProvider}');
        debugPrint('LLM Analysis - Content length: ${content.length}');
      }

      // 调用LLM API
      final response = await _llmClient.generateText(
        providerName: settings.llmProvider!,
        prompt: prompt,
        apiKey: settings.llmApiKey,
        model: settings.llmModel,
        parameters: {
          'max_tokens': 500,
          'temperature': 0.3, // 较低的temperature确保结果稳定
        },
      );

      if (kDebugMode) {
        debugPrint('LLM Response: $response');
      }

      // 解析响应
      final parsedResult = EmotionAnalysisPrompt.validateAndParseResponse(response);
      
      // 转换为标准的AnalysisResult
      return AnalysisResult(
        moodType: _parseMoodType(parsedResult['moodType'] as String),
        emotionScore: parsedResult['emotionScore'] as int,
        extractedTags: List<String>.from(parsedResult['extractedTags'] as List),
        reasoning: parsedResult['reasoning'] as String,
        analysisMethod: AnalysisMethod.llm.name,
        timestamp: DateTime.now(),
        confidence: (parsedResult['confidence'] as num).toDouble(),
      );

    } on LLMException catch (e) {
      if (kDebugMode) {
        debugPrint('LLM analysis failed: $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LLM analysis unexpected error: $e');
      }
      throw LLMException('LLM analysis failed: $e');
    }
  }

  @override
  Future<bool> validateConfig() async {
    try {
      final settings = _settingsService.currentSettings;
      
      if (!settings.isLLMConfigured) {
        return false;
      }

      // 测试连接
      return await _llmClient.testProviderConnection(
        providerName: settings.llmProvider!,
        apiKey: settings.llmApiKey,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LLM config validation failed: $e');
      }
      return false;
    }
  }

  /// 将LLM返回的字符串转换为MoodType枚举
  MoodType _parseMoodType(String moodTypeString) {
    switch (moodTypeString.toLowerCase()) {
      case 'positive':
        return MoodType.positive;
      case 'negative':
        return MoodType.negative;
      case 'neutral':
        return MoodType.neutral;
      default:
        if (kDebugMode) {
          debugPrint('Unknown mood type: $moodTypeString, defaulting to neutral');
        }
        return MoodType.neutral;
    }
  }

  /// 批量分析多个内容（可选功能，用于历史记录重新分析）
  Future<List<AnalysisResult>> analyzeBatch(List<String> contents) async {
    if (contents.isEmpty) {
      return [];
    }

    if (contents.length == 1) {
      // 单个内容直接调用普通分析
      return [await analyze(contents.first)];
    }

    try {
      final settings = _settingsService.currentSettings;
      
      if (!settings.isLLMConfigured) {
        throw const LLMException('LLM provider or API key not configured');
      }

      // 生成批量提示词
      final prompt = EmotionAnalysisPrompt.generateBatchPrompt(contents);
      
      if (kDebugMode) {
        debugPrint('LLM Batch Analysis - Count: ${contents.length}');
      }

      // 调用LLM API
      final response = await _llmClient.generateText(
        providerName: settings.llmProvider!,
        prompt: prompt,
        apiKey: settings.llmApiKey,
        model: settings.llmModel,
        parameters: {
          'max_tokens': 2000, // 批量分析需要更多tokens
          'temperature': 0.3,
        },
      );

      // 解析批量响应
      final parsedResults = EmotionAnalysisPrompt.validateAndParseBatchResponse(
        response, 
        contents.length,
      );
      
      // 转换为AnalysisResult列表
      return parsedResults.map((result) => AnalysisResult(
        moodType: _parseMoodType(result['moodType'] as String),
        emotionScore: result['emotionScore'] as int,
        extractedTags: List<String>.from(result['extractedTags'] as List),
        reasoning: result['reasoning'] as String,
        analysisMethod: AnalysisMethod.llm.name,
        timestamp: DateTime.now(),
        confidence: (result['confidence'] as num).toDouble(),
      )).toList();

    } catch (e) {
      if (kDebugMode) {
        debugPrint('LLM batch analysis failed: $e');
      }
      
      // 批量分析失败时，回退到逐个分析
      final results = <AnalysisResult>[];
      for (final content in contents) {
        try {
          results.add(await analyze(content));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Individual analysis failed in batch fallback: $e');
          }
          // 跳过失败的分析，继续处理下一个
        }
      }
      return results;
    }
  }
}