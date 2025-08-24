import '../../models/analysis_result.dart';
import '../emotion_service.dart';
import 'analysis_strategy.dart';

/// 基于规则的传统情绪分析策略
/// 
/// 直接封装现有的EmotionService逻辑，确保完全兼容性
/// 不做任何功能增强，纯粹的架构适配
class RuleBasedStrategy implements AnalysisStrategy {
  final EmotionService _emotionService = EmotionService.instance;

  @override
  String get strategyName => 'rule_based';

  @override
  String get description => '使用关键词和规则进行快速分析，离线可用';

  @override
  bool get requiresNetwork => false;

  @override
  Future<bool> get isAvailable async => true;

  @override
  int get estimatedDurationMs => 50;

  @override
  double get confidenceBaseline => 0.7;

  @override
  List<String> get requiredConfigs => []; // 规则分析无需额外配置

  @override
  Future<bool> validateConfig() async => true; // 规则分析无需配置验证

  @override
  Future<AnalysisResult> analyze(String content) async {
    // 直接使用现有EmotionService的逻辑，确保完全兼容
    final analysisResult = _emotionService.analyzeEmotion(content);
    
    // 简单转换为统一的AnalysisResult格式
    return AnalysisResult.fromRuleAnalysis(
      moodType: analysisResult.moodType,
      emotionScore: analysisResult.score,
      extractedTags: [], // 暂不提取额外标签
      reasoning: null, // 暂不提供分析推理
    );
  }
}