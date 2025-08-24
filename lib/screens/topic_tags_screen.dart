import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/mood_fragment.dart';
import '../services/fragment_storage_service.dart';
import '../events/app_events.dart';
import '../services/storage_service.dart';
import '../widgets/tag_detail_bottom_sheet.dart';

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
  final ScrollController _scrollController = ScrollController();
  
  List<TopicTag> _allTopicTags = [];
  List<TopicTag> _displayedTags = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  
  // 分页配置
  static const int _itemsPerPage = 20;
  int _currentPage = 0;
  bool _hasMoreItems = true;
  
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
    _setupScrollController();
    _loadData();
  }
  
  void _setupScrollController() {
    _scrollController.addListener(() {
      // 检查是否接近底部，提前加载更多数据
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreData();
      }
    });
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
    _scrollController.dispose();
    _moodDataSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreItems = true;
    });

    try {
      _allTopicTags = await _fragmentStorage.getAllTopicTags();
      _loadInitialPageData();
    } catch (e) {
      debugPrint('Error loading topic tags: $e');
      _allTopicTags = [];
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  void _loadInitialPageData() {
    final filteredTags = _getFilteredTags();
    final endIndex = _itemsPerPage;
    
    if (endIndex >= filteredTags.length) {
      _displayedTags = filteredTags;
      _hasMoreItems = false;
    } else {
      _displayedTags = filteredTags.take(endIndex).toList();
      _hasMoreItems = true;
    }
    
    _currentPage = 1;
  }
  
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreItems || _isLoading) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // 模拟网络延迟，使加载更真实
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      final filteredTags = _getFilteredTags();
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      
      if (startIndex >= filteredTags.length) {
        _hasMoreItems = false;
      } else {
        final newItems = filteredTags.skip(startIndex).take(_itemsPerPage).toList();
        _displayedTags.addAll(newItems);
        _currentPage++;
        
        if (endIndex >= filteredTags.length) {
          _hasMoreItems = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading more tags: $e');
    }
    
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  List<TopicTag> _getFilteredTags() {
    if (_searchQuery.isEmpty) return _allTopicTags;
    
    return _allTopicTags.where((tag) {
      return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  void _onSearchChanged() {
    // 重新计算显示的标签（重置分页）
    setState(() {
      _currentPage = 0;
      _hasMoreItems = true;
    });
    _loadInitialPageData();
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
                _onSearchChanged();
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
    if (_displayedTags.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        controller: _scrollController,
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
                '所有标签 (${_getFilteredTags().length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final tag = _displayedTags[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: _buildTagListItem(tag),
                );
              },
              childCount: _displayedTags.length,
            ),
          ),
          
          // 加载更多指示器
          if (_isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            
          // 没有更多数据提示
          if (!_hasMoreItems && _displayedTags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '已显示全部标签',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
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
    final totalTags = _allTopicTags.length;
    final totalUsage = _allTopicTags.fold(0, (sum, tag) => sum + tag.usageCount);
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
    if (_allTopicTags.isEmpty) return const SizedBox();
    
    // 获取使用频率前10的标签用于标签云
    final popularTags = _allTopicTags.take(10).toList();

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
                alignment: WrapAlignment.center,
                children: popularTags.map((tag) {
                  return _buildTagCloudChip(tag, popularTags);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建标签云中的单个标签芯片
  Widget _buildTagCloudChip(TopicTag tag, List<TopicTag> allTags) {
    if (allTags.isEmpty) return const SizedBox();
    
    final maxUsage = allTags.first.usageCount;
    final minUsage = allTags.last.usageCount;
    
    // 使用对数刻度计算字体大小，让差异更明显
    final minSize = 14.0;
    final maxSize = 26.0;
    final normalizedValue = minUsage == maxUsage 
        ? 1.0 
        : (math.log(tag.usageCount) - math.log(minUsage)) / 
          (math.log(maxUsage) - math.log(minUsage));
    final fontSize = minSize + (maxSize - minSize) * normalizedValue;
    
    // 计算颜色强度（基于频率百分位，从浅到深）
    final percentile = tag.usageCount / maxUsage;
    
    // 基于主题色的深浅渐变色系
    final theme = Theme.of(context);
    Color chipColor;
    Color textColor;
    
    if (percentile >= 0.8) {
      // 最高频：主色，深色
      chipColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (percentile >= 0.6) {
      // 高频：主色容器，较深
      chipColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    } else if (percentile >= 0.4) {
      // 中频：次要色容器，中等
      chipColor = theme.colorScheme.secondaryContainer;
      textColor = theme.colorScheme.onSecondaryContainer;
    } else if (percentile >= 0.2) {
      // 低频：表面变体，较浅
      chipColor = theme.colorScheme.surfaceContainerHigh;
      textColor = theme.colorScheme.onSurface;
    } else {
      // 最低频：表面容器，最浅
      chipColor = theme.colorScheme.surfaceContainer;
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    }
    
    // 高频标签添加渐变效果
    final isHighFrequency = percentile > 0.7;
    
    return GestureDetector(
      onTap: () => _showTagDetails(tag),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: isHighFrequency 
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    chipColor,
                    chipColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#${tag.name}',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${tag.usageCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${tag.name}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${tag.usageCount}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              backgroundColor: chipColor,
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        title: Text(tag.name),
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

  void _showTagDetails(TopicTag tag) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TagDetailBottomSheet(
        initialTag: tag,
        allTags: _allTopicTags,
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

}