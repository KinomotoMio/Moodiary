import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_history.dart';
import '../events/app_events.dart';
import 'storage_service.dart';

/// 会话存储服务
///
/// 管理对话会话的持久化存储和检索
class ConversationStorageService {
  static ConversationStorageService? _instance;
  static ConversationStorageService get instance =>
      _instance ??= ConversationStorageService._();

  ConversationStorageService._();

  static const String _conversationsKey = 'conversations_history';

  /// 保存会话
  Future<void> saveConversation(ConversationHistory conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getAllConversations();

      // 查找现有会话并更新，或添加新会话
      final index = conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        conversations[index] = conversation;
      } else {
        conversations.insert(0, conversation); // 新会话插入到最前面
      }

      // 序列化并保存
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(jsonList));

      // 触发会话数据变更事件
      StorageService.eventBus.fire(ConversationDataChangedEvent());

      if (kDebugMode) {
        debugPrint('Saved conversation: ${conversation.id} (${conversation.title})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save conversation: $e');
      }
      rethrow;
    }
  }

  /// 获取所有会话（非临时）
  Future<List<ConversationHistory>> getAllConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);

      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final conversations = jsonList
          .map((json) => ConversationHistory.fromJson(json as Map<String, dynamic>))
          .where((c) => !c.isTemporary) // 过滤掉临时会话
          .toList();

      // 按最后更新时间排序（最新的在前）
      conversations.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));

      return conversations;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load conversations: $e');
      }
      return [];
    }
  }

  /// 获取单个会话
  Future<ConversationHistory?> getConversation(String id) async {
    final conversations = await getAllConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 删除会话
  Future<void> deleteConversation(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversations = await getAllConversations();

      conversations.removeWhere((c) => c.id == id);

      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(jsonList));

      // 触发会话数据变更事件
      StorageService.eventBus.fire(ConversationDataChangedEvent());

      if (kDebugMode) {
        debugPrint('Deleted conversation: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to delete conversation: $e');
      }
      rethrow;
    }
  }

  /// 搜索会话
  Future<List<ConversationHistory>> searchConversations(String query) async {
    if (query.trim().isEmpty) {
      return getAllConversations();
    }

    final conversations = await getAllConversations();
    final lowerQuery = query.toLowerCase();

    return conversations.where((c) {
      // 搜索标题
      if (c.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 搜索消息内容
      return c.messages.any((m) =>
          m.content?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 清理临时会话
  Future<void> cleanupTemporaryConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);

      if (jsonString == null) return;

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final conversations = jsonList
          .map((json) => ConversationHistory.fromJson(json as Map<String, dynamic>))
          .where((c) => !c.isTemporary) // 只保留非临时会话
          .toList();

      final jsonListFiltered = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(jsonListFiltered));

      if (kDebugMode) {
        debugPrint('Cleaned up temporary conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to cleanup temporary conversations: $e');
      }
    }
  }

  /// 获取会话统计
  Future<Map<String, int>> getStatistics() async {
    final conversations = await getAllConversations();

    return {
      'total': conversations.length,
      'completed': conversations.where((c) => c.isComplete).length,
      'active': conversations.where((c) => !c.isComplete).length,
    };
  }
}
