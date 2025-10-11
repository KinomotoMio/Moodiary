import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_summary.dart';
import '../services/daily_summary_service.dart';
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

  DailySummary? _todaySummary;
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
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
      if (mounted) {
        setState(() {
          _todaySummary = summary;
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
      if (mounted) {
        setState(() {
          _todaySummary = summary;
          _isGenerating = false;
        });
        _fadeController.reset();
        _fadeController.forward();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已重新生成睡前内容')),
        );
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
      MaterialPageRoute(
        builder: (context) => const BedtimeHistoryScreen(),
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
                _todaySummary!.isFavorite ? Icons.favorite : Icons.favorite_border,
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
    final dateStr = DateFormat('MM月dd日 EEEE', 'zh_CN').format(_todaySummary!.date);
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
    // 生成情绪数据摘要
    final dateStr = DateFormat('MM月dd日', 'zh_CN').format(_todaySummary!.date);
    final emotionSummary = '${_todaySummary!.emotionReview.substring(0, _todaySummary!.emotionReview.length > 50 ? 50 : _todaySummary!.emotionReview.length)}...';

    return ImpressionImageBanner(
      emotionSummary: emotionSummary,
      timeRange: dateStr,
      height: 180,
    );
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
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
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

/// 睡前阅读历史页面
class BedtimeHistoryScreen extends StatefulWidget {
  const BedtimeHistoryScreen({super.key});

  @override
  State<BedtimeHistoryScreen> createState() => _BedtimeHistoryScreenState();
}

class _BedtimeHistoryScreenState extends State<BedtimeHistoryScreen> {
  final DailySummaryService _summaryService = DailySummaryService.instance;

  List<DailySummary> _summaries = [];
  bool _isLoading = true;
  bool _showOnlyFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summaries = await _summaryService.getHistorySummaries(
        limit: 60,
        onlyFavorites: _showOnlyFavorites,
      );
      if (mounted) {
        setState(() {
          _summaries = summaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
    });
    _loadHistory();
  }

  void _viewSummary(DailySummary summary) {
    // TODO: 实现查看具体某天的睡前内容
    // 可以复用 BedtimeReadingScreen 或创建一个详情页面
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('历史记录'),
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            )
          : _summaries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _summaries.length,
                  itemBuilder: (context, index) {
                    final summary = _summaries[index];
                    return _buildHistoryItem(summary);
                  },
                ),
    );
  }

  Widget _buildHistoryItem(DailySummary summary) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MM月dd日', 'zh_CN').format(summary.date);
    final isToday = summary.isToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          summary.isFavorite ? Icons.favorite : Icons.bedtime_outlined,
          color: summary.isFavorite ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
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
            summary.eventSummary.length > 50
                ? '${summary.eventSummary.substring(0, 50)}...'
                : summary.eventSummary,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        onTap: () => _viewSummary(summary),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyFavorites ? Icons.favorite_border : Icons.history,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyFavorites ? '暂无收藏' : '暂无历史记录',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
