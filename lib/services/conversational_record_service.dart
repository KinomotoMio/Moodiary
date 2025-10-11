import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import 'fragment_storage_service.dart';
import 'storage_service.dart';
import '../events/app_events.dart';
import 'llm/llm_client.dart';
import 'llm/tool_calling.dart';
import 'llm/providers/base_llm_provider.dart';
import 'settings_service.dart';

/// 对话式记录服务
///
/// 通过AI对话引导用户记录心情：
/// 1. 理解用户自然语言输入
/// 2. 智能提问澄清细节
/// 3. 提取结构化心情数据
/// 4. 保存为完整的MoodEntry
class ConversationalRecordService {
  static ConversationalRecordService? _instance;
  static ConversationalRecordService get instance =>
      _instance ??= ConversationalRecordService._();

  ConversationalRecordService._();

  // 依赖服务
  final FragmentStorageService _fragmentStorage =
      FragmentStorageService.instance;
  final LLMClient _llmClient = LLMClient.instance;
  final SettingsService _settingsService = SettingsService.instance;

  // 系统提示词
  static const String _systemPrompt = '''你是Moodiary的AI助手，专门帮助用户记录心情。

**你的角色**：
- 温暖、共情、非评判性
- 善于倾听和提问
- 帮助用户表达和整理情绪

**对话流程**：
1. 当用户开始描述心情时，耐心倾听
2. 如果信息不足，使用ask_clarifying_question工具询问细节（如：具体发生了什么？你现在感觉如何？）
3. 当你收集到足够信息后，使用extract_mood_data工具提取数据
4. 提取后，向用户确认信息是否准确
5. 用户确认后，使用save_mood_entry工具保存

**重要原则**：
- 不要过早调用工具，先建立对话
- 不要一次问太多问题
- 识别用户文字中的关键词作为话题标签
- 根据内容准确评估情绪类型和评分

**情绪评分标准（0-100分制）**：
- **0-49分：消极情绪区间**
  * 0-24分：极度消极（沮丧、绝望、痛苦）
  * 25-37分：较为消极（难过、焦虑、低落）
  * 38-49分：轻微消极（有些烦躁、疲惫、不满）

- **50分：中性情绪**
  * 完全中性，没有明显的积极或消极倾向

- **51-100分：积极情绪区间**
  * 51-62分：轻微积极（平和、还不错、有点开心）
  * 63-80分：较为积极（愉悦、满意、开心）
  * 81-100分：极度积极（兴奋、狂喜、特别满足）

**评分与情绪类型必须一致**：
- negative → 0-49分
- neutral → 正好50分
- positive → 51-100分

开始对话时，用温暖的语气打招呼。''';

  /// 开始新的对话会话
  ConversationSession startNewSession() {
    return ConversationSession();
  }

  /// 处理用户消息，返回AI回复
  ///
  /// [session] 当前对话会话
  /// [userMessage] 用户输入的消息
  ///
  /// 返回AI的回复和可能的工具调用结果
  Future<ConversationResponse> processMessage({
    required ConversationSession session,
    required String userMessage,
  }) async {
    // 添加用户消息到历史
    session.addUserMessage(userMessage);

    // 获取LLM配置
    final settings = _settingsService.currentSettings;
    final providerName = settings.llmProvider ?? 'siliconflow';
    final apiKey = settings.llmApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('LLM API key not configured');
    }

    // 准备对话历史（包含系统提示）
    final messages = [
      ChatMessage.system(_systemPrompt).toJson(),
      ...session.messages.map((m) => m.toJson()),
    ];

    if (kDebugMode) {
      debugPrint('=== Sending to LLM ===');
      debugPrint('Total messages: ${messages.length}');
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        debugPrint('[$i] ${msg['role']}: ${msg['content']?.toString().substring(0, msg['content'].toString().length > 100 ? 100 : msg['content'].toString().length) ?? '(tool_calls)'}');
      }
    }

    // 调用LLM（带工具）
    try {
      final response = await _llmClient.generateChatWithTools(
        providerName: providerName,
        messages: messages,
        tools: ConversationalTools.getToolsJson(),
        apiKey: apiKey,
        parameters: {
          'temperature': 0.8, // 稍高的temperature让对话更自然
          'max_tokens': 800,
        },
      );

      // 解析响应
      final assistantMessage = ChatMessage.fromJson(response);
      session.addMessage(assistantMessage);

      // 检查是否有工具调用
      if (assistantMessage.toolCalls != null &&
          assistantMessage.toolCalls!.isNotEmpty) {
        // 执行工具调用
        final toolResults = await _executeToolCalls(
          session: session,
          toolCalls: assistantMessage.toolCalls!,
        );

        // 将工具结果添加到会话
        for (final result in toolResults) {
          session.addMessage(ChatMessage.toolResult(result));
        }

        // 如果有工具调用，需要再次请求LLM获取最终回复
        final followUpMessages = [
          ChatMessage.system(_systemPrompt).toJson(),
          ...session.messages.map((m) => m.toJson()),
        ];

        final followUpResponse = await _llmClient.generateChatWithTools(
          providerName: providerName,
          messages: followUpMessages,
          tools: ConversationalTools.getToolsJson(),
          apiKey: apiKey,
          parameters: {
            'temperature': 0.8,
            'max_tokens': 800,
          },
        );

        final followUpMessage = ChatMessage.fromJson(followUpResponse);
        session.addMessage(followUpMessage);

        return ConversationResponse(
          message: followUpMessage.content ?? '',
          toolCallResults: toolResults,
          isComplete: session.isComplete,
        );
      }

      // 没有工具调用，直接返回助手回复
      return ConversationResponse(
        message: assistantMessage.content ?? '',
        toolCallResults: [],
        isComplete: session.isComplete,
      );
    } on LLMException catch (e) {
      if (kDebugMode) {
        debugPrint('Conversational LLM call failed: $e');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error in conversation: $e');
      }
      rethrow;
    }
  }

  /// 执行工具调用
  Future<List<ToolResult>> _executeToolCalls({
    required ConversationSession session,
    required List<ToolCall> toolCalls,
  }) async {
    final results = <ToolResult>[];

    for (final toolCall in toolCalls) {
      if (kDebugMode) {
        debugPrint('Executing tool: ${toolCall.name}');
        debugPrint('Arguments: ${toolCall.arguments}');
      }

      try {
        final args = toolCall.parseArguments();
        String resultContent;

        switch (toolCall.name) {
          case 'search_history_records':
            resultContent = await _handleSearchHistoryRecords(session, args);
            break;

          case 'extract_mood_data':
            resultContent = await _handleExtractMoodData(session, args);
            break;

          case 'ask_clarifying_question':
            resultContent = _handleAskClarifyingQuestion(args);
            break;

          case 'save_mood_entry':
            resultContent = await _handleSaveMoodEntry(session, args);
            break;

          case 'suggest_topic_tags':
            resultContent = _handleSuggestTopicTags(args);
            break;

          default:
            resultContent = jsonEncode({'error': 'Unknown tool: ${toolCall.name}'});
        }

        results.add(ToolResult(
          toolCallId: toolCall.id,
          name: toolCall.name,
          content: resultContent,
        ));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Tool execution failed: ${toolCall.name} - $e');
        }
        results.add(ToolResult(
          toolCallId: toolCall.id,
          name: toolCall.name,
          content: jsonEncode({'error': e.toString()}),
        ));
      }
    }

    return results;
  }

  /// 处理检索历史记录
  Future<String> _handleSearchHistoryRecords(
    ConversationSession session,
    Map<String, dynamic> args,
  ) async {
    try {
      // 解析参数
      final keywordsList = args['keywords'] as List?;
      final keywords = keywordsList?.map((k) => k.toString()).toList() ?? [];
      final moodTypeStr = args['mood_type'] as String? ?? 'all';
      final daysAgo = args['days_ago'] as int? ?? 30;
      final limit = args['limit'] as int? ?? 5;

      // 获取所有记录
      final allFragments = await _fragmentStorage.getAllFragments();

      // 计算日期范围
      final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo));

      // 过滤记录
      var filteredFragments = allFragments.where((fragment) {
        // 日期过滤
        if (fragment.timestamp.isBefore(cutoffDate)) {
          return false;
        }

        // 情绪类型过滤
        if (moodTypeStr != 'all') {
          MoodType targetType;
          switch (moodTypeStr) {
            case 'positive':
              targetType = MoodType.positive;
              break;
            case 'negative':
              targetType = MoodType.negative;
              break;
            case 'neutral':
              targetType = MoodType.neutral;
              break;
            default:
              targetType = MoodType.neutral;
          }
          if (fragment.mood != targetType) {
            return false;
          }
        }

        // 关键词过滤（如果提供了关键词）
        if (keywords.isNotEmpty) {
          final content = (fragment.textContent ?? '').toLowerCase();
          final tags = fragment.topicTags.map((t) => t.toLowerCase()).toList();

          return keywords.any((keyword) {
            final lowerKeyword = keyword.toLowerCase();
            return content.contains(lowerKeyword) || tags.contains(lowerKeyword);
          });
        }

        return true;
      }).toList();

      // 限制结果数量
      if (filteredFragments.length > limit) {
        filteredFragments = filteredFragments.take(limit).toList();
      }

      // 格式化结果
      final results = filteredFragments.map((fragment) {
        return {
          'date': fragment.timestamp.toString().split('.')[0],
          'mood_type': fragment.mood.name,
          'score': fragment.emotionScore,
          'content': fragment.textContent ?? '',
          'tags': fragment.topicTags,
        };
      }).toList();

      if (kDebugMode) {
        debugPrint('Found ${results.length} records matching criteria');
      }

      return jsonEncode({
        'success': true,
        'count': results.length,
        'records': results,
        'search_params': {
          'keywords': keywords,
          'mood_type': moodTypeStr,
          'days_ago': daysAgo,
        },
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to search history records: $e');
      }

      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 处理提取心情数据
  Future<String> _handleExtractMoodData(
    ConversationSession session,
    Map<String, dynamic> args,
  ) async {
    final moodTypeStr = args['mood_type'] as String;
    final emotionScore = args['emotion_score'] as int;
    final content = args['content'] as String;
    final topicTagsList = args['topic_tags'] as List?;

    // 解析情绪类型
    MoodType moodType;
    switch (moodTypeStr) {
      case 'positive':
        moodType = MoodType.positive;
        break;
      case 'negative':
        moodType = MoodType.negative;
        break;
      default:
        moodType = MoodType.neutral;
    }

    // 验证评分与情绪类型的一致性
    if (moodType == MoodType.positive && emotionScore <= 50) {
      return jsonEncode({
        'success': false,
        'error': 'Positive mood must have score > 50',
      });
    }
    if (moodType == MoodType.negative && emotionScore >= 50) {
      return jsonEncode({
        'success': false,
        'error': 'Negative mood must have score < 50',
      });
    }
    if (moodType == MoodType.neutral && emotionScore != 50) {
      return jsonEncode({
        'success': false,
        'error': 'Neutral mood should have score = 50',
      });
    }

    // 解析标签
    final topicTags = topicTagsList?.map((t) => t.toString()).toList() ?? [];

    // 保存到会话
    session.extractedData = ExtractedMoodData(
      moodType: moodType,
      emotionScore: emotionScore,
      content: content,
      topicTags: topicTags,
    );

    if (kDebugMode) {
      debugPrint('Extracted mood data: $moodType, score: $emotionScore');
      debugPrint('Tags: $topicTags');
    }

    return jsonEncode({
      'success': true,
      'message': 'Mood data extracted successfully',
    });
  }

  /// 处理询问澄清问题
  String _handleAskClarifyingQuestion(Map<String, dynamic> args) {
    final question = args['question'] as String;

    if (kDebugMode) {
      debugPrint('AI asking question: $question');
    }

    return jsonEncode({
      'success': true,
      'question': question,
    });
  }

  /// 处理保存心情记录
  Future<String> _handleSaveMoodEntry(
    ConversationSession session,
    Map<String, dynamic> args,
  ) async {
    if (session.extractedData == null) {
      return jsonEncode({
        'success': false,
        'error': 'No mood data to save',
      });
    }

    final data = session.extractedData!;

    // 创建MoodEntry
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: data.content,
      timestamp: DateTime.now(),
      mood: data.moodType,
      emotionScore: data.emotionScore,
    );

    // 保存到存储
    try {
      await _fragmentStorage.saveMoodEntry(entry);

      // 触发数据刷新事件
      StorageService.eventBus.fire(MoodDataChangedEvent());

      // 标记会话完成
      session.isComplete = true;

      if (kDebugMode) {
        debugPrint('Mood entry saved: ${entry.id}');
        debugPrint('Data refresh event fired');
      }

      return jsonEncode({
        'success': true,
        'entry_id': entry.id,
        'message': 'Mood entry saved successfully',
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save mood entry: $e');
      }

      return jsonEncode({
        'success': false,
        'error': e.toString(),
      });
    }
  }

  /// 处理建议话题标签
  String _handleSuggestTopicTags(Map<String, dynamic> args) {
    final suggestedTags = (args['suggested_tags'] as List?)
            ?.map((t) => t.toString())
            .toList() ??
        [];

    if (kDebugMode) {
      debugPrint('Suggested tags: $suggestedTags');
    }

    return jsonEncode({
      'success': true,
      'tags': suggestedTags,
    });
  }
}

/// 对话会话
class ConversationSession {
  /// 对话消息历史
  final List<ChatMessage> messages = [];

  /// 提取的心情数据
  ExtractedMoodData? extractedData;

  /// 会话是否完成（已保存记录）
  bool isComplete = false;

  /// 添加用户消息
  void addUserMessage(String content) {
    messages.add(ChatMessage.user(content));
  }

  /// 添加消息
  void addMessage(ChatMessage message) {
    messages.add(message);
  }
}

/// 提取的心情数据
class ExtractedMoodData {
  final MoodType moodType;
  final int emotionScore;
  final String content;
  final List<String> topicTags;

  const ExtractedMoodData({
    required this.moodType,
    required this.emotionScore,
    required this.content,
    required this.topicTags,
  });
}

/// 对话响应
class ConversationResponse {
  /// AI的回复消息
  final String message;

  /// 工具调用结果
  final List<ToolResult> toolCallResults;

  /// 会话是否完成
  final bool isComplete;

  const ConversationResponse({
    required this.message,
    required this.toolCallResults,
    required this.isComplete,
  });
}
