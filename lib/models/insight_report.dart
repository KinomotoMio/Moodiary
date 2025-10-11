import 'mood_entry.dart';

/// 洞察报告类型
enum ReportType {
  weekly,  // 周报
  monthly, // 月报
}

/// 心理洞察报告
///
/// 基于CBT（认知行为疗法）框架，帮助用户理解情绪模式
class InsightReport {
  /// 唯一标识符（格式：weekly_2024_W01 或 monthly_2024_01）
  final String id;

  /// 报告类型
  final ReportType type;

  /// 开始日期
  final DateTime startDate;

  /// 结束日期
  final DateTime endDate;

  /// 生成时间
  final DateTime generatedAt;

  /// 数据统计
  final ReportStats stats;

  /// 核心洞察（AI生成，150-200字）
  ///
  /// 基于CBT框架：
  /// - 识别主要情绪模式
  /// - 情绪与事件/思维的关联
  /// - 温和的自我觉察引导
  final String coreInsight;

  /// 情绪模式分析（AI生成，200-250字）
  ///
  /// 包含：
  /// - 情绪波动规律（如时间段、周期性）
  /// - 触发因素分析
  /// - 积极与消极情绪的平衡
  final String emotionPattern;

  /// 行为建议（AI生成，150-200字）
  ///
  /// 基于CBT：
  /// - 具体的、可执行的建议
  /// - 认知重构提示
  /// - 情绪调节策略
  final String behaviorSuggestion;

  /// 是否已读
  final bool isRead;

  /// 是否收藏
  final bool isFavorite;

  const InsightReport({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    required this.stats,
    required this.coreInsight,
    required this.emotionPattern,
    required this.behaviorSuggestion,
    this.isRead = false,
    this.isFavorite = false,
  });

  /// 创建新的洞察报告
  factory InsightReport.create({
    required ReportType type,
    required DateTime startDate,
    required DateTime endDate,
    required ReportStats stats,
    required String coreInsight,
    required String emotionPattern,
    required String behaviorSuggestion,
  }) {
    final id = _generateId(type, startDate);
    return InsightReport(
      id: id,
      type: type,
      startDate: startDate,
      endDate: endDate,
      generatedAt: DateTime.now(),
      stats: stats,
      coreInsight: coreInsight,
      emotionPattern: emotionPattern,
      behaviorSuggestion: behaviorSuggestion,
    );
  }

  /// 生成报告ID
  static String _generateId(ReportType type, DateTime startDate) {
    if (type == ReportType.weekly) {
      // 计算周数（ISO 8601标准）
      final weekNumber = _getWeekNumber(startDate);
      return 'weekly_${startDate.year}_W${weekNumber.toString().padLeft(2, '0')}';
    } else {
      return 'monthly_${startDate.year}_${startDate.month.toString().padLeft(2, '0')}';
    }
  }

  /// 计算周数（简化版，从1月1日开始计算）
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).floor() + 1;
  }

  /// 获取报告标题
  String get title {
    if (type == ReportType.weekly) {
      return '${startDate.month}月第${_getWeekOfMonth()}周心理洞察';
    } else {
      return '${startDate.year}年${startDate.month}月心理洞察';
    }
  }

  /// 获取月份中的第几周
  int _getWeekOfMonth() {
    final firstDayOfMonth = DateTime(startDate.year, startDate.month, 1);
    final daysDiff = startDate.difference(firstDayOfMonth).inDays;
    return (daysDiff / 7).floor() + 1;
  }

  /// 获取时间范围描述
  String get dateRangeDescription {
    final startStr = '${startDate.month}月${startDate.day}日';
    final endStr = '${endDate.month}月${endDate.day}日';
    return '$startStr - $endStr';
  }

  /// 是否为当前周期
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'stats': stats.toJson(),
      'coreInsight': coreInsight,
      'emotionPattern': emotionPattern,
      'behaviorSuggestion': behaviorSuggestion,
      'isRead': isRead,
      'isFavorite': isFavorite,
    };
  }

  /// JSON反序列化
  factory InsightReport.fromJson(Map<String, dynamic> json) {
    return InsightReport(
      id: json['id'] as String,
      type: ReportType.values.byName(json['type'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      stats: ReportStats.fromJson(json['stats'] as Map<String, dynamic>),
      coreInsight: json['coreInsight'] as String,
      emotionPattern: json['emotionPattern'] as String,
      behaviorSuggestion: json['behaviorSuggestion'] as String,
      isRead: json['isRead'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  /// 复制并修改
  InsightReport copyWith({
    String? id,
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? generatedAt,
    ReportStats? stats,
    String? coreInsight,
    String? emotionPattern,
    String? behaviorSuggestion,
    bool? isRead,
    bool? isFavorite,
  }) {
    return InsightReport(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      generatedAt: generatedAt ?? this.generatedAt,
      stats: stats ?? this.stats,
      coreInsight: coreInsight ?? this.coreInsight,
      emotionPattern: emotionPattern ?? this.emotionPattern,
      behaviorSuggestion: behaviorSuggestion ?? this.behaviorSuggestion,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// 报告统计数据
class ReportStats {
  /// 记录总数
  final int totalEntries;

  /// 平均情绪评分
  final double averageScore;

  /// 主导情绪类型
  final MoodType? dominantMood;

  /// 情绪分布（各类型情绪的数量）
  final Map<MoodType, int> moodDistribution;

  /// 最高评分
  final int highestScore;

  /// 最低评分
  final int lowestScore;

  /// 情绪波动度（标准差）
  final double emotionVolatility;

  /// 活跃标签（前5个最常用的话题标签）
  final List<String> topTags;

  const ReportStats({
    required this.totalEntries,
    required this.averageScore,
    this.dominantMood,
    required this.moodDistribution,
    required this.highestScore,
    required this.lowestScore,
    required this.emotionVolatility,
    required this.topTags,
  });

  /// JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'totalEntries': totalEntries,
      'averageScore': averageScore,
      'dominantMood': dominantMood?.name,
      'moodDistribution': moodDistribution.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'highestScore': highestScore,
      'lowestScore': lowestScore,
      'emotionVolatility': emotionVolatility,
      'topTags': topTags,
    };
  }

  /// JSON反序列化
  factory ReportStats.fromJson(Map<String, dynamic> json) {
    final moodDistMap = (json['moodDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        MoodTypeExtension.fromString(key),
        value as int,
      ),
    );

    return ReportStats(
      totalEntries: json['totalEntries'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      dominantMood: json['dominantMood'] != null
          ? MoodTypeExtension.fromString(json['dominantMood'] as String)
          : null,
      moodDistribution: moodDistMap,
      highestScore: json['highestScore'] as int,
      lowestScore: json['lowestScore'] as int,
      emotionVolatility: (json['emotionVolatility'] as num).toDouble(),
      topTags: (json['topTags'] as List<dynamic>).cast<String>(),
    );
  }
}

/// ReportType扩展
extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.weekly:
        return '周报';
      case ReportType.monthly:
        return '月报';
    }
  }

  String get description {
    switch (this) {
      case ReportType.weekly:
        return '7天情绪洞察';
      case ReportType.monthly:
        return '30天心理回顾';
    }
  }
}
