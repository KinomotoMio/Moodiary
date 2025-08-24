import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../services/fragment_storage_service.dart';
import '../events/app_events.dart';
import '../services/storage_service.dart';
import '../widgets/highlighted_text.dart';
import '../screens/mood_detail_screen.dart';

class TopicTagsScreen extends StatefulWidget {
  final String? initialSearchQuery;
  
  const TopicTagsScreen({
    super.key,
    this.initialSearchQuery,
  });

  @override
  State<TopicTagsScreen> createState() => _TopicTagsScreenState();
}

class _TopicTagsScreenState extends State<TopicTagsScreen> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<TopicTag> _topicTags = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // 事件监听
  late StreamSubscription _moodDataSubscription;

  @override
  void initState() {
    super.initState();
    
    // 设置初始搜索查询
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
    
    _setupEventListeners();
    _loadData();
  }
  
  void _setupEventListeners() {
    _moodDataSubscription = StorageService.eventBus.on<MoodDataChangedEvent>().listen((event) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _moodDataSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _topicTags = await _fragmentStorage.getAllTopicTags();
    } catch (e) {
      debugPrint('Error loading topic tags: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<TopicTag> get _filteredTags {
    if (_searchQuery.isEmpty) return _topicTags;
    
    return _topicTags.where((tag) {
      return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // 临时：重建标签统计的方法
  Future<void> _rebuildTagsStatistics() async {
    try {
      await _fragmentStorage.rebuildTopicTagsStatistics();
      await _loadData(); // 重新加载数据
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('标签统计已重建完成！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重建标签统计失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('话题标签'),
        elevation: 0,
        actions: [
          // 临时：重建标签统计按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rebuildTagsStatistics,
            tooltip: '重建标签统计',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索话题标签...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final filteredTags = _filteredTags;
    
    if (filteredTags.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // 统计信息
          SliverToBoxAdapter(
            child: _buildStatisticsCard(),
          ),
          
          // 标签云视图
          SliverToBoxAdapter(
            child: _buildTagCloudCard(),
          ),
          
          // 标签列表
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '所有标签 (${filteredTags.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tag = filteredTags[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: _buildTagListItem(tag),
                );
              },
              childCount: filteredTags.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? '没有找到匹配的标签' : '还没有话题标签',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty 
                ? '尝试调整搜索关键词'
                : '在记录心情时使用 #标签 来创建话题分类\n例如：#工作 #心情 #生活',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalTags = _topicTags.length;
    final totalUsage = _topicTags.fold(0, (sum, tag) => sum + tag.usageCount);
    final averageUsage = totalTags > 0 ? totalUsage / totalTags : 0.0;

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '标签统计',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('总标签', '$totalTags', Icons.tag_outlined),
                  ),
                  Expanded(
                    child: _buildStatItem('总使用', '$totalUsage次', Icons.trending_up_outlined),
                  ),
                  Expanded(
                    child: _buildStatItem('平均使用', '${averageUsage.toStringAsFixed(1)}次', Icons.analytics_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTagCloudCard() {
    if (_topicTags.isEmpty) return const SizedBox();
    
    // 获取使用频率前10的标签用于标签云
    final popularTags = _topicTags.take(10).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '热门标签',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: popularTags.map((tag) {
                  final maxUsage = _topicTags.first.usageCount;
                  final size = 12.0 + (tag.usageCount / maxUsage) * 8.0;
                  
                  return GestureDetector(
                    onTap: () => _showTagDetails(tag),
                    child: Chip(
                      label: Text(
                        '#${tag.name}',
                        style: TextStyle(fontSize: size),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(
                        alpha: 0.3 + (tag.usageCount / maxUsage) * 0.7,
                      ),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagListItem(TopicTag tag) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.tag,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text('#${tag.name}'),
        subtitle: Text('使用 ${tag.usageCount} 次 • 首次使用: ${_formatDate(tag.firstUsed)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tag.usageCount}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _showTagDetails(tag),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showTagDetails(TopicTag tag) async {
    final fragments = await _fragmentStorage.getFragmentsByTopicTag(tag.name);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 拖拽指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Chip(
                    label: Text('#${tag.name}'),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const Spacer(),
                  Text(
                    '${fragments.length} 条记录',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 记录列表
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                itemCount: fragments.length,
                itemBuilder: (context, index) {
                  final fragment = fragments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: fragment.textContent != null && fragment.textContent!.isNotEmpty
                        ? HighlightedText(
                            text: fragment.textContent!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            onTagTap: (tagName) => _onTagTapInModal(tagName),
                          )
                        : const Text(
                            '仅图片记录',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      subtitle: Text(_formatDateTime(fragment.timestamp)),
                      leading: CircleAvatar(
                        backgroundColor: _getMoodColor(fragment.mood).withValues(alpha: 0.2),
                        child: Text(
                          fragment.mood.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fragment.hasMedia) 
                            const Icon(Icons.photo_outlined, size: 16),
                          if (fragment.hasMedia && fragment.hasTopicTags)
                            const SizedBox(width: 4),
                          if (fragment.hasTopicTags)
                            Icon(Icons.tag, size: 16, color: Theme.of(context).colorScheme.primary),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                      onTap: () => _navigateToMoodDetail(fragment),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 处理弹窗内标签点击 - 关闭当前弹窗并打开新的标签弹窗
  void _onTagTapInModal(String tagName) {
    Navigator.of(context).pop(); // 关闭当前弹窗
    
    // 查找对应的标签并显示其详情
    final tag = _topicTags.firstWhere(
      (t) => t.name == tagName,
      orElse: () => TopicTag(name: tagName, firstUsed: DateTime.now(), usageCount: 0),
    );
    _showTagDetails(tag);
  }

  // 导航到心情详情页面
  void _navigateToMoodDetail(MoodFragment fragment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MoodDetailScreen(entry: fragment.toMoodEntry()),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else {
      return '${(difference.inDays / 30).floor()}个月前';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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