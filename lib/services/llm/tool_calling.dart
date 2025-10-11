import 'dart:convert';

/// LLM Tool Calling 基础模型
///
/// 实现OpenAI兼容的Function Calling规范
/// 支持DeepSeek、通义千问等兼容OpenAI API的模型

/// 工具函数定义
class ToolFunction {
  /// 函数名称
  final String name;

  /// 函数描述（用于LLM理解何时调用）
  final String description;

  /// 参数schema（JSON Schema格式）
  final Map<String, dynamic> parameters;

  const ToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };
}

/// 工具调用请求（LLM返回的调用指令）
class ToolCall {
  /// 调用ID（用于追踪）
  final String id;

  /// 函数名称
  final String name;

  /// 函数参数（JSON字符串）
  final String arguments;

  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  /// 从LLM响应解析
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      name: json['function']['name'] as String,
      arguments: json['function']['arguments'] as String,
    );
  }

  /// 解析参数为Map
  Map<String, dynamic> parseArguments() {
    try {
      return jsonDecode(arguments) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}

/// 工具调用结果
class ToolResult {
  /// 对应的调用ID
  final String toolCallId;

  /// 函数名称
  final String name;

  /// 执行结果（序列化为JSON字符串）
  final String content;

  const ToolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'role': 'tool',
        'tool_call_id': toolCallId,
        'name': name,
        'content': content,
      };
}

/// 对话消息
class ChatMessage {
  /// 角色：system, user, assistant, tool
  final String role;

  /// 消息内容
  final String? content;

  /// 工具调用（assistant发起）
  final List<ToolCall>? toolCalls;

  /// 工具调用ID（tool消息关联）
  final String? toolCallId;

  /// 函数名称（tool消息）
  final String? name;

  /// 消息时间戳
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 创建用户消息
  factory ChatMessage.user(String content) {
    return ChatMessage(role: 'user', content: content);
  }

  /// 创建助手消息
  factory ChatMessage.assistant(String content) {
    return ChatMessage(role: 'assistant', content: content);
  }

  /// 创建系统消息
  factory ChatMessage.system(String content) {
    return ChatMessage(role: 'system', content: content);
  }

  /// 创建工具调用消息
  factory ChatMessage.assistantWithToolCalls(List<ToolCall> toolCalls) {
    return ChatMessage(role: 'assistant', toolCalls: toolCalls);
  }

  /// 创建工具结果消息
  factory ChatMessage.toolResult(ToolResult result) {
    return ChatMessage(
      role: 'tool',
      content: result.content,
      toolCallId: result.toolCallId,
      name: result.name,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'role': role};

    if (content != null) {
      json['content'] = content;
    }

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      json['tool_calls'] = toolCalls!.map((tc) => {
        'id': tc.id,
        'type': 'function',
        'function': {
          'name': tc.name,
          'arguments': tc.arguments,
        },
      }).toList();
    }

    if (toolCallId != null) {
      json['tool_call_id'] = toolCallId;
    }

    if (name != null) {
      json['name'] = name;
    }

    return json;
  }

  /// 从JSON解析
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    final content = json['content'] as String?;

    List<ToolCall>? toolCalls;
    if (json.containsKey('tool_calls')) {
      final calls = json['tool_calls'] as List;
      toolCalls = calls.map((c) => ToolCall.fromJson(c as Map<String, dynamic>)).toList();
    }

    return ChatMessage(
      role: role,
      content: content,
      toolCalls: toolCalls,
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
    );
  }
}

/// 对话式记录专用工具集
class ConversationalTools {
  /// 检索历史记录工具
  static final searchHistoryRecords = ToolFunction(
    name: 'search_history_records',
    description: '检索用户的历史心情记录。'
        '当用户询问"最近发生了什么"、"我之前记录过什么"、"帮我回忆一下"等问题时使用。'
        '支持按关键词、情绪类型、日期范围搜索。',
    parameters: {
      'type': 'object',
      'properties': {
        'keywords': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': '搜索关键词列表，从用户问题中提取（如：工作、朋友、运动等）',
        },
        'mood_type': {
          'type': 'string',
          'enum': ['positive', 'neutral', 'negative', 'all'],
          'description': '筛选的情绪类型，默认为all（全部）',
        },
        'days_ago': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 365,
          'description': '搜索最近多少天的记录，默认30天',
        },
        'limit': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 20,
          'description': '返回结果的最大数量，默认5条',
        },
      },
      'required': [],
    },
  );

  /// 提取心情数据工具
  static final extractMoodData = ToolFunction(
    name: 'extract_mood_data',
    description: '从用户的对话中提取结构化的心情数据。'
        '当用户描述了自己的心情、情绪或发生的事情时调用此函数。'
        '注意：只有在用户提供了足够信息时才调用，不要过早调用。',
    parameters: {
      'type': 'object',
      'properties': {
        'mood_type': {
          'type': 'string',
          'enum': ['positive', 'neutral', 'negative'],
          'description': '情绪类型：positive（积极）、neutral（中性）、negative（消极）',
        },
        'emotion_score': {
          'type': 'integer',
          'minimum': 0,
          'maximum': 100,
          'description': '情绪评分，0-100，越高越积极',
        },
        'content': {
          'type': 'string',
          'description': '心情记录的文字内容，整理用户的描述',
        },
        'topic_tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': '话题标签列表，例如：["工作", "朋友", "运动"]',
        },
      },
      'required': ['mood_type', 'emotion_score', 'content'],
    },
  );

  /// 询问澄清问题工具
  static final askClarifyingQuestion = ToolFunction(
    name: 'ask_clarifying_question',
    description: '当需要更多信息来理解用户心情时，询问澄清性问题。'
        '用于引导用户提供更多细节，帮助建立完整的心情记录。',
    parameters: {
      'type': 'object',
      'properties': {
        'question': {
          'type': 'string',
          'description': '要问用户的问题',
        },
        'reason': {
          'type': 'string',
          'description': '为什么需要这个信息（内部使用，不展示给用户）',
        },
      },
      'required': ['question'],
    },
  );

  /// 保存心情记录工具
  static final saveMoodEntry = ToolFunction(
    name: 'save_mood_entry',
    description: '保存完整的心情记录。'
        '只有在已经提取了足够的心情数据，并且用户确认满意时调用。'
        '这是对话的最后一步。',
    parameters: {
      'type': 'object',
      'properties': {
        'confirm_message': {
          'type': 'string',
          'description': '向用户确认保存的消息',
        },
      },
      'required': ['confirm_message'],
    },
  );

  /// 建议话题标签工具
  static final suggestTopicTags = ToolFunction(
    name: 'suggest_topic_tags',
    description: '基于对话内容建议相关的话题标签。'
        '当识别到关键主题或活动时调用，帮助用户更好地组织记录。',
    parameters: {
      'type': 'object',
      'properties': {
        'suggested_tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'description': '建议的标签列表',
        },
        'explanation': {
          'type': 'string',
          'description': '为什么建议这些标签',
        },
      },
      'required': ['suggested_tags'],
    },
  );

  /// 获取所有工具定义
  static List<ToolFunction> getAllTools() => [
        searchHistoryRecords,
        extractMoodData,
        askClarifyingQuestion,
        saveMoodEntry,
        suggestTopicTags,
      ];

  /// 获取工具定义的JSON列表（用于API请求）
  static List<Map<String, dynamic>> getToolsJson() =>
      getAllTools().map((tool) => tool.toJson()).toList();
}
