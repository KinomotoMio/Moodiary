import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../widgets/chart_widgets.dart';
import '../widgets/mood_card.dart';
import '../models/mood_entry.dart';
import 'mood_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final StorageService _storageService = StorageService.instance;

  // 数据状态
  List<FlSpot> _weekTrendData = [];
  List<FlSpot> _monthTrendData = [];
  List<PieChartSectionData> _distributionData = [];
  Map<MoodType, int> _moodCounts = {};
  List<BarChartGroupData> _frequencyData = [];
  MoodInsightsReport? _insightsReport;
  QuickStats? _quickStats;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载所有数据
      final results = await Future.wait([
        _analyticsService.getMoodTrendData(days: 7),
        _analyticsService.getMoodTrendData(days: 30),
        _analyticsService.getMoodDistributionData(days: 30),
        _analyticsService.getRecordFrequencyData(days: 7),
        _analyticsService.getMoodInsights(days: 30),
        _analyticsService.getQuickStats(),
      ]);

      setState(() {
        _weekTrendData = results[0] as List<FlSpot>;
        _monthTrendData = results[1] as List<FlSpot>;
        _distributionData = results[2] as List<PieChartSectionData>;
        _frequencyData = results[3] as List<BarChartGroupData>;
        _insightsReport = results[4] as MoodInsightsReport;
        _quickStats = results[5] as QuickStats;

        // 从洞察报告中获取情绪分布数据
        _moodCounts = _insightsReport?.moodDistribution ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: '刷新数据',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '趋势分析', icon: Icon(Icons.trending_up)),
            Tab(text: '情绪分布', icon: Icon(Icons.pie_chart)),
            Tab(text: '洞察报告', icon: Icon(Icons.insights)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendAnalysisTab(),
                _buildDistributionTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildTrendAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快速统计卡片
          if (_quickStats != null) ...[
            Row(
              children: [
                Expanded(
                  child: QuickStatsCard(
                    title: '本周记录',
                    value: '${_quickStats!.weekCount}',
                    subtitle: '平均分数: ${_quickStats!.weekAverage.toStringAsFixed(1)}',
                    icon: Icons.calendar_view_week,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: QuickStatsCard(
                    title: '本月记录',
                    value: '${_quickStats!.monthCount}',
                    subtitle: '平均分数: ${_quickStats!.monthAverage.toStringAsFixed(1)}',
                    icon: Icons.calendar_view_month,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 7天趋势
          _buildSectionHeader('7天情绪趋势'),
          Card(
            child: Column(
              children: [
                MoodTrendChart(
                  trendData: _weekTrendData,
                  days: 7,
                ),
                if (_weekTrendData.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '过去一周的情绪起伏，帮助你了解近期的心理状态变化',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 30天趋势
          _buildSectionHeader('30天情绪趋势'),
          Card(
            child: Column(
              children: [
                MoodTrendChart(
                  trendData: _monthTrendData,
                  days: 30,
                ),
                if (_monthTrendData.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '一个月的整体趋势，观察长期的情绪模式和周期性变化',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 记录频率
          _buildSectionHeader('记录频率'),
          Card(
            child: Column(
              children: [
                RecordFrequencyChart(
                  frequencyData: _frequencyData,
                  days: 7,
                ),
                if (_frequencyData.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '每日记录次数，保持规律的记录有助于更好地管理情绪',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('情绪类型分布'),
          Card(
            child: Column(
              children: [
                const SizedBox(height: 16),
                MoodDistributionChart(
                  distributionData: _distributionData,
                  moodCounts: _moodCounts,
                ),
                if (_distributionData.isNotEmpty) ...[
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '了解你的情绪构成，积极情绪占比高说明心理状态良好',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 情绪分布统计详情
          if (_moodCounts.isNotEmpty) ...[
            _buildSectionHeader('详细统计'),
            ..._moodCounts.entries.map((entry) {
              final mood = entry.key;
              final count = entry.value;
              final total = _moodCounts.values.reduce((a, b) => a + b);
              final percentage = (count / total) * 100;

              const moodLabels = {
                MoodType.positive: '积极情绪',
                MoodType.neutral: '平静状态',
                MoodType.negative: '消极情绪',
              };

              const moodColors = {
                MoodType.positive: Color(0xFF4CAF50),
                MoodType.neutral: Color(0xFFFF9800),
                MoodType.negative: Color(0xFFF44336),
              };

              const moodDescriptions = {
                MoodType.positive: '感到快乐、满足、充满活力的时刻',
                MoodType.neutral: '心境平和、状态稳定的时刻',
                MoodType.negative: '感到沮丧、压力、不安的时刻',
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _showMoodEntriesDialog(
                    mood,
                    moodLabels[mood] ?? '',
                    moodColors[mood] ?? Colors.grey,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: moodColors[mood],
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(moodLabels[mood] ?? ''),
                  subtitle: Text(moodDescriptions[mood] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: moodColors[mood],
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: moodColors[mood],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_insightsReport == null) {
      return const Center(child: Text('暂无洞察数据'));
    }

    final report = _insightsReport!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 概览卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.insights,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '过去${report.period}天洞察报告',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '基于${report.totalEntries}条记录的智能分析',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 核心指标
          Row(
            children: [
              Expanded(
                child: QuickStatsCard(
                  title: '平均情绪分数',
                  value: report.averageScore.toStringAsFixed(1),
                  subtitle: _getScoreDescription(report.averageScore),
                  icon: Icons.mood,
                  color: _getScoreColor(report.averageScore),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuickStatsCard(
                  title: '连续记录',
                  value: '${report.streakDays}天',
                  subtitle: report.streakDays > 7 ? '坚持得很好！' : '继续加油',
                  icon: Icons.local_fire_department,
                  color: report.streakDays > 7 ? const Color(0xFFFF5722) : const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: QuickStatsCard(
                  title: '情绪趋势',
                  value: report.trendDescription,
                  subtitle: '与前期对比',
                  icon: report.trendPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: report.trendPercentage >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: QuickStatsCard(
                  title: '活跃时段',
                  value: '${report.mostActiveHour}:00',
                  subtitle: report.activeTimeDescription,
                  icon: Icons.access_time,
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 情绪洞察
          _buildSectionHeader('个性化洞察'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightItem(
                    '主导情绪',
                    _getMoodTypeDescription(report.dominantMoodType),
                    Icons.psychology,
                  ),
                  const Divider(),
                  _buildInsightItem(
                    '记录习惯',
                    '你通常在${report.activeTimeDescription}记录心情，这个时段的情绪更容易被捕捉到',
                    Icons.schedule,
                  ),
                  if (report.streakDays > 0) ...[
                    const Divider(),
                    _buildInsightItem(
                      '坚持程度',
                      report.streakDays > 14 
                          ? '连续${report.streakDays}天记录，这是一个很棒的习惯！继续保持，让情绪管理成为生活的一部分'
                          : '已连续记录${report.streakDays}天，再坚持几天就能形成稳定的习惯',
                      Icons.emoji_events,
                    ),
                  ],
                  if (report.trendPercentage.abs() > 5) ...[
                    const Divider(),
                    _buildInsightItem(
                      '情绪变化',
                      report.trendPercentage > 0
                          ? '最近情绪有明显改善，保持当前的生活节奏和心态'
                          : '最近情绪有所波动，建议关注一下可能的压力源，适当调整生活方式',
                      report.trendPercentage > 0 ? Icons.sentiment_satisfied : Icons.sentiment_neutral,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 建议
          _buildSectionHeader('个性化建议'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _generatePersonalizedTips(report)
                    .map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 80) return '情绪很好';
    if (score >= 60) return '状态良好';
    if (score >= 40) return '一般状态';
    return '需要关注';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFF8BC34A);
    if (score >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String _getMoodTypeDescription(MoodType? moodType) {
    switch (moodType) {
      case MoodType.positive:
        return '你的情绪以积极正面为主，这表明你有很好的心理韧性和生活态度';
      case MoodType.neutral:
        return '你的情绪状态比较平稳，善于保持内心的平和与安定';
      case MoodType.negative:
        return '最近消极情绪较多，建议关注自己的心理健康，适当寻求支持';
      default:
        return '还需要更多数据来分析你的情绪模式';
    }
  }

  List<String> _generatePersonalizedTips(MoodInsightsReport report) {
    final tips = <String>[];

    // 基于平均分数的建议
    if (report.averageScore < 40) {
      tips.add('情绪分数偏低，建议增加运动、听音乐或与朋友交流的时间');
      tips.add('考虑寻求专业心理健康支持，学习更好的情绪调节技巧');
    } else if (report.averageScore < 60) {
      tips.add('可以尝试一些放松技巧，如深呼吸、冥想或瑜伽');
      tips.add('保持规律的作息时间，充足的睡眠有助于情绪稳定');
    } else {
      tips.add('情绪状态不错，继续保持现在的生活方式');
    }

    // 基于记录频率的建议
    if (report.totalEntries < 10) {
      tips.add('增加记录频率有助于更好地了解自己的情绪模式');
    }

    // 基于连续记录天数的建议
    if (report.streakDays < 7) {
      tips.add('尝试每天至少记录一次心情，养成自我觉察的好习惯');
    } else if (report.streakDays > 30) {
      tips.add('记录习惯很棒！可以开始关注更细致的情绪变化模式');
    }

    // 基于主导情绪的建议
    if (report.dominantMoodType == MoodType.negative) {
      tips.add('多关注生活中的积极面，培养感恩的心态');
      tips.add('适当调整生活节奏，给自己更多放松和恢复的时间');
    } else if (report.dominantMoodType == MoodType.positive) {
      tips.add('保持积极的心态，可以多分享快乐给身边的人');
    }

    return tips;
  }

  // 获取特定情绪类型的记录
  Future<List<MoodEntry>> _getMoodEntriesByType(MoodType moodType) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));
    final allEntries = await _storageService.getMoodEntriesByDateRange(startDate, endDate);
    
    return allEntries.where((entry) => entry.mood == moodType).toList();
  }

  // 显示特定情绪类型的记录弹窗
  void _showMoodEntriesDialog(MoodType moodType, String moodLabel, Color moodColor) async {
    final entries = await _getMoodEntriesByType(moodType);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: moodColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: moodColor,
                      radius: 16,
                      child: Text(
                        entries.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moodLabel,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: moodColor,
                            ),
                          ),
                          Text(
                            '过去30天的${entries.length}条记录',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // 记录列表
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sentiment_neutral,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无${moodLabel}记录',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: MoodCard(
                              entry: entry,
                              onTap: () {
                                Navigator.of(context).pop(); // 关闭弹窗
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MoodDetailScreen(entry: entry),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}