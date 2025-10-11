import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation_history.dart';
import '../services/conversation_storage_service.dart';
import '../services/storage_service.dart';
import '../events/app_events.dart';
import 'conversational_record_screen.dart';

/// 会话历史列表界面
///
/// 显示所有保存的对话会话，支持搜索、删除等操作
class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final ConversationStorageService _storage =
      ConversationStorageService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<ConversationHistory> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // 事件监听
  late StreamSubscription _conversationDataSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
    _loadConversations();
  }

  // 设置事件监听器
  void _setupEventListeners() {
    _conversationDataSubscription = StorageService.eventBus
        .on<ConversationDataChangedEvent>()
        .listen((event) {
      // 当会话数据发生变化时，重新加载数据
      if (mounted) {
        _loadConversations();
      }
    });
  }

  @override
  void dispose() {
    _conversationDataSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

    try {
      final conversations = _searchQuery.isEmpty
          ? await _storage.getAllConversations()
          : await _storage.searchConversations(_searchQuery);

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadConversations();
  }

  Future<void> _deleteConversation(ConversationHistory conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定要删除会话"${conversation.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storage.deleteConversation(conversation.id);
      _loadConversations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('会话已删除')),
        );
      }
    }
  }

  Future<void> _editConversationTitle(ConversationHistory conversation) async {
    final controller = TextEditingController(text: conversation.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改标题'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新标题',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newTitle != null && newTitle != conversation.title) {
      // 更新标题
      final updatedConversation = conversation.copyWith(title: newTitle);
      await _storage.saveConversation(updatedConversation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标题已更新')),
        );
      }
    }
  }

  void _openConversation(ConversationHistory conversation) async {
    // 导航到对话界面，加载选中的会话
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConversationalRecordScreen(
          conversationId: conversation.id,
          isTemporary: false,
        ),
      ),
    );

    // 对话界面返回后，数据已经通过事件自动更新了
    // 但如果用户删除了当前会话，这里可以做额外处理
    if (result == true && mounted) {
      // 可选：显示提示或执行其他操作
    }
  }

  void _createNewConversation({bool isTemporary = false}) async {
    // 创建新会话时，直接导航
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ConversationalRecordScreen(
          conversationId: null,
          isTemporary: isTemporary,
        ),
      ),
    );

    if (result == true) {
      _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('对话历史'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索会话...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // 会话列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return _buildConversationCard(
                            conversation,
                            colorScheme,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 新建临时会话
          FloatingActionButton.small(
            heroTag: 'temp',
            onPressed: () => _createNewConversation(isTemporary: true),
            tooltip: '临时会话',
            child: const Icon(Icons.chat_bubble_outline),
          ),
          const SizedBox(height: 8),
          // 新建普通会话
          FloatingActionButton(
            heroTag: 'new',
            onPressed: () => _createNewConversation(),
            tooltip: '新建会话',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '还没有对话记录' : '没有找到匹配的会话',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '点击右下角按钮开始新对话' : '试试其他关键词',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(
    ConversationHistory conversation,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openConversation(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 状态图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: conversation.isComplete
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  conversation.isComplete
                      ? Icons.check_circle
                      : Icons.chat_bubble,
                  color: conversation.isComplete
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ),

              const SizedBox(width: 16),

              // 会话信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${conversation.userMessageCount}条消息 · ${_formatDate(conversation.lastUpdatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // 编辑按钮
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editConversationTitle(conversation),
                tooltip: '编辑标题',
              ),

              // 删除按钮
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteConversation(conversation),
                tooltip: '删除',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('MM-dd').format(dateTime);
    }
  }
}
