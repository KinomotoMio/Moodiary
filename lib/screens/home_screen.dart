import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../models/mood_fragment.dart';
import '../services/storage_service.dart';
import '../services/fragment_storage_service.dart';
import '../widgets/fragment_card.dart';
import '../events/app_events.dart';
import 'add_mood_screen.dart';
import 'mood_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  List<MoodFragment> _recentFragments = [];
  MoodStatistics? _statistics;
  bool _isLoading = true;
  
  // 事件监听
  late StreamSubscription _moodDataSubscription;

  @override
  void initState() {
    super.initState();
    _setupEventListeners();
    _loadData();
  }
  
  // 设置事件监听器
  void _setupEventListeners() {
    _moodDataSubscription = StorageService.eventBus.on<MoodDataChangedEvent>().listen((event) {
      // 当心情数据发生变化时，重新加载数据
      if (mounted) {
        _loadData();
      }
    });
  }
  
  @override
  void dispose() {
    _moodDataSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取最近的5条Fragment记录
      final allFragments = await _fragmentStorage.getAllFragments();
      _recentFragments = allFragments.take(5).toList();
      
      // 获取统计数据
      _statistics = await _fragmentStorage.getMoodStatistics();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // 临时：添加测试数据的方法
  Future<void> _addTestData() async {
    final testEntries = [
      MoodEntry(
        id: '1',
        content: '今天天气很好，心情特别棒！早上去 #公园 跑步，看到很多可爱的小动物，感觉整个世界都充满了活力。#工作 上也有新的进展，同事们都很支持我的想法。#心情 #运动',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        mood: MoodType.positive,
        emotionScore: 85,
      ),
      MoodEntry(
        id: '2', 
        content: '有点 #焦虑，明天有个重要的 #会议，担心准备得不够充分。虽然努力了很久，但总觉得还有什么遗漏的地方。希望明天能顺利进行。#工作 #压力',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        mood: MoodType.negative,
        emotionScore: 35,
      ),
      MoodEntry(
        id: '3',
        content: '平平常常的一天，没什么特别的事情发生。按部就班地 #工作，吃饭，休息。有时候觉得这样的 #日常 也挺好的，不用太兴奋，也不用太担心。#平静',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        mood: MoodType.neutral,
        emotionScore: 50,
      ),
      MoodEntry(
        id: '4',
        content: '和 #朋友 们一起聚餐，聊了很多有趣的话题。大家分享了最近的 #生活，虽然各自都有烦恼，但在一起的时候就忘记了所有不开心的事情。#友谊 真是珍贵！#聚会',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        mood: MoodType.positive,
        emotionScore: 78,
      ),
      MoodEntry(
        id: '5',
        content: '感觉有点累了，最近 #工作 #压力 比较大，加班频繁。需要找个时间好好休息一下，也许应该出去 #旅行 放松放松心情。#疲惫',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        mood: MoodType.negative,
        emotionScore: 42,
      ),
      MoodEntry(
        id: '6',
        content: '周末终于可以好好休息了！睡了个懒觉，然后做了喜欢的 #料理。简单的 #幸福 就是这样，不需要太复杂。#周末 #放松 #美食',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        mood: MoodType.positive,
        emotionScore: 72,
      ),
      MoodEntry(
        id: '7',
        content: '今天 #学习 了新的知识，感觉很充实。虽然有些内容很难理解，但是慢慢消化总会有收获的。#成长 #知识 #努力',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        mood: MoodType.positive,
        emotionScore: 68,
      ),
      MoodEntry(
        id: '8',
        content: '下雨天总是让人感到有些 #忧郁。坐在窗边听着雨声，想起了很多往事。#天气 #回忆 #思考',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        mood: MoodType.negative,
        emotionScore: 38,
      ),
      MoodEntry(
        id: '9',
        content: '今天去看了场 #电影，剧情很感人，看得眼泪都出来了。艺术真的有治愈人心的力量。#文艺 #感动 #治愈',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        mood: MoodType.positive,
        emotionScore: 75,
      ),
      MoodEntry(
        id: '10',
        content: '又是一个普通的 #工作 日，处理了很多琐碎的事情。虽然不算特别开心，但也没什么不满的。#日常 #平凡',
        timestamp: DateTime.now().subtract(const Duration(days: 6)),
        mood: MoodType.neutral,
        emotionScore: 55,
      ),
      MoodEntry(
        id: '11',
        content: '和 #家人 视频通话，听到他们的声音就觉得很温暖。距离不能阻隔 #爱，#思念 让心更近。#家庭 #温暖',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        mood: MoodType.positive,
        emotionScore: 80,
      ),
      MoodEntry(
        id: '12',
        content: '今天犯了个小错误，被领导批评了。虽然知道是为了我好，但还是觉得有点 #沮丧。明天会做得更好。#工作 #反思 #成长',
        timestamp: DateTime.now().subtract(const Duration(days: 8)),
        mood: MoodType.negative,
        emotionScore: 45,
      ),
    ];

    try {
      for (final entry in testEntries) {
        await _fragmentStorage.saveMoodEntry(entry);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加12条测试心情记录，包含丰富的话题标签')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加测试数据失败: $e')),
        );
      }
    }
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
        title: Text(
          'Moodiary',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFFFF6B8A), Color(0xFFFF8FA3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
        elevation: 0,
        actions: [
          // 临时：添加测试数据按钮  
          IconButton(
            icon: const Icon(Icons.data_array),
            onPressed: _addTestData,
            tooltip: '添加测试数据',
          ),
          // 临时：重建标签统计按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rebuildTagsStatistics,
            tooltip: '重建标签统计',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildStatisticsCard(),
                    const SizedBox(height: 24),
                    _buildRecentEntriesSection(),
                  ],
                ),
              ),
      ),
      floatingActionButton: Tooltip(
        message: '记录心情',
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const AddMoodScreen()),
            );
            if (result == true) {
              _loadData();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final greeting = _getGreeting();
    final date = _formatDate(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '今天过得怎么样？记录下你的心情，让我们一起关注你的情绪健康～',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null || _statistics!.totalEntries == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                '还没有心情记录',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '开始记录你的第一条心情吧！',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _statistics!;
    final dominantMood = stats.dominantMoodType;

    return Card(
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
                  '心情统计',
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
                  child: _buildStatItem(
                    '总记录',
                    '${stats.totalEntries}条',
                    Icons.note_outlined,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '平均分',
                    '${stats.averageScore.toStringAsFixed(1)}分',
                    Icons.trending_up_outlined,
                  ),
                ),
                if (dominantMood != null)
                  Expanded(
                    child: _buildStatItem(
                      '主要情绪',
                      dominantMood.displayName,
                      Icons.emoji_emotions_outlined,
                    ),
                  ),
              ],
            ),
          ],
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

  Widget _buildRecentEntriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近记录',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentFragments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.mood_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '还没有心情记录',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击下方按钮开始记录吧！',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_recentFragments.map((fragment) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: FragmentCard(
                  fragment: fragment,
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => MoodDetailScreen(entry: fragment.toMoodEntry()),
                      ),
                    );
                    if (result == true) {
                      _loadData(); // 如果删除了记录，重新加载数据
                    }
                  },
                ),
              ))),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '深夜好';
    } else if (hour < 12) {
      return '早上好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }

  String _formatDate(DateTime dateTime) {
    try {
      return DateFormat('MM月dd日 EEEE', 'zh_CN').format(dateTime);
    } catch (e) {
      return DateFormat('MM月dd日 EEEE').format(dateTime);
    }
  }
}