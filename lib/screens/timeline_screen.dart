import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../services/fragment_storage_service.dart';
import '../events/app_events.dart';
import '../utils/navigation_utils.dart';
import '../widgets/fragment_card.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';

/// Timeline页面 - 以时间轴形式展示用户的情绪记录流
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final SearchService _searchService = SearchService.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  final Map<String, List<MoodFragment>> _fragmentsByDate = {};
  List<MoodFragment> _allFragments = [];
  bool _isLoading = true;
  MoodType? _selectedMoodFilter;
  bool _isSearchExpanded = false;
  
  // 事件监听
  late StreamSubscription _moodDataSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _setupEventListeners();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _moodDataSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupEventListeners() {
    _moodDataSubscription = StorageService.eventBus.on<MoodDataChangedEvent>().listen((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final fragments = await _fragmentStorage.getAllFragments();
      _allFragments = fragments;
      _applyFiltersAndOrganize();
    } catch (e) {
      debugPrint('Error loading timeline data: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _organizeFragmentsByDate(List<MoodFragment> fragments) {
    _fragmentsByDate.clear();

    for (final fragment in fragments) {
      final dateKey = DateFormat('yyyy-MM-dd').format(fragment.timestamp);
      _fragmentsByDate.putIfAbsent(dateKey, () => []).add(fragment);
    }

    // 对每天的记录按时间排序
    for (final dayFragments in _fragmentsByDate.values) {
      dayFragments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  void _onSearchChanged() {
    _applyFiltersAndOrganize();
  }

  void _applyFiltersAndOrganize() {
    if (!mounted) return;

    // 构建搜索条件
    final criteria = SearchCriteria(
      textQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      moodFilter: _selectedMoodFilter,
    );

    // 使用SearchService进行筛选
    final filteredFragments = _searchService.filterFragments(_allFragments, criteria);

    // 按日期重新组织
    _organizeFragmentsByDate(filteredFragments);

    if (mounted) {
      setState(() {
        // 触发UI重建
      });
    }
  }

  List<String> _getFilteredDateKeys() {
    // 直接返回已经过筛选并组织好的日期键，按时间倒序排列
    return _fragmentsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  List<MoodFragment> _getFilteredFragmentsForDate(String dateKey) {
    // 直接返回已经过筛选的当日记录
    return _fragmentsByDate[dateKey] ?? [];
  }

  bool _hasActiveFilters() {
    return _selectedMoodFilter != null || _searchController.text.isNotEmpty;
  }

  void _navigateToMoodDetail(MoodFragment fragment) async {
    final heroTag = NavigationUtils.getHeroTag(fragment.id, 'timeline');
    final result = await NavigationUtils.navigateToMoodDetail(
      context, 
      fragment.toMoodEntry(),
      heroTag: heroTag,
    );

    NavigationUtils.handleDetailResult(result, () async {
      if (mounted) {
        await _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间线'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_isSearchExpanded ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                }
              });
            },
            tooltip: _isSearchExpanded ? '关闭搜索' : '搜索',
          ),
          PopupMenuButton<MoodType?>(
            initialValue: _selectedMoodFilter,
            onSelected: (value) {
              setState(() {
                _selectedMoodFilter = value;
              });
              _applyFiltersAndOrganize();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 20),
                    SizedBox(width: 8),
                    Text('全部'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MoodType.positive,
                child: Row(
                  children: [
                    Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('积极'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MoodType.negative,
                child: Row(
                  children: [
                    Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('消极'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MoodType.neutral,
                child: Row(
                  children: [
                    Icon(Icons.sentiment_neutral, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('中性'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 搜索框
                  if (_isSearchExpanded) _buildSearchBox(),
                  // 搜索结果统计
                  if (_hasActiveFilters()) _buildSearchStats(),
                  // 时间线内容
                  Expanded(child: _buildTimelineContent()),
                ],
              ),
      ),
    );
  }

  Widget _buildTimelineContent() {
    final filteredDateKeys = _getFilteredDateKeys();
    
    if (filteredDateKeys.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredDateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = filteredDateKeys[index];
        final dayFragments = _getFilteredFragmentsForDate(dateKey);
        
        if (dayFragments.isEmpty) return const SizedBox.shrink();
        
        return _buildTimelineDay(dateKey, dayFragments, index);
      },
    );
  }

  Widget _buildTimelineDay(String dateKey, List<MoodFragment> fragments, int dayIndex) {
    final date = DateTime.parse(dateKey);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
    final isYesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))) == dateKey;
    
    String dateLabel;
    if (isToday) {
      dateLabel = '今天';
    } else if (isYesterday) {
      dateLabel = '昨天';
    } else {
      dateLabel = DateFormat('MM月dd日 EEEE', 'zh_CN').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Container(
          margin: EdgeInsets.only(bottom: 16, top: dayIndex == 0 ? 0 : 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${fragments.length} 条记录',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // 时间线内容
        ...fragments.asMap().entries.map((entry) {
          final fragmentIndex = entry.key;
          final fragment = entry.value;
          final isLast = fragmentIndex == fragments.length - 1;
          
          return _buildTimelineItem(fragment, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(MoodFragment fragment, bool isLast) {
    final time = DateFormat('HH:mm').format(fragment.timestamp);
    final moodColor = _getMoodColor(fragment.mood);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间轴部分
          Column(
            children: [
              // 时间标签
              Container(
                width: 60,
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  time,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // 时间轴线和圆点
          Column(
            children: [
              const SizedBox(height: 2),
              // 情绪圆点
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: moodColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: moodColor.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // 连接线
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // 内容卡片
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Hero(
                tag: NavigationUtils.getHeroTag(fragment.id, 'timeline'),
                child: Material(
                  color: Colors.transparent,
                  child: FragmentCard(
                    fragment: fragment,
                    onTap: () => _navigateToMoodDetail(fragment),
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
    final filterText = _selectedMoodFilter == null ? '记录' : '${_selectedMoodFilter!.displayName}记录';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无$filterText',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始记录你的心情故事吧',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildSearchBox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16.0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _isSearchExpanded ? 1.0 : 0.95,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索时间线记录...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchStats() {
    if (!_hasActiveFilters() || _isLoading) return const SizedBox();
    
    // 构建搜索条件
    final criteria = SearchCriteria(
      textQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
      moodFilter: _selectedMoodFilter,
    );

    // 使用SearchService获取统计
    final filteredFragments = _searchService.filterFragments(_allFragments, criteria);
    final stats = _searchService.getSearchStats(_allFragments, filteredFragments);
    
    final percentage = stats.filterRatio > 0 ? (stats.filterRatio * 100).round() : 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '时间线筛选',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '${stats.filteredCount}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                ' / ${stats.totalCount} 条记录',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (percentage < 100) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}