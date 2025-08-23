import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../widgets/mood_card.dart';
import 'add_mood_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService.instance;
  List<MoodEntry> _recentEntries = [];
  MoodStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取最近的5条记录
      final allEntries = await _storageService.getAllMoodEntries();
      _recentEntries = allEntries.take(5).toList();
      
      // 获取统计数据
      _statistics = await _storageService.getMoodStatistics();
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
        content: '今天天气很好，心情特别棒！早上去公园跑步，看到很多可爱的小动物，感觉整个世界都充满了活力。工作上也有新的进展，同事们都很支持我的想法。',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        mood: MoodType.positive,
        emotionScore: 85,
      ),
      MoodEntry(
        id: '2', 
        content: '有点焦虑，明天有个重要的会议，担心准备得不够充分。虽然努力了很久，但总觉得还有什么遗漏的地方。希望明天能顺利进行。',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        mood: MoodType.negative,
        emotionScore: 35,
      ),
      MoodEntry(
        id: '3',
        content: '平平常常的一天，没什么特别的事情发生。按部就班地工作，吃饭，休息。有时候觉得这样的日子也挺好的，不用太兴奋，也不用太担心。',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        mood: MoodType.neutral,
        emotionScore: 50,
      ),
      MoodEntry(
        id: '4',
        content: '和朋友们一起聚餐，聊了很多有趣的话题。大家分享了最近的生活，虽然各自都有烦恼，但在一起的时候就忘记了所有不开心的事情。友谊真是珍贵！',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        mood: MoodType.positive,
        emotionScore: 78,
      ),
      MoodEntry(
        id: '5',
        content: '感觉有点累了，最近工作压力比较大，加班频繁。需要找个时间好好休息一下，也许应该出去旅行放松放松心情。',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        mood: MoodType.negative,
        emotionScore: 42,
      ),
    ];

    try {
      for (final entry in testEntries) {
        await _storageService.saveMoodEntry(entry);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加5条测试心情记录')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心情日记'),
        elevation: 0,
        actions: [
          // 临时：添加测试数据按钮  
          IconButton(
            icon: const Icon(Icons.data_array),
            onPressed: _addTestData,
            tooltip: '添加测试数据',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
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
            if (_recentEntries.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                child: const Text('查看全部'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentEntries.isEmpty)
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
          ...(_recentEntries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: MoodCard(
                  entry: entry,
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