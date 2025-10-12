import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/insight_report.dart';
import '../models/mood_entry.dart';
import '../services/insight_report_service.dart';
import '../widgets/impression_image_banner.dart';

/// 心理洞察报告主屏幕
///
/// 设计理念：
/// 1. 参考睡前阅读的优秀UI设计
/// 2. 双入口：生成新报告 + 查看历史
/// 3. 清晰的三段式内容展示
/// 4. 支持收藏和历史管理
class InsightReportScreen extends StatefulWidget {
  const InsightReportScreen({super.key});

  @override
  State<InsightReportScreen> createState() => _InsightReportScreenState();
}

class _InsightReportScreenState extends State<InsightReportScreen> {
  final InsightReportService _reportService = InsightReportService.instance;

  List<InsightReport> _historyReports = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final reports = await _reportService.getHistoryReports(limit: 20);
      if (mounted) {
        setState(() {
          _historyReports = reports;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  void _generateWeeklyReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportGenerationScreen(
          reportType: ReportType.weekly,
        ),
      ),
    ).then((_) => _loadHistory());
  }

  void _generateMonthlyReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReportGenerationScreen(
          reportType: ReportType.monthly,
        ),
      ),
    ).then((_) => _loadHistory());
  }

  void _viewReport(InsightReport report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    ).then((_) => _loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('心理洞察报告'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 生成新报告section
            _buildGenerationSection(),
            const SizedBox(height: 32),

            // 历史报告section
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationSection() {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  '生成新报告',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '基于CBT认知行为疗法框架，深度分析你的情绪模式',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 周报按钮
            _buildReportTypeButton(
              icon: Icons.calendar_view_week,
              title: '本周心理洞察',
              subtitle: '7天深度分析',
              color: const Color(0xFF5c6bc0),
              onTap: _generateWeeklyReport,
            ),
            const SizedBox(height: 12),

            // 月报按钮
            _buildReportTypeButton(
              icon: Icons.calendar_month,
              title: '本月心理洞察',
              subtitle: '30天回顾总结',
              color: const Color(0xFF7e57c2),
              onTap: _generateMonthlyReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '历史报告',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoadingHistory)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            ),
          )
        else if (_historyReports.isEmpty)
          _buildEmptyHistoryState()
        else
          ..._historyReports.map((report) => _buildHistoryItem(report)),
      ],
    );
  }

  Widget _buildHistoryItem(InsightReport report) {
    final theme = Theme.of(context);
    final icon = report.type == ReportType.weekly
        ? Icons.calendar_view_week
        : Icons.calendar_month;
    final color = report.type == ReportType.weekly
        ? const Color(0xFF5c6bc0)
        : const Color(0xFF7e57c2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewReport(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (report.isFavorite)
                          Icon(
                            Icons.favorite,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.dateRangeDescription,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.stats.totalEntries}条记录 · 平均${report.stats.averageScore.toStringAsFixed(1)}分',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无历史报告',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '生成第一份心理洞察报告吧',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 报告生成页面
class ReportGenerationScreen extends StatefulWidget {
  final ReportType reportType;

  const ReportGenerationScreen({
    super.key,
    required this.reportType,
  });

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  final InsightReportService _reportService = InsightReportService.instance;
  bool _isGenerating = true;
  InsightReport? _report;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport({bool forceRegenerate = false}) async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final InsightReport report;
      if (widget.reportType == ReportType.weekly) {
        report = await _reportService.generateCurrentWeeklyReport(
          forceRegenerate: forceRegenerate,
        );
      } else {
        report = await _reportService.generateCurrentMonthlyReport(
          forceRegenerate: forceRegenerate,
        );
      }

      if (mounted) {
        setState(() {
          _report = report;
          _isGenerating = false;
        });

        // 标记为已读
        await _reportService.markAsRead(report.id);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '生成失败：$e';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isGenerating) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'AI正在深度分析你的情绪模式...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Text(
                      '这可能需要30秒至2分钟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '网络不稳定时会自动重试',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.primary.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
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
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _generateReport(forceRegenerate: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_report == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('未知错误'),
        ),
      );
    }

    // 显示报告详情
    return ReportDetailScreen(report: _report!);
  }
}

/// 报告详情页面
class ReportDetailScreen extends StatefulWidget {
  final InsightReport report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with SingleTickerProviderStateMixin {
  final InsightReportService _reportService = InsightReportService.instance;
  late InsightReport _report;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    await _reportService.toggleFavorite(_report.id);

    if (!mounted) return;

    setState(() {
      _report = _report.copyWith(isFavorite: !_report.isFavorite);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_report.isFavorite ? '已收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
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
        title: Text(_report.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _report.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleFavorite,
            tooltip: _report.isFavorite ? '取消收藏' : '收藏',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImpressionBanner(),
              const SizedBox(height: 24),
              _buildStatsOverview(),
              const SizedBox(height: 32),
              _buildCoreInsightSection(),
              const SizedBox(height: 32),
              _buildEmotionPatternSection(),
              const SizedBox(height: 32),
              _buildBehaviorSuggestionSection(),
              const SizedBox(height: 48),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpressionBanner() {
    return ImpressionImageBanner(
      emotionSummary: _buildReportEmotionSummary(),
      timeRange: _report.dateRangeDescription,
      height: 200,
    );
  }

  String _buildReportEmotionSummary() {
    final stats = _report.stats;
    final lines = <String>[
      '周期情绪概览：平均分 ${stats.averageScore.toStringAsFixed(1)} · ${stats.dominantMood?.displayName ?? "情绪多样"}为主 · 共 ${stats.totalEntries} 条记录',
    ];

    if (stats.topTags.isNotEmpty) {
      final tagPreview = stats.topTags.take(4).join('、');
      lines.add('高频主题：$tagPreview');
    }

    if (_report.coreInsight.isNotEmpty) {
      lines.add('核心洞察：${_truncate(_report.coreInsight)}');
    }

    if (_report.emotionPattern.isNotEmpty) {
      lines.add('情绪模式：${_truncate(_report.emotionPattern)}');
    }

    return lines.join('\n');
  }

  String _truncate(String text, {int maxLength = 220}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}…';
  }

  Widget _buildStatsOverview() {
    final theme = Theme.of(context);
    final stats = _report.stats;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '数据概览',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildStatItem(
                  label: '记录数',
                  value: '${stats.totalEntries}条',
                ),
                _buildStatItem(
                  label: '平均分',
                  value: stats.averageScore.toStringAsFixed(1),
                ),
                if (stats.dominantMood != null)
                  _buildStatItem(
                    label: '主导情绪',
                    value: stats.dominantMood!.displayName,
                  ),
                _buildStatItem(
                  label: '波动度',
                  value: stats.emotionVolatility.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCoreInsightSection() {
    return _buildContentSection(
      icon: Icons.wb_incandescent_outlined,
      iconColor: const Color(0xFFffa726),
      title: '核心洞察',
      content: _report.coreInsight,
    );
  }

  Widget _buildEmotionPatternSection() {
    return _buildContentSection(
      icon: Icons.timeline,
      iconColor: const Color(0xFF66bb6a),
      title: '情绪模式分析',
      content: _report.emotionPattern,
    );
  }

  Widget _buildBehaviorSuggestionSection() {
    return _buildContentSection(
      icon: Icons.lightbulb_outline,
      iconColor: const Color(0xFF42a5f5),
      title: '行为建议',
      content: _report.behaviorSuggestion,
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
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
                letterSpacing: 1.0,
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
              fontSize: 16,
              height: 1.8,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final theme = Theme.of(context);
    final generatedDate = DateFormat('yyyy年MM月dd日 HH:mm', 'zh_CN')
        .format(_report.generatedAt);

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.psychology,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '生成于 $generatedDate',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
