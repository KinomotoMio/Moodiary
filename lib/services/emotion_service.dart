import '../models/mood_entry.dart';

class EmotionService {
  static EmotionService? _instance;
  static EmotionService get instance => _instance ??= EmotionService._();
  
  EmotionService._();
  
  // MVP阶段的基础情绪分析 - 使用关键词匹配
  // TODO: 后期可替换为AI API调用
  EmotionAnalysisResult analyzeEmotion(String text) {
    final cleanText = text.toLowerCase().trim();
    
    if (cleanText.isEmpty) {
      return EmotionAnalysisResult(
        moodType: MoodType.neutral,
        score: 50,
        confidence: 0.5,
      );
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
    
    return EmotionAnalysisResult(
      moodType: dominantMood,
      score: emotionScore,
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
  
  // 批量分析多条文本
  Future<List<EmotionAnalysisResult>> analyzeEmotions(List<String> texts) async {
    return texts.map((text) => analyzeEmotion(text)).toList();
  }
  
  // 获取情绪建议
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