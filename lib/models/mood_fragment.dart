import 'mood_entry.dart';

// Fragment类型 - 支持多种媒体形式
enum FragmentType {
  text,    // 纯文本
  image,   // 图片
  mixed,   // 混合媒体（文字+图片）
}

// 媒体附件
class MediaAttachment {
  final String id;
  final String filePath;
  final MediaType type;
  final DateTime createdAt;
  final String? caption; // 图片描述

  const MediaAttachment({
    required this.id,
    required this.filePath,
    required this.type,
    required this.createdAt,
    this.caption,
  });

  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      id: json['id'] as String,
      filePath: json['filePath'] as String,
      type: MediaType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'caption': caption,
    };
  }
}

enum MediaType {
  image,
  // 预留扩展：audio, video
}

// 话题标签
class TopicTag {
  final String name;
  final DateTime firstUsed;
  final int usageCount;

  const TopicTag({
    required this.name,
    required this.firstUsed,
    required this.usageCount,
  });

  factory TopicTag.fromJson(Map<String, dynamic> json) {
    return TopicTag(
      name: json['name'] as String,
      firstUsed: DateTime.parse(json['firstUsed'] as String),
      usageCount: json['usageCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'firstUsed': firstUsed.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  TopicTag copyWith({
    String? name,
    DateTime? firstUsed,
    int? usageCount,
  }) {
    return TopicTag(
      name: name ?? this.name,
      firstUsed: firstUsed ?? this.firstUsed,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

// 扩展的心情片段模型
class MoodFragment {
  final String id;
  final String? textContent;           // 文字内容
  final List<MediaAttachment> media;   // 媒体附件
  final List<String> topicTags;        // 话题标签 (#工作 #心情)
  final DateTime timestamp;
  final MoodType mood;
  final int emotionScore;
  final FragmentType type;

  const MoodFragment({
    required this.id,
    this.textContent,
    required this.media,
    required this.topicTags,
    required this.timestamp,
    required this.mood,
    required this.emotionScore,
    required this.type,
  });

  // 从旧的MoodEntry迁移
  factory MoodFragment.fromMoodEntry(MoodEntry entry) {
    return MoodFragment(
      id: entry.id,
      textContent: entry.content.isEmpty ? null : entry.content,
      media: [],
      topicTags: _extractTopicTags(entry.content),
      timestamp: entry.timestamp,
      mood: entry.mood,
      emotionScore: entry.emotionScore,
      type: FragmentType.text,
    );
  }

  // 创建新的Fragment
  factory MoodFragment.create({
    String? textContent,
    List<MediaAttachment>? media,
    List<String>? topicTags,
    required MoodType mood,
    required int emotionScore,
  }) {
    final now = DateTime.now();
    final allMedia = media ?? <MediaAttachment>[];
    final allTags = topicTags ?? <String>[];
    
    // 从文本内容中提取标签
    if (textContent != null && textContent.isNotEmpty) {
      allTags.addAll(_extractTopicTags(textContent));
    }
    
    // 确定Fragment类型
    FragmentType fragmentType;
    if (allMedia.isNotEmpty && (textContent?.isNotEmpty ?? false)) {
      fragmentType = FragmentType.mixed;
    } else if (allMedia.isNotEmpty) {
      fragmentType = FragmentType.image;
    } else {
      fragmentType = FragmentType.text;
    }

    return MoodFragment(
      id: '${now.millisecondsSinceEpoch}',
      textContent: textContent,
      media: allMedia,
      topicTags: allTags.toSet().toList(), // 去重
      timestamp: now,
      mood: mood,
      emotionScore: emotionScore,
      type: fragmentType,
    );
  }

  // 提取话题标签的静态方法
  static List<String> _extractTopicTags(String content) {
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  // 获取显示内容（不包含标签的纯净文本）
  String get displayContent {
    if (textContent == null) return '';
    
    // 移除话题标签，保留其他内容
    String content = textContent!;
    final regex = RegExp(r'#\w+\s?');
    content = content.replaceAll(regex, '').trim();
    
    return content;
  }

  // 获取完整内容（包含标签）
  String get fullContent => textContent ?? '';

  // 是否有媒体附件
  bool get hasMedia => media.isNotEmpty;

  // 是否有话题标签
  bool get hasTopicTags => topicTags.isNotEmpty;

  // 转换为旧的MoodEntry（兼容性）
  MoodEntry toMoodEntry() {
    return MoodEntry(
      id: id,
      content: textContent ?? '',
      timestamp: timestamp,
      mood: mood,
      emotionScore: emotionScore,
    );
  }

  factory MoodFragment.fromJson(Map<String, dynamic> json) {
    return MoodFragment(
      id: json['id'] as String,
      textContent: json['textContent'] as String?,
      media: (json['media'] as List<dynamic>?)
          ?.map((item) => MediaAttachment.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      topicTags: (json['topicTags'] as List<dynamic>?)
          ?.map((item) => item as String)
          .toList() ?? [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      mood: MoodTypeExtension.fromString(json['mood'] as String),
      emotionScore: json['emotionScore'] as int,
      type: FragmentType.values.byName(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'textContent': textContent,
      'media': media.map((item) => item.toJson()).toList(),
      'topicTags': topicTags,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood.name,
      'emotionScore': emotionScore,
      'type': type.name,
    };
  }

  MoodFragment copyWith({
    String? id,
    String? textContent,
    List<MediaAttachment>? media,
    List<String>? topicTags,
    DateTime? timestamp,
    MoodType? mood,
    int? emotionScore,
    FragmentType? type,
  }) {
    return MoodFragment(
      id: id ?? this.id,
      textContent: textContent ?? this.textContent,
      media: media ?? this.media,
      topicTags: topicTags ?? this.topicTags,
      timestamp: timestamp ?? this.timestamp,
      mood: mood ?? this.mood,
      emotionScore: emotionScore ?? this.emotionScore,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'MoodFragment(id: $id, textContent: $textContent, media: ${media.length}, topicTags: $topicTags, timestamp: $timestamp, mood: $mood, emotionScore: $emotionScore, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodFragment &&
        other.id == id &&
        other.textContent == textContent &&
        _listEquals(other.media, media) &&
        _listEquals(other.topicTags, topicTags) &&
        other.timestamp == timestamp &&
        other.mood == mood &&
        other.emotionScore == emotionScore &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      textContent,
      Object.hashAll(media),
      Object.hashAll(topicTags),
      timestamp,
      mood,
      emotionScore,
      type,
    );
  }

  // 辅助方法：比较列表
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}