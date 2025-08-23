class MoodEntry {
  final String id;
  final String content;
  final DateTime timestamp;
  final MoodType mood;
  final int emotionScore; // 0-100 情绪强度评分

  const MoodEntry({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.mood,
    required this.emotionScore,
  });

  // 从JSON创建对象
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: MoodTypeExtension.fromString(json['mood'] as String),
      emotionScore: json['emotionScore'] as int,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood.name,
      'emotionScore': emotionScore,
    };
  }

  // 复制并修改对象
  MoodEntry copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    MoodType? mood,
    int? emotionScore,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      emotionScore: emotionScore ?? this.emotionScore,
    );
  }

  @override
  String toString() {
    return 'MoodEntry(id: $id, content: $content, timestamp: $timestamp, mood: $mood, emotionScore: $emotionScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntry &&
        other.id == id &&
        other.content == content &&
        other.timestamp == timestamp &&
        other.mood == mood &&
        other.emotionScore == emotionScore;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, timestamp, mood, emotionScore);
  }
}

// MVP阶段的基础情绪类型 - 设计为可扩展架构
enum MoodType {
  // MVP基础情绪类型 - 便于测试和演示
  positive,   // 正面情绪
  negative,   // 负面情绪  
  neutral,    // 中性情绪
  
  // 预留：后期可扩展为具体心理学模型
  // TODO: 考虑接入 Plutchik情绪轮 或 PAD情绪模型
}

// 情绪类型扩展 - 集中管理显示逻辑，便于后期维护
extension MoodTypeExtension on MoodType {
  String get displayName {
    // MVP阶段的简化显示
    switch (this) {
      case MoodType.positive:
        return '正面情绪';
      case MoodType.negative:
        return '负面情绪';
      case MoodType.neutral:
        return '中性情绪';
    }
  }

  String get emoji {
    switch (this) {
      case MoodType.positive:
        return '😊';
      case MoodType.negative:
        return '😔';
      case MoodType.neutral:
        return '😐';
    }
  }
  
  // 情绪极性 (-1到1，便于数据分析)
  double get polarity {
    switch (this) {
      case MoodType.positive:
        return 1.0;
      case MoodType.negative:
        return -1.0;
      case MoodType.neutral:
        return 0.0;
    }
  }

  // 从字符串创建枚举
  static MoodType fromString(String value) {
    return MoodType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MoodType.neutral,
    );
  }
}