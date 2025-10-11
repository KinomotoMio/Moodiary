import 'mood_entry.dart';

/// 每日睡前阅读摘要
///
/// 包含当天的情绪回顾、冥想引导词等内容
class DailySummary {
  /// 唯一标识（使用日期作为ID，格式：yyyy-MM-dd）
  final String id;

  /// 摘要生成日期
  final DateTime date;

  /// 当天记录数量
  final int fragmentCount;

  /// 事件回顾：今天发生了什么（AI生成，简洁）
  final String eventSummary;

  /// 情绪流向：情绪如何随事件变化（AI生成，温暖）
  final String emotionReview;

  /// 正念冥想引导词：基于事件或情绪的个性化引导（AI生成）
  final String meditationGuide;

  /// 当天主导情绪
  final MoodType? dominantMood;

  /// 当天平均情绪评分
  final double? averageScore;

  /// 生成时间（用于缓存管理）
  final DateTime generatedAt;

  /// 是否被用户收藏
  final bool isFavorite;

  const DailySummary({
    required this.id,
    required this.date,
    required this.fragmentCount,
    required this.eventSummary,
    required this.emotionReview,
    required this.meditationGuide,
    this.dominantMood,
    this.averageScore,
    required this.generatedAt,
    this.isFavorite = false,
  });

  /// 创建新的每日摘要
  factory DailySummary.create({
    required DateTime date,
    required int fragmentCount,
    required String eventSummary,
    required String emotionReview,
    required String meditationGuide,
    MoodType? dominantMood,
    double? averageScore,
  }) {
    final dateStr = _formatDateId(date);
    return DailySummary(
      id: dateStr,
      date: date,
      fragmentCount: fragmentCount,
      eventSummary: eventSummary,
      emotionReview: emotionReview,
      meditationGuide: meditationGuide,
      dominantMood: dominantMood,
      averageScore: averageScore,
      generatedAt: DateTime.now(),
      isFavorite: false,
    );
  }

  /// 从JSON反序列化
  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      fragmentCount: json['fragmentCount'] as int,
      eventSummary: json['eventSummary'] as String,
      emotionReview: json['emotionReview'] as String,
      meditationGuide: json['meditationGuide'] as String,
      dominantMood: json['dominantMood'] != null
          ? MoodTypeExtension.fromString(json['dominantMood'] as String)
          : null,
      averageScore: json['averageScore'] as double?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'fragmentCount': fragmentCount,
      'eventSummary': eventSummary,
      'emotionReview': emotionReview,
      'meditationGuide': meditationGuide,
      'dominantMood': dominantMood?.name,
      'averageScore': averageScore,
      'generatedAt': generatedAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  /// 创建副本（用于更新）
  DailySummary copyWith({
    String? id,
    DateTime? date,
    int? fragmentCount,
    String? eventSummary,
    String? emotionReview,
    String? meditationGuide,
    MoodType? dominantMood,
    double? averageScore,
    DateTime? generatedAt,
    bool? isFavorite,
  }) {
    return DailySummary(
      id: id ?? this.id,
      date: date ?? this.date,
      fragmentCount: fragmentCount ?? this.fragmentCount,
      eventSummary: eventSummary ?? this.eventSummary,
      emotionReview: emotionReview ?? this.emotionReview,
      meditationGuide: meditationGuide ?? this.meditationGuide,
      dominantMood: dominantMood ?? this.dominantMood,
      averageScore: averageScore ?? this.averageScore,
      generatedAt: generatedAt ?? this.generatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// 是否为今天的摘要
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 摘要是否仍然有效（缓存未过期）
  /// 每日摘要有效期为7天
  bool get isValid {
    final expiryDate = generatedAt.add(const Duration(days: 7));
    return DateTime.now().isBefore(expiryDate);
  }

  /// 格式化日期为ID（yyyy-MM-dd）
  static String _formatDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 从日期获取ID
  static String getIdFromDate(DateTime date) => _formatDateId(date);

  @override
  String toString() {
    return 'DailySummary(id: $id, date: $date, fragmentCount: $fragmentCount, dominantMood: $dominantMood)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailySummary &&
        other.id == id &&
        other.date == date &&
        other.fragmentCount == fragmentCount &&
        other.eventSummary == eventSummary &&
        other.emotionReview == emotionReview &&
        other.meditationGuide == meditationGuide &&
        other.dominantMood == dominantMood &&
        other.averageScore == averageScore &&
        other.generatedAt == generatedAt &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      date,
      fragmentCount,
      eventSummary,
      emotionReview,
      meditationGuide,
      dominantMood,
      averageScore,
      generatedAt,
      isFavorite,
    );
  }
}
