import '../services/llm/tool_calling.dart';

/// 会话历史记录
///
/// 用于持久化对话会话，支持会话管理和恢复
class ConversationHistory {
  /// 会话唯一ID
  final String id;

  /// 会话标题（自动从首条用户消息生成或用户自定义）
  final String title;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime lastUpdatedAt;

  /// 对话消息列表
  final List<ChatMessage> messages;

  /// 是否为临时会话（退出后删除）
  final bool isTemporary;

  /// 是否已完成（保存了记录）
  final bool isComplete;

  /// 提取的心情数据（如果有）
  final Map<String, dynamic>? extractedData;

  const ConversationHistory({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
    this.isTemporary = false,
    this.isComplete = false,
    this.extractedData,
  });

  /// 创建新会话
  factory ConversationHistory.create({
    String? title,
    bool isTemporary = false,
  }) {
    final now = DateTime.now();
    return ConversationHistory(
      id: '${now.millisecondsSinceEpoch}',
      title: title ?? '新对话',
      createdAt: now,
      lastUpdatedAt: now,
      messages: [],
      isTemporary: isTemporary,
    );
  }

  /// 从JSON反序列化
  factory ConversationHistory.fromJson(Map<String, dynamic> json) {
    return ConversationHistory(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      isTemporary: json['isTemporary'] as bool? ?? false,
      isComplete: json['isComplete'] as bool? ?? false,
      extractedData: json['extractedData'] as Map<String, dynamic>?,
    );
  }

  /// 序列化为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'isTemporary': isTemporary,
      'isComplete': isComplete,
      'extractedData': extractedData,
    };
  }

  /// 更新会话
  ConversationHistory copyWith({
    String? title,
    DateTime? lastUpdatedAt,
    List<ChatMessage>? messages,
    bool? isComplete,
    Map<String, dynamic>? extractedData,
  }) {
    return ConversationHistory(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      messages: messages ?? this.messages,
      isTemporary: isTemporary,
      isComplete: isComplete ?? this.isComplete,
      extractedData: extractedData ?? this.extractedData,
    );
  }

  /// 生成智能标题（从首条用户消息）
  String generateSmartTitle() {
    final firstUserMessage = messages
        .where((m) => m.role == 'user')
        .firstOrNull;

    if (firstUserMessage?.content != null) {
      final content = firstUserMessage!.content!;
      // 取前20个字符作为标题
      return content.length > 20
          ? '${content.substring(0, 20)}...'
          : content;
    }

    return '新对话 ${createdAt.month}/${createdAt.day}';
  }

  /// 获取消息数量
  int get messageCount => messages.length;

  /// 获取用户消息数量
  int get userMessageCount => messages.where((m) => m.role == 'user').length;

  @override
  String toString() {
    return 'ConversationHistory(id: $id, title: $title, messages: ${messages.length}, isComplete: $isComplete)';
  }
}
