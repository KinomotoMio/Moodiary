import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../services/fragment_storage_service.dart';
import '../widgets/mood_card.dart';
import '../events/app_events.dart';
import 'mood_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  
  const HistoryScreen({
    super.key,
    this.onNavigateToHome,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<MoodEntry> _allEntries = [];
  List<MoodEntry> _filteredEntries = [];
  bool _isLoading = true;
  bool _isSearchExpanded = false;
  
  // 筛选状态
  MoodType? _selectedMoodFilter;
  TimeFilter _selectedTimeFilter = TimeFilter.all;
  RangeValues _scoreRangeFilter = const RangeValues(0, 100);
  
  // 事件监听
  late StreamSubscription _moodDataSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _setupEventListeners();
    _loadEntries();
  }
  
  // 设置事件监听器
  void _setupEventListeners() {
    _moodDataSubscription = StorageService.eventBus.on<MoodDataChangedEvent>().listen((event) {
      // 当心情数据发生变化时，重新加载数据
      if (mounted) {
        _loadEntries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _moodDataSubscription.cancel(); // 取消事件监听
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allEntries = await _fragmentStorage.getAllMoodEntries();
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading entries: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    List<MoodEntry> filtered = List.from(_allEntries);
    
    // 搜索筛选
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        return entry.content.toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    // 情绪类型筛选
    if (_selectedMoodFilter != null) {
      filtered = filtered.where((entry) {
        return entry.mood == _selectedMoodFilter;
      }).toList();
    }
    
    // 时间筛选
    if (_selectedTimeFilter != TimeFilter.all) {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeFilter) {
        case TimeFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case TimeFilter.week:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case TimeFilter.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimeFilter.all:
          startDate = DateTime(1970);
          break;
      }
      
      filtered = filtered.where((entry) {
        return entry.timestamp.isAfter(startDate);
      }).toList();
    }
    
    // 评分筛选
    filtered = filtered.where((entry) {
      return entry.emotionScore >= _scoreRangeFilter.start && 
             entry.emotionScore <= _scoreRangeFilter.end;
    }).toList();
    
    setState(() {
      _filteredEntries = filtered;
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedMoodFilter = null;
      _selectedTimeFilter = TimeFilter.all;
      _scoreRangeFilter = const RangeValues(0, 100);
      _isSearchExpanded = false;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
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
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '筛选',
          ),
          // 菜单按钮
          if (_allEntries.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearDialog();
                } else if (value == 'reset_filters') {
                  _resetFilters();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reset_filters',
                  child: Row(
                    children: [
                      Icon(Icons.clear, size: 20),
                      SizedBox(width: 8),
                      Text('重置筛选'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, size: 20),
                      SizedBox(width: 8),
                      Text('清空记录'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 搜索框
                  if (_isSearchExpanded) _buildSearchBox(),
                  // 筛选状态显示
                  if (_hasActiveFilters()) _buildFilterChips(),
                  // 记录列表
                  Expanded(
                    child: _filteredEntries.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: MoodCard(
                                  entry: entry,
                                  onTap: () async {
                                    final result = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (context) => MoodDetailScreen(entry: entry),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadEntries(); // 如果有修改或删除，重新加载数据
                                    }
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(entry);
                                  },
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

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索心情记录...',
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
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedMoodFilter != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(_selectedMoodFilter!.displayName),
                  avatar: Text(_selectedMoodFilter!.emoji),
                  selected: true,
                  onSelected: (_) {
                    setState(() {
                      _selectedMoodFilter = null;
                    });
                    _applyFilters();
                  },
                ),
              ),
            if (_selectedTimeFilter != TimeFilter.all)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(_selectedTimeFilter.displayName),
                  avatar: const Icon(Icons.access_time, size: 16),
                  selected: true,
                  onSelected: (_) {
                    setState(() {
                      _selectedTimeFilter = TimeFilter.all;
                    });
                    _applyFilters();
                  },
                ),
              ),
            if (_scoreRangeFilter.start > 0 || _scoreRangeFilter.end < 100)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text('评分 ${_scoreRangeFilter.start.round()}-${_scoreRangeFilter.end.round()}'),
                  avatar: const Icon(Icons.trending_up, size: 16),
                  selected: true,
                  onSelected: (_) {
                    setState(() {
                      _scoreRangeFilter = const RangeValues(0, 100);
                    });
                    _applyFilters();
                  },
                ),
              ),
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text('搜索: "${_searchController.text}"'),
                  avatar: const Icon(Icons.search, size: 16),
                  selected: true,
                  onSelected: (_) {
                    _searchController.clear();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedMoodFilter != null ||
           _selectedTimeFilter != TimeFilter.all ||
           _scoreRangeFilter.start > 0 ||
           _scoreRangeFilter.end < 100 ||
           _searchController.text.isNotEmpty;
  }

  void _showFilterDialog() {
    // 创建对话框内的临时状态
    MoodType? tempMoodFilter = _selectedMoodFilter;
    TimeFilter tempTimeFilter = _selectedTimeFilter;
    RangeValues tempScoreRange = _scoreRangeFilter;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('筛选选项'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 情绪类型筛选
                Text(
                  '情绪类型',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('全部'),
                      selected: tempMoodFilter == null,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempMoodFilter = null;
                        });
                      },
                    ),
                    ...MoodType.values.map((mood) => FilterChip(
                      label: Text(mood.displayName),
                      avatar: Text(mood.emoji),
                      selected: tempMoodFilter == mood,
                      onSelected: (selected) {
                        setDialogState(() {
                          tempMoodFilter = selected ? mood : null;
                        });
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 时间筛选
                Text(
                  '时间范围',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: TimeFilter.values.map((filter) => FilterChip(
                    label: Text(filter.displayName),
                    selected: tempTimeFilter == filter,
                    onSelected: (selected) {
                      setDialogState(() {
                        tempTimeFilter = selected ? filter : TimeFilter.all;
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                // 评分筛选
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '情绪评分',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // 最小值输入
                        GestureDetector(
                          onTap: () => _showScoreInputDialog(
                            context: context,
                            title: '设置最小分数',
                            initialValue: tempScoreRange.start.round(),
                            onChanged: (value) {
                              if (value < tempScoreRange.end) {
                                setDialogState(() {
                                  tempScoreRange = RangeValues(value.toDouble(), tempScoreRange.end);
                                });
                              }
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${tempScoreRange.start.round()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('-'),
                        ),
                        // 最大值输入
                        GestureDetector(
                          onTap: () => _showScoreInputDialog(
                            context: context,
                            title: '设置最大分数',
                            initialValue: tempScoreRange.end.round(),
                            onChanged: (value) {
                              if (value > tempScoreRange.start) {
                                setDialogState(() {
                                  tempScoreRange = RangeValues(tempScoreRange.start, value.toDouble());
                                });
                              }
                            },
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Theme.of(context).colorScheme.outline),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${tempScoreRange.end.round()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: tempScoreRange,
                  min: 0,
                  max: 100,
                  divisions: 20, // 100/5 = 20个分割点，每5分一个吸附点
                  labels: RangeLabels(
                    tempScoreRange.start.round().toString(),
                    tempScoreRange.end.round().toString(),
                  ),
                  onChanged: (values) {
                    setDialogState(() {
                      // 吸附到5的倍数
                      final start = (values.start / 5).round() * 5.0;
                      final end = (values.end / 5).round() * 5.0;
                      tempScoreRange = RangeValues(start, end);
                    });
                  },
                ),
                // 刻度标记
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i <= 100; i += 25)
                        Text(
                          i.toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 重置到默认值
                setDialogState(() {
                  tempMoodFilter = null;
                  tempTimeFilter = TimeFilter.all;
                  tempScoreRange = const RangeValues(0, 100);
                });
              },
              child: const Text('重置'),
            ),
            FilledButton(
              onPressed: () {
                // 应用临时筛选条件到实际状态
                setState(() {
                  _selectedMoodFilter = tempMoodFilter;
                  _selectedTimeFilter = tempTimeFilter;
                  _scoreRangeFilter = tempScoreRange;
                });
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('应用'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScoreInputDialog({
    required BuildContext context,
    required String title,
    required int initialValue,
    required Function(int) onChanged,
  }) {
    final TextEditingController controller = TextEditingController(text: initialValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '分数 (0-100)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '分',
              ),
              autofocus: true,
              onSubmitted: (value) {
                final score = int.tryParse(value);
                if (score != null && score >= 0 && score <= 100) {
                  onChanged(score);
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 16),
            // 快速选择按钮
            Wrap(
              spacing: 8.0,
              children: [
                for (int score in [0, 25, 50, 75, 100])
                  FilterChip(
                    label: Text('$score'),
                    selected: initialValue == score,
                    onSelected: (selected) {
                      if (selected) {
                        controller.text = score.toString();
                        onChanged(score);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final score = int.tryParse(controller.text);
              if (score != null && score >= 0 && score <= 100) {
                onChanged(score);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入0-100之间的数字')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool hasRecords = _allEntries.isNotEmpty;
    final bool hasFilters = _hasActiveFilters();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasRecords && hasFilters ? Icons.search_off : Icons.history_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              hasRecords && hasFilters ? '没有找到匹配的记录' : '还没有历史记录',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasRecords && hasFilters 
                ? '尝试调整筛选条件或搜索关键词'
                : '开始记录你的心情吧！\n每一次记录都是珍贵的回忆',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            if (hasRecords && hasFilters)
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear),
                label: const Text('清除筛选'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  // 如果有回调，使用回调切换到主页；否则尝试pop
                  if (widget.onNavigateToHome != null) {
                    widget.onNavigateToHome!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.home),
                label: const Text('开始记录'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(MoodEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定要删除这条心情记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteEntry(entry);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有记录'),
        content: const Text('确定要清空所有心情记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _clearAllEntries();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清空'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _deleteEntry(MoodEntry entry) async {
    try {
      await _fragmentStorage.deleteFragment(entry.id);
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _clearAllEntries() async {
    try {
      await _fragmentStorage.clearAllFragments();
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有记录已清空')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清空失败: $e')),
        );
      }
    }
  }
}

// 时间筛选选项
enum TimeFilter {
  all('全部时间'),
  today('今天'), 
  week('本周'),
  month('本月');

  const TimeFilter(this.displayName);
  final String displayName;
}