import '../../models/analysis_result.dart';
import '../../models/mood_entry.dart';
import '../../enums/analysis_method.dart';
import 'analysis_strategy.dart';

/// 基于规则的传统情绪分析策略
/// 
/// 直接封装现有的EmotionService逻辑，确保完全兼容性
/// 不做任何功能增强，纯粹的架构适配
class RuleBasedStrategy implements AnalysisStrategy {

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
    return analyzeSync(content);
  }

  /// 同步版本的规则分析
  /// 
  /// 避免循环依赖，直接实现规则分析逻辑
  AnalysisResult analyzeSync(String content) {
    final cleanText = content.toLowerCase().trim();
    
    if (cleanText.isEmpty) {
      return AnalysisResult.neutral();
    }
    
    // 情绪关键词词典 - MVP阶段简化版
    final emotionKeywords = {
      MoodType.positive: [
        '开心', '快乐', '高兴', '兴奋', '满意', '幸福', '愉快', '舒服', '棒', '好', '爱',
        '成功', '胜利', '完美', '美好', '温暖', '感动', '骄傲', '自豪', '满足', '放松',
        '哈哈', '嘻嘻', '😊', '😄', '😍', '🥰', '😘', '🤩', '😋', '😌'
      ],
      MoodType.negative: [
        '难过', '悲伤', '失望', '沮丧', '痛苦', '伤心', '哭', '泪', '累', '烦', '恨',
        '愤怒', '生气', '愤慨', '讨厌', '焦虑', '紧张', '害怕', '恐惧', '担心', '压力',
        '糟糕', '坏', '差', '失败', '挫折', '孤独', '空虚', '无聊', '郁闷', '抑郁',
        '😢', '😭', '😔', '😞', '😟', '😧', '😨', '😰', '😱', '🙄', '😤', '😠', '😡'
      ],
      MoodType.neutral: [
        '平静', '平常', '一般', '还好', '普通', '正常', '平淡', '无感', '中性',
        '😐', '😑', '🙂'
      ],
    };
    
    // 计算各种情绪的得分
    final scores = <MoodType, double>{};
    
    for (final mood in MoodType.values) {
      final keywords = emotionKeywords[mood] ?? [];
      int matchCount = 0;
      double intensitySum = 0.0;
      
      for (final keyword in keywords) {
        if (cleanText.contains(keyword)) {
          matchCount++;
          // 根据关键词长度和位置给予不同权重
          final weight = keyword.length > 2 ? 1.5 : 1.0;
          intensitySum += weight;
        }
      }
      
      if (matchCount > 0) {
        // 基础得分 + 强度加成
        scores[mood] = (matchCount * 10.0) + (intensitySum * 5.0);
      } else {
        scores[mood] = 0.0;
      }
    }
    
    // 找出得分最高的情绪类型
    MoodType dominantMood = MoodType.neutral;
    double maxScore = scores[MoodType.neutral] ?? 0.0;
    
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        dominantMood = entry.key;
      }
    }
    
    // 计算置信度和情绪强度
    final totalScore = scores.values.reduce((a, b) => a + b);
    final confidence = totalScore > 0 ? (maxScore / totalScore).clamp(0.0, 1.0) : 0.5;
    
    // 根据情绪类型和文本特征计算0-100的情绪强度
    int emotionScore = _calculateEmotionScore(cleanText, dominantMood, maxScore);
    
    return AnalysisResult(
      moodType: dominantMood,
      emotionScore: emotionScore,
      extractedTags: [], // 规则分析暂不提取标签
      reasoning: null,
      analysisMethod: AnalysisMethod.rule.name,
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  // 计算情绪强度评分 (0-100)
  int _calculateEmotionScore(String text, MoodType moodType, double rawScore) {
    // 基础分数
    int baseScore = 50;
    
    // 根据情绪极性调整
    switch (moodType) {
      case MoodType.positive:
        baseScore = 70;
        break;
      case MoodType.negative:
        baseScore = 30;
        break;
      case MoodType.neutral:
        baseScore = 50;
        break;
    }
    
    // 根据原始得分调整强度
    final intensityAdjustment = (rawScore / 10.0).clamp(-20.0, 20.0).round();
    
    // 根据文本长度调整（更长的文本可能包含更多情绪表达）
    final lengthAdjustment = (text.length / 50.0).clamp(-5.0, 10.0).round();
    
    // 检查强烈情绪表达
    final strongEmotions = ['非常', '特别', '超级', '极其', '超', '巨', '！！', '...'];
    int strongEmotionBonus = 0;
    for (final strong in strongEmotions) {
      if (text.contains(strong)) {
        strongEmotionBonus += 5;
      }
    }
    
    final finalScore = (baseScore + intensityAdjustment + lengthAdjustment + strongEmotionBonus)
        .clamp(0, 100);
        
    return finalScore;
  }
}