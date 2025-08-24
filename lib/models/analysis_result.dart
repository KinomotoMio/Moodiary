import 'mood_entry.dart';

/// 统一的情绪分析结果模型
/// 
/// 无论使用何种分析方法（规则、AI、本地模型），都返回统一格式的结果
/// 确保上层业务逻辑与具体分析实现解耦
class AnalysisResult {
  /// 情绪类型（正面、负面、中性）
  final MoodType moodType;
  
  /// 情绪强度评分 (0-100)
  /// 0: 非常消极/平淡  100: 非常积极/强烈
  final int emotionScore;
  
  /// 自动提取的话题标签列表
  /// AI分析可能提取更准确的标签，规则分析提取基础标签
  final List<String> extractedTags;
  
  /// 分析推理过程或原因（可选）
  /// AI分析可能提供分析依据，规则分析可能显示匹配的关键词
  final String? reasoning;
  
  /// 使用的分析方法
  final String analysisMethod;
  
  /// 分析时间戳
  final DateTime timestamp;
  
  /// 分析置信度 (0.0-1.0)，可选
  /// AI分析可能提供置信度分数，规则分析可能基于关键词匹配程度
  final double? confidence;

  const AnalysisResult({
    required this.moodType,
    required this.emotionScore,
    required this.extractedTags,
    required this.analysisMethod,
    required this.timestamp,
    this.reasoning,
    this.confidence,
  });

  /// 从JSON创建分析结果
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      moodType: MoodTypeExtension.fromString(json['moodType'] as String),
      emotionScore: json['emotionScore'] as int,
      extractedTags: List<String>.from(json['extractedTags'] as List),
      reasoning: json['reasoning'] as String?,
      analysisMethod: json['analysisMethod'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: json['confidence'] as double?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'moodType': moodType.name,
      'emotionScore': emotionScore,
      'extractedTags': extractedTags,
      'reasoning': reasoning,
      'analysisMethod': analysisMethod,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
    };
  }

  /// 创建副本，支持部分字段修改
  AnalysisResult copyWith({
    MoodType? moodType,
    int? emotionScore,
    List<String>? extractedTags,
    String? reasoning,
    String? analysisMethod,
    DateTime? timestamp,
    double? confidence,
  }) {
    return AnalysisResult(
      moodType: moodType ?? this.moodType,
      emotionScore: emotionScore ?? this.emotionScore,
      extractedTags: extractedTags ?? this.extractedTags,
      reasoning: reasoning ?? this.reasoning,
      analysisMethod: analysisMethod ?? this.analysisMethod,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
    );
  }

  /// 创建基础的规则分析结果
  factory AnalysisResult.fromRuleAnalysis({
    required MoodType moodType,
    required int emotionScore,
    List<String>? extractedTags,
    String? reasoning,
  }) {
    return AnalysisResult(
      moodType: moodType,
      emotionScore: emotionScore,
      extractedTags: extractedTags ?? [],
      reasoning: reasoning,
      analysisMethod: 'rule',
      timestamp: DateTime.now(),
      confidence: null,
    );
  }

  /// 创建AI分析结果
  factory AnalysisResult.fromAIAnalysis({
    required MoodType moodType,
    required int emotionScore,
    required List<String> extractedTags,
    required String reasoning,
    required double confidence,
    required String aiProvider,
  }) {
    return AnalysisResult(
      moodType: moodType,
      emotionScore: emotionScore,
      extractedTags: extractedTags,
      reasoning: reasoning,
      analysisMethod: 'llm_$aiProvider',
      timestamp: DateTime.now(),
      confidence: confidence,
    );
  }

  /// 创建中性分析结果（用于错误或空内容场景）
  factory AnalysisResult.neutral() {
    return AnalysisResult(
      moodType: MoodType.neutral,
      emotionScore: 50,
      extractedTags: [],
      reasoning: null,
      analysisMethod: 'fallback',
      timestamp: DateTime.now(),
      confidence: 0.5,
    );
  }

  /// 获取简化的情绪描述
  String get moodDescription {
    final intensity = emotionScore > 70 ? '很' : emotionScore > 30 ? '较' : '有些';
    switch (moodType) {
      case MoodType.positive:
        return '$intensity积极';
      case MoodType.negative:
        return '$intensity消极';
      case MoodType.neutral:
        return '比较平静';
    }
  }

  /// 检查结果是否有效
  bool get isValid {
    return emotionScore >= 0 && 
           emotionScore <= 100 && 
           analysisMethod.isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisResult &&
          runtimeType == other.runtimeType &&
          moodType == other.moodType &&
          emotionScore == other.emotionScore &&
          extractedTags.toString() == other.extractedTags.toString() &&
          reasoning == other.reasoning &&
          analysisMethod == other.analysisMethod &&
          confidence == other.confidence;

  @override
  int get hashCode => Object.hash(
        moodType,
        emotionScore,
        extractedTags,
        reasoning,
        analysisMethod,
        confidence,
      );

  @override
  String toString() {
    return 'AnalysisResult('
        'mood: $moodType, '
        'score: $emotionScore, '
        'tags: $extractedTags, '
        'method: $analysisMethod, '
        'confidence: $confidence'
        ')';
  }
}