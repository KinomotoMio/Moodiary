import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/conversation_history.dart';
import '../services/conversational_record_service.dart';
import '../services/conversation_storage_service.dart';
import '../services/llm/tool_calling.dart';

/// 对话式心情记录界面
///
/// 通过与AI助手对话，引导用户自然地表达和记录心情
class ConversationalRecordScreen extends StatefulWidget {
  /// 会话ID（如果恢复已有会话）
  final String? conversationId;

  /// 是否为临时会话（退出后删除）
  final bool isTemporary;

  const ConversationalRecordScreen({
    super.key,
    this.conversationId,
    this.isTemporary = false,
  });

  @override
  State<ConversationalRecordScreen> createState() =>
      _ConversationalRecordScreenState();
}

class _ConversationalRecordScreenState
    extends State<ConversationalRecordScreen> {
  final ConversationalRecordService _service =
      ConversationalRecordService.instance;
  final ConversationStorageService _storage =
      ConversationStorageService.instance;

  late final ConversationSession _session;
  late ConversationHistory _conversationHistory;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isProcessing = false;
  bool _isComplete = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    _handleDispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  /// 初始化会话
  Future<void> _initializeConversation() async {
    setState(() => _isLoading = true);

    try {
      if (widget.conversationId != null) {
        // 加载已有会话
        final existingConversation = await _storage.getConversation(widget.conversationId!);
        if (existingConversation != null) {
          _conversationHistory = existingConversation;
          _session = _service.startNewSession();
          // 恢复会话消息
          for (final message in existingConversation.messages) {
            _session.addMessage(message);
          }
          _isComplete = existingConversation.isComplete;
        } else {
          // 会话不存在，创建新会话
          _createNewConversation();
        }
      } else {
        // 创建新会话
        _createNewConversation();
      }

      setState(() => _isLoading = false);

      // 如果是新会话，发送初始问候
      if (widget.conversationId == null) {
        _sendInitialGreeting();
      } else {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('初始化会话失败：$e');
      }
    }
  }

  /// 创建新会话
  void _createNewConversation() {
    _conversationHistory = ConversationHistory.create(
      isTemporary: widget.isTemporary,
    );
    _session = _service.startNewSession();
  }

  /// 处理退出
  Future<void> _handleDispose() async {
    if (widget.isTemporary) {
      // 临时会话：删除
      await _storage.deleteConversation(_conversationHistory.id);
    } else {
      // 非临时会话：保存
      await _saveConversation();
    }
  }

  /// 保存会话
  Future<void> _saveConversation() async {
    try {
      // 如果标题仍是"新对话"，生成智能标题
      String title = _conversationHistory.title;
      if (title == '新对话' && _session.messages.isNotEmpty) {
        title = _conversationHistory.copyWith(messages: _session.messages).generateSmartTitle();
      }

      final updatedConversation = _conversationHistory.copyWith(
        title: title,
        messages: _session.messages,
        isComplete: _isComplete,
        extractedData: _session.extractedData?.toJson(),
      );

      await _storage.saveConversation(updatedConversation);
      _conversationHistory = updatedConversation;
    } catch (e) {
      debugPrint('Failed to save conversation: $e');
    }
  }

  /// 发送初始问候
  Future<void> _sendInitialGreeting() async {
    setState(() => _isProcessing = true);

    try {
      final response = await _service.processMessage(
        session: _session,
        userMessage: '你好',
      );

      setState(() {
        _isProcessing = false;
        _isComplete = response.isComplete;
      });

      // 自动保存会话
      await _saveConversation();

      _scrollToBottom();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        _showError('初始化对话失败：$e');
      }
    }
  }

  /// 发送用户消息
  Future<void> _sendMessage() async {
    final userInput = _inputController.text.trim();
    if (userInput.isEmpty || _isProcessing || _isComplete) return;

    _inputController.clear();
    setState(() => _isProcessing = true);

    try {
      final response = await _service.processMessage(
        session: _session,
        userMessage: userInput,
      );

      setState(() {
        _isProcessing = false;
        _isComplete = response.isComplete;
      });

      // 自动保存会话
      await _saveConversation();

      _scrollToBottom();

      // 如果对话完成，显示成功提示并返回
      if (response.isComplete) {
        _showSuccess();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        _showError('发送消息失败：$e');
      }
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  /// 显示成功提示
  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('心情记录已保存！'),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );

    // 延迟返回上一页
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示成功保存
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversationId != null
            ? _conversationHistory.title
            : '对话记录心情'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (widget.isTemporary)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: const Text(
                  '临时',
                  style: TextStyle(fontSize: 12),
                ),
                backgroundColor: colorScheme.secondaryContainer,
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 对话历史区域
                Expanded(
                  child: _buildMessageList(colorScheme),
                ),

                // 输入区域
                _buildInputArea(theme, colorScheme),
              ],
            ),
    );
  }

  /// 构建消息列表
  Widget _buildMessageList(ColorScheme colorScheme) {
    // 过滤掉不应该显示的消息
    final displayMessages = _session.messages.where((msg) {
      // 不显示工具结果消息和系统消息
      return msg.role != 'tool' && msg.role != 'system';
    }).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: displayMessages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        // 显示加载指示器
        if (index == displayMessages.length) {
          return _buildLoadingIndicator();
        }

        final message = displayMessages[index];
        return _buildMessageBubble(message, colorScheme);
      },
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme) {
    final isUser = message.role == 'user';

    // 处理AI消息的显示内容
    String displayContent = message.content ?? '';
    Widget? toolCallIndicator;

    // 如果AI消息包含工具调用，显示工具调用状态
    if (!isUser && message.toolCalls != null && message.toolCalls!.isNotEmpty) {
      toolCallIndicator = _buildToolCallIndicator(message.toolCalls!, colorScheme);
    }

    // 如果既没有内容也没有工具调用，跳过这条消息
    if (displayContent.isEmpty && toolCallIndicator == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像（左侧）
          if (!isUser) _buildAvatar(colorScheme, isUser: false),

          const SizedBox(width: 8),

          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 工具调用指示器
                if (toolCallIndicator != null) ...[
                  toolCallIndicator,
                  const SizedBox(height: 8),
                ],

                // 消息气泡
                if (displayContent.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      displayContent,
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),

                // 时间戳
                if (displayContent.isNotEmpty || toolCallIndicator != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 用户头像（右侧）
          if (isUser) _buildAvatar(colorScheme, isUser: true),
        ],
      ),
    );
  }

  /// 构建工具调用指示器
  Widget _buildToolCallIndicator(List<ToolCall> toolCalls, ColorScheme colorScheme) {
    final toolNames = <String, String>{
      'search_history_records': '🔍 检索历史记录',
      'extract_mood_data': '📝 提取心情数据',
      'ask_clarifying_question': '💭 思考中',
      'save_mood_entry': '💾 保存记录',
      'suggest_topic_tags': '🏷️ 分析话题标签',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '已调用: ${toolCalls.map((t) => toolNames[t.name] ?? t.name).join('、')}',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(ColorScheme colorScheme, {required bool isUser}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isUser ? colorScheme.primary : colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        color: isUser ? colorScheme.onPrimary : colorScheme.onSecondary,
        size: 20,
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAvatar(Theme.of(context).colorScheme, isUser: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(timestamp);
    } else {
      return DateFormat('MM-dd HH:mm').format(timestamp);
    }
  }

  /// 构建输入区域
  Widget _buildInputArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
                    if (event.logicalKey == LogicalKeyboardKey.enter && !isShiftPressed) {
                      _sendMessage();
                      return KeyEventResult.handled; // 阻止默认行为
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  enabled: !_isProcessing && !_isComplete,
                  decoration: InputDecoration(
                    hintText: _isComplete ? '对话已完成' : '输入你的想法... (Shift+Enter换行)',
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
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // 发送按钮
            IconButton.filled(
              onPressed: (_isProcessing || _isComplete) ? null : _sendMessage,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              tooltip: '发送',
            ),
          ],
        ),
      ),
    );
  }
}
