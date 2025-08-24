import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../services/fragment_storage_service.dart';
import '../widgets/highlighted_text.dart';
import '../screens/mood_detail_screen.dart';

class TagDetailBottomSheet extends StatefulWidget {
  final TopicTag initialTag;
  final List<TopicTag> allTags;

  const TagDetailBottomSheet({
    super.key,
    required this.initialTag,
    required this.allTags,
  });

  @override
  State<TagDetailBottomSheet> createState() => _TagDetailBottomSheetState();
}

class _TagDetailBottomSheetState extends State<TagDetailBottomSheet> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final List<TopicTag> _navigationStack = [];
  List<MoodFragment> _currentFragments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化导航栈
    _navigationStack.add(widget.initialTag);
    _loadFragmentsForCurrentTag();
  }

  TopicTag get _currentTag => _navigationStack.last;
  bool get _canGoBack => _navigationStack.length > 1;

  Future<void> _loadFragmentsForCurrentTag() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentFragments = await _fragmentStorage.getFragmentsByTopicTag(_currentTag.name);
    } catch (e) {
      debugPrint('Error loading fragments for tag ${_currentTag.name}: $e');
      _currentFragments = [];
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 导航到新标签
  void _navigateToTag(String tagName) {
    final tag = widget.allTags.firstWhere(
      (t) => t.name == tagName,
      orElse: () => TopicTag(name: tagName, firstUsed: DateTime.now(), usageCount: 0),
    );
    
    setState(() {
      _navigationStack.add(tag);
    });
    _loadFragmentsForCurrentTag();
  }

  // 返回上一个标签
  void _goBack() {
    if (_canGoBack) {
      setState(() {
        _navigationStack.removeLast();
      });
      _loadFragmentsForCurrentTag();
    }
  }

  // 导航到心情详情页面
  void _navigateToMoodDetail(MoodFragment fragment) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          MoodDetailScreen(entry: fragment.toMoodEntry()),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 从右滑入动画效果
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    // 如果记录被编辑或删除，刷新当前标签的内容
    if (result == true && mounted) {
      await _loadFragmentsForCurrentTag();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: kIsWeb ? 0.8 : 0.7, // Web端显示更大
      maxChildSize: 0.95,
      minChildSize: kIsWeb ? 0.5 : 0.4, // Web端最小高度调整
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 拖拽指示器和标题栏
            _buildHeader(),
            
            // 内容区域
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            width: kIsWeb ? 60 : 40, // Web端更宽的指示器
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Row(
            children: [
              // 返回按钮
              if (_canGoBack)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: _goBack,
                    tooltip: '返回 #${_navigationStack[_navigationStack.length - 2].name}',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              
              if (_canGoBack) const SizedBox(width: 12),
              
              // 当前标签芯片
              Chip(
                label: Text(_currentTag.name),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                avatar: Icon(
                  Icons.tag,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              
              const Spacer(),
              
              // 记录数量
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentFragments.length} 条记录',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // Web端关闭按钮
              if (kIsWeb) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_currentFragments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      itemCount: _currentFragments.length,
      itemBuilder: (context, index) {
        final fragment = _currentFragments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shadowColor: _getMoodColor(fragment.mood).withValues(alpha: 0.2),
            child: InkWell(
              onTap: () => _navigateToMoodDetail(fragment),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 情绪图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getMoodColor(fragment.mood).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getMoodColor(fragment.mood).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              fragment.mood.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // 时间和状态指示器
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDateTime(fragment.timestamp),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (fragment.hasMedia) 
                                    Icon(
                                      Icons.photo_outlined, 
                                      size: 14,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  if (fragment.hasMedia && fragment.hasTopicTags)
                                    const SizedBox(width: 4),
                                  if (fragment.hasTopicTags)
                                    Icon(
                                      Icons.tag, 
                                      size: 14, 
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 内容文本
                    if (fragment.textContent != null && fragment.textContent!.isNotEmpty)
                      HighlightedText(
                        text: fragment.textContent!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                        onTagTap: (tagName) => _navigateToTag(tagName),
                      )
                    else
                      Text(
                        '仅图片记录',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_neutral,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '这个标签暂无记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '可能记录已被删除或标签已被修改',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
      final weekday = weekdays[dateTime.weekday - 1];
      return '周$weekday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}月${dateTime.day}日 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.positive:
        return const Color(0xFF4CAF50);
      case MoodType.negative:
        return const Color(0xFFFF5722);
      case MoodType.neutral:
        return const Color(0xFF607D8B);
    }
  }
}