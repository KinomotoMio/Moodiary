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

/// Timeline页面 - 以时间轴形式展示用户的情绪记录流
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final ScrollController _scrollController = ScrollController();
  
  final Map<String, List<MoodFragment>> _fragmentsByDate = {};
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, positive, negative, neutral
  
  // 事件监听
  late StreamSubscription _moodDataSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
    _loadData();
  }

  @override
  void dispose() {
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
      _organizeFragmentsByDate(fragments);
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

  List<String> _getFilteredDateKeys() {
    if (_selectedFilter == 'all') {
      return _fragmentsByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    }

    final filteredDates = <String>[];
    for (final dateKey in _fragmentsByDate.keys) {
      final dayFragments = _fragmentsByDate[dateKey]!;
      final hasMatchingFragments = dayFragments.any((fragment) {
        switch (_selectedFilter) {
          case 'positive':
            return fragment.mood == MoodType.positive;
          case 'negative':
            return fragment.mood == MoodType.negative;
          case 'neutral':
            return fragment.mood == MoodType.neutral;
          default:
            return true;
        }
      });
      
      if (hasMatchingFragments) {
        filteredDates.add(dateKey);
      }
    }
    
    return filteredDates..sort((a, b) => b.compareTo(a));
  }

  List<MoodFragment> _getFilteredFragmentsForDate(String dateKey) {
    final dayFragments = _fragmentsByDate[dateKey] ?? [];
    
    if (_selectedFilter == 'all') {
      return dayFragments;
    }

    return dayFragments.where((fragment) {
      switch (_selectedFilter) {
        case 'positive':
          return fragment.mood == MoodType.positive;
        case 'negative':
          return fragment.mood == MoodType.negative;
        case 'neutral':
          return fragment.mood == MoodType.neutral;
        default:
          return true;
      }
    }).toList();
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
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.all_inclusive, size: 20),
                    SizedBox(width: 8),
                    Text('全部'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'positive',
                child: Row(
                  children: [
                    Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('积极'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'negative',
                child: Row(
                  children: [
                    Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('消极'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'neutral',
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
            : _buildTimelineContent(),
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
    final filterText = _selectedFilter == 'all' ? '记录' : '${_getFilterDisplayName(_selectedFilter)}记录';
    
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

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'positive':
        return '积极';
      case 'negative':
        return '消极';
      case 'neutral':
        return '中性';
      default:
        return '全部';
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