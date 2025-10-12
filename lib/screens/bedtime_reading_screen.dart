import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_summary.dart';
import '../models/mood_entry.dart';
import '../models/mood_fragment.dart';
import '../services/daily_summary_service.dart';
import '../services/fragment_storage_service.dart';
import '../widgets/impression_image_banner.dart';

/// 睡前阅读页面
///
/// 设计理念：
/// 1. 深色柔和的背景，助眠氛围
/// 2. 大号字体，舒适的阅读体验
/// 3. 三部分内容清晰分隔（事件回顾 + 情绪流向 + 冥想引导）
/// 4. 支持历史查看和收藏
class BedtimeReadingScreen extends StatefulWidget {
  const BedtimeReadingScreen({super.key});

  @override
  State<BedtimeReadingScreen> createState() => _BedtimeReadingScreenState();
}

class _BedtimeReadingScreenState extends State<BedtimeReadingScreen>
    with SingleTickerProviderStateMixin {
  final DailySummaryService _summaryService = DailySummaryService.instance;
  final FragmentStorageService _fragmentStorage =
      FragmentStorageService.instance;

  DailySummary? _todaySummary;
  List<MoodFragment> _todayFragments = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _loadTodaySummary();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadTodaySummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _summaryService.generateTodaySummary();
      final fragments = await _fetchFragmentsForDate(summary.date);
      if (mounted) {
        setState(() {
          _todaySummary = summary;
          _todayFragments = fragments;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '生成失败：$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _regenerateSummary() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final summary = await _summaryService.generateTodaySummary(
        forceRegenerate: true,
      );
      final fragments = await _fetchFragmentsForDate(summary.date);
      if (mounted) {
        setState(() {
          _todaySummary = summary;
          _todayFragments = fragments;
          _isGenerating = false;
        });
        _fadeController.reset();
        _fadeController.forward();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已重新生成睡前内容')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '重新生成失败：$e';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_todaySummary == null) return;

    await _summaryService.toggleFavorite(_todaySummary!.id);

    if (!mounted) return;

    setState(() {
      _todaySummary = _todaySummary!.copyWith(
        isFavorite: !_todaySummary!.isFavorite,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_todaySummary!.isFavorite ? '已收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showHistoryList() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BedtimeHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('睡前阅读'),
        centerTitle: true,
        actions: [
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryList,
            tooltip: '历史记录',
          ),
          // 收藏按钮
          if (_todaySummary != null)
            IconButton(
              icon: Icon(
                _todaySummary!.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              onPressed: _toggleFavorite,
              tooltip: _todaySummary!.isFavorite ? '取消收藏' : '收藏',
            ),
          // 重新生成按钮
          if (_todaySummary != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isGenerating ? null : _regenerateSummary,
              tooltip: '重新生成',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              '正在生成今日睡前内容...',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_todaySummary == null) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _regenerateSummary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(),
              const SizedBox(height: 24),
              _buildImpressionBanner(),
              const SizedBox(height: 32),
              _buildEventSummarySection(),
              const SizedBox(height: 32),
              _buildEmotionReviewSection(),
              const SizedBox(height: 32),
              _buildMeditationGuideSection(),
              const SizedBox(height: 48),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final theme = Theme.of(context);
    final dateStr = DateFormat(
      'MM月dd日 EEEE',
      'zh_CN',
    ).format(_todaySummary!.date);
    final isToday = _todaySummary!.isToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 日期
        Text(
          dateStr,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 16,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // 标题
        Text(
          isToday ? '今日回顾' : '往日回忆',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        // 记录数量
        if (_todaySummary!.fragmentCount > 0)
          Text(
            '共${_todaySummary!.fragmentCount}条记录',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildImpressionBanner() {
    return ImpressionImageBanner(
      emotionSummary: _buildDailyEmotionSummary(),
      timeRange: DateFormat('MM月dd日', 'zh_CN').format(_todaySummary!.date),
      height: 180,
    );
  }

  String _buildDailyEmotionSummary() {
    return composeDailyEmotionSummary(
      summary: _todaySummary!,
      fragments: _todayFragments,
    );
  }

  Future<List<MoodFragment>> _fetchFragmentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final fragments = await _fragmentStorage.getFragmentsByDateRange(
      startOfDay,
      endOfDay,
    );
    return fragments;
  }

  Widget _buildEventSummarySection() {
    return _buildContentSection(
      icon: Icons.event_note_outlined,
      iconColor: const Color(0xFF64b5f6),
      title: '今日事件',
      content: _todaySummary!.eventSummary,
    );
  }

  Widget _buildEmotionReviewSection() {
    return _buildContentSection(
      icon: Icons.favorite_border,
      iconColor: const Color(0xFFef5350),
      title: '情绪流向',
      content: _todaySummary!.emotionReview,
    );
  }

  Widget _buildMeditationGuideSection() {
    return _buildContentSection(
      icon: Icons.self_improvement_outlined,
      iconColor: const Color(0xFF9575cd),
      title: '正念冥想',
      content: _todaySummary!.meditationGuide,
      isLastSection: true,
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    bool isLastSection = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: iconColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 内容
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              height: 1.8,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.bedtime,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '祝你今晚好梦',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 16,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '暂无睡前内容',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '今天还没有记录心情\n明天记得来记录哦',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? '加载失败',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTodaySummary,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

String composeDailyEmotionSummary({
  required DailySummary summary,
  required List<MoodFragment> fragments,
}) {
  final lines = <String>[];

  if (summary.averageScore != null || summary.dominantMood != null) {
    final scorePart = summary.averageScore != null
        ? '平均情绪分 ${summary.averageScore!.toStringAsFixed(1)}'
        : null;
    final moodPart = summary.dominantMood != null
        ? '主导情绪 ${summary.dominantMood!.displayName}'
        : null;
    lines.add(
      [
        '今日情绪概览',
        if (scorePart != null) scorePart,
        if (moodPart != null) moodPart,
        '共 ${summary.fragmentCount} 条记录',
      ].join(' · '),
    );
  } else {
    lines.add('今日共记录 ${summary.fragmentCount} 条心情片段');
  }

  lines.add('事件回顾：${truncateWithEllipsis(summary.eventSummary)}');
  lines.add('情绪流向：${truncateWithEllipsis(summary.emotionReview)}');
  lines.add('正念引导：${truncateWithEllipsis(summary.meditationGuide)}');

  final meaningfulFragments = fragments
      .where((fragment) => fragmentContentWithTags(fragment).trim().isNotEmpty)
      .take(3)
      .toList();

  if (meaningfulFragments.isNotEmpty) {
    final timeFormat = DateFormat('HH:mm', 'zh_CN');
    lines.add('代表记录：');
    for (final fragment in meaningfulFragments) {
      lines.add(
        '• ${timeFormat.format(fragment.timestamp)} ${fragment.mood.displayName}：${truncateWithEllipsis(fragmentContentWithTags(fragment), maxLength: 90)}',
      );
    }
  }

  return lines.join('\n');
}

String truncateWithEllipsis(String text, {int maxLength = 180}) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength).trim()}…';
}

String fragmentContentWithTags(MoodFragment fragment) {
  if (fragment.fullContent.isNotEmpty) {
    return fragment.fullContent;
  }
  return fragment.displayContent;
}

class BedtimeSummaryDetailScreen extends StatefulWidget {
  final DailySummary summary;

  const BedtimeSummaryDetailScreen({super.key, required this.summary});

  @override
  State<BedtimeSummaryDetailScreen> createState() =>
      _BedtimeSummaryDetailScreenState();
}

class _BedtimeSummaryDetailScreenState
    extends State<BedtimeSummaryDetailScreen> {
  final FragmentStorageService _fragmentStorage =
      FragmentStorageService.instance;

  late DailySummary _summary;
  List<MoodFragment> _fragments = [];
  bool _isLoadingFragments = true;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
    _loadFragments();
  }

  Future<void> _loadFragments() async {
    final startOfDay = DateTime(
      _summary.date.year,
      _summary.date.month,
      _summary.date.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final fragments = await _fragmentStorage.getFragmentsByDateRange(
      startOfDay,
      endOfDay,
    );
    if (!mounted) return;
    setState(() {
      _fragments = fragments;
      _isLoadingFragments = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('yyyy年MM月dd日', 'zh_CN').format(_summary.date);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(dateStr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImpressionImageBanner(
              emotionSummary: composeDailyEmotionSummary(
                summary: _summary,
                fragments: _fragments,
              ),
              timeRange: DateFormat('MM月dd日', 'zh_CN').format(_summary.date),
              height: 180,
            ),
            const SizedBox(height: 24),
            _buildMetaChips(theme),
            const SizedBox(height: 24),
            _buildDetailSection(
              theme: theme,
              icon: Icons.event_note_outlined,
              iconColor: const Color(0xFF64b5f6),
              title: '今日事件',
              content: _summary.eventSummary,
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              theme: theme,
              icon: Icons.favorite_border,
              iconColor: const Color(0xFFef5350),
              title: '情绪流向',
              content: _summary.emotionReview,
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              theme: theme,
              icon: Icons.self_improvement_outlined,
              iconColor: const Color(0xFF9575cd),
              title: '正念冥想',
              content: _summary.meditationGuide,
            ),
            const SizedBox(height: 24),
            _buildFragmentSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChips(ThemeData theme) {
    final chips = <Widget>[];

    if (_summary.averageScore != null) {
      chips.add(
        _buildChip(theme, '平均分 ${_summary.averageScore!.toStringAsFixed(1)}'),
      );
    }
    if (_summary.dominantMood != null) {
      chips.add(
        _buildChip(theme, '主导情绪 ${_summary.dominantMood!.displayName}'),
      );
    }
    chips.add(_buildChip(theme, '记录 ${_summary.fragmentCount} 条'));

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFragmentSection(ThemeData theme) {
    if (_isLoadingFragments) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                '正在整理当天的心情片段...',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_fragments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notes_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '当日心情片段',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '当天未记录具体片段，但情绪洞察已为你保存。',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeFormat = DateFormat('HH:mm', 'zh_CN');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '当日心情片段',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._fragments.take(10).map((fragment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${timeFormat.format(fragment.timestamp)} · ${fragment.mood.displayName}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      truncateWithEllipsis(fragmentContentWithTags(fragment)),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// 睡前阅读历史页面
class BedtimeHistoryScreen extends StatefulWidget {
  const BedtimeHistoryScreen({super.key});

  @override
  State<BedtimeHistoryScreen> createState() => _BedtimeHistoryScreenState();
}

class _BedtimeHistoryScreenState extends State<BedtimeHistoryScreen> {
  final DailySummaryService _summaryService = DailySummaryService.instance;

  List<DailySummary> _summaries = [];
  DailySummary? _todaySummary;
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  bool _isGeneratingToday = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final summaries = await _summaryService.getHistorySummaries(
        limit: 60,
        onlyFavorites: _showOnlyFavorites,
      );

      final todayId = DailySummary.getIdFromDate(DateTime.now());
      DailySummary? todaySummary;
      for (final summary in summaries) {
        if (summary.id == todayId) {
          todaySummary = summary;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _summaries = summaries;
          _todaySummary = todaySummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('历史记录加载失败：$e')));
      }
    }
  }

  void _toggleFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
    });
    _loadHistory();
  }

  Future<void> _handleTodayAction() async {
    if (_isGeneratingToday) return;

    if (_todaySummary != null) {
      _viewSummary(_todaySummary!);
      return;
    }

    setState(() {
      _isGeneratingToday = true;
    });

    try {
      final summary = await _summaryService.generateTodaySummary(
        forceRegenerate: true,
      );
      if (!mounted) return;

      await _loadHistory(showLoading: false);
      _viewSummary(summary);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成失败：$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingToday = false;
        });
      }
    }
  }

  void _viewSummary(DailySummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BedtimeSummaryDetailScreen(summary: summary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('睡前阅读'),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleFilter,
            tooltip: _showOnlyFavorites ? '显示全部' : '只看收藏',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(showLoading: false),
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 160),
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              )
            : _buildHistoryList(theme),
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    final items = _summaries;
    final extraPlaceholder = items.isEmpty ? 1 : 0;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1 + extraPlaceholder,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTodayHeader(theme);
        }

        if (items.isEmpty && index == 1) {
          return _buildEmptyState(theme);
        }

        final summary = items[index - 1];
        return _buildHistoryItem(theme, summary);
      },
    );
  }

  Widget _buildTodayHeader(ThemeData theme) {
    final hasToday = _todaySummary != null;
    final title = hasToday ? '今晚的睡前阅读准备好了' : '今晚还没有生成睡前阅读';
    final description = hasToday
        ? '点击下方按钮即可查看今天的回顾与冥想引导。'
        : '记录完一天的心情后，点击下方按钮即可生成属于你的睡前陪伴。';

    final buttonLabel = _isGeneratingToday
        ? '生成中...'
        : hasToday
        ? '查看今日内容'
        : '生成今日睡前阅读';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasToday ? Icons.bedtime : Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isGeneratingToday ? null : _handleTodayAction,
              icon: Icon(
                hasToday ? Icons.visibility_outlined : Icons.auto_awesome,
              ),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(ThemeData theme, DailySummary summary) {
    final dateStr = DateFormat('MM月dd日', 'zh_CN').format(summary.date);
    final isToday = summary.isToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          summary.isFavorite ? Icons.favorite : Icons.bedtime_outlined,
          color: summary.isFavorite
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
          size: 28,
        ),
        title: Row(
          children: [
            Text(
              dateStr,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '今天',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            summary.eventSummary.length > 60
                ? '${summary.eventSummary.substring(0, 60)}...'
                : summary.eventSummary,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _viewSummary(summary),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showOnlyFavorites ? '暂无收藏' : '还没有历史记录',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyFavorites
                  ? '收藏的睡前阅读会显示在这里。'
                  : '生成的睡前阅读会自动加入历史，快来记录今天的心情吧。',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
