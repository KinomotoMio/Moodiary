import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/fragment_storage_service.dart';
import '../services/storage_service.dart';
import '../events/app_events.dart';

/// GitHub风格的Contributions热力图组件
class ContributionsHeatmap extends StatefulWidget {
  const ContributionsHeatmap({super.key});

  @override
  State<ContributionsHeatmap> createState() => _ContributionsHeatmapState();
}

class _ContributionsHeatmapState extends State<ContributionsHeatmap> {
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  
  Map<DateTime, int> _dailyContributions = {};
  bool _isLoading = true;
  late DateTime _endDate;
  late DateTime _startDate;
  late StreamSubscription _moodDataSubscription;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _setupDateRange();
    _setupEventListeners();
    _loadContributionsData();
  }

  /// 设置事件监听器
  void _setupEventListeners() {
    _moodDataSubscription = StorageService.eventBus.on<MoodDataChangedEvent>().listen((event) {
      // 当心情数据发生变化时，重新加载贡献数据
      if (mounted) {
        _loadContributionsData();
      }
    });
  }

  @override
  void dispose() {
    _moodDataSubscription.cancel();
    super.dispose();
  }

  /// 设置日期范围 - 显示指定年份的数据
  void _setupDateRange() {
    // 设置为指定年份的完整年份
    _startDate = DateTime(_selectedYear, 1, 1);
    _endDate = DateTime(_selectedYear, 12, 31);
    
    // 调整开始日期到周日开始（GitHub风格）
    final startWeekday = _startDate.weekday == 7 ? 0 : _startDate.weekday;
    if (startWeekday != 0) {
      _startDate = _startDate.subtract(Duration(days: startWeekday));
    }
    
    // 调整结束日期到周六结束
    final endWeekday = _endDate.weekday == 7 ? 0 : _endDate.weekday;
    if (endWeekday != 6) {
      _endDate = _endDate.add(Duration(days: 6 - endWeekday));
    }
  }

  /// 加载贡献数据
  Future<void> _loadContributionsData() async {
    try {
      final fragments = await _fragmentStorage.getFragmentsByDateRange(
        _startDate, 
        _endDate.add(const Duration(days: 1)),
      );
      
      // 按日期统计记录数量
      final contributionsMap = <DateTime, int>{};
      
      for (final fragment in fragments) {
        final date = DateTime(
          fragment.timestamp.year,
          fragment.timestamp.month, 
          fragment.timestamp.day,
        );
        contributionsMap[date] = (contributionsMap[date] ?? 0) + 1;
      }
      
      setState(() {
        _dailyContributions = contributionsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 获取贡献强度颜色（0-4级别）
  Color _getContributionColor(int count, BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    
    if (count == 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.15);
    }
    
    // 根据记录数量计算强度级别
    final maxCount = _dailyContributions.values.isNotEmpty 
        ? _dailyContributions.values.reduce(max) 
        : 4;
    
    // 确保至少有4个级别的区分
    final normalizedCount = count.toDouble();
    final step = maxCount / 4.0;
    
    if (normalizedCount <= step) {
      return primary.withValues(alpha: 0.25);
    } else if (normalizedCount <= step * 2) {
      return primary.withValues(alpha: 0.45);
    } else if (normalizedCount <= step * 3) {
      return primary.withValues(alpha: 0.7);
    } else {
      return primary;
    }
  }

  /// 获取强度级别描述
  String _getIntensityDescription(int count) {
    if (count == 0) return '无记录';
    if (count == 1) return '1条记录';
    if (count <= 3) return '少量记录';
    if (count <= 6) return '适中记录';
    return '频繁记录';
  }

  /// 显示日期详情
  void _showDateDetails(DateTime date, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${date.year}年${date.month}月${date.day}日',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getContributionColor(count, context),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$count条情绪记录',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getIntensityDescription(count),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 16),
              Text(
                '点击"查看详情"可以查看当天的具体记录',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          if (count > 0)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 导航到具体日期的记录列表
              },
              child: const Text('查看详情'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和年份选择
            Row(
              children: [
                Icon(
                  Icons.grid_view,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '情绪记录热力图',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 年份选择下拉菜单
                _buildYearSelector(),
              ],
            ),
            const SizedBox(height: 8),
            
            // 统计信息
            Row(
              children: [
                Text(
                  '${_getTotalContributions()}条记录',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  ' 在$_selectedYear年',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 热力图网格
            _buildHeatmapGrid(),
            const SizedBox(height: 16),
            
            // 图例
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// 构建热力图网格
  Widget _buildHeatmapGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算响应式尺寸
        final totalWidth = constraints.maxWidth - 40; // 预留padding
        final labelWidth = 30.0; // 星期标签宽度
        const gap = 2.0;
        
        final totalDays = _endDate.difference(_startDate).inDays + 1;
        final weeks = (totalDays / 7).ceil();
        
        // 计算每个方块的最佳尺寸
        final availableWidth = totalWidth - labelWidth;
        final squareSize = ((availableWidth - (weeks * gap)) / weeks).clamp(8.0, 12.0);
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧星期标签
                SizedBox(
                  width: labelWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: 20), // 月份标签空间
                      ...['', '一', '', '三', '', '五', ''].map((day) => Container(
                        height: squareSize + gap,
                        alignment: Alignment.centerRight,
                        child: Text(
                          day,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // 热力图主体
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 月份标签
                    _buildMonthLabels(weeks, squareSize, gap),
                    const SizedBox(height: 4),
                    
                    // 热力图方格网格
                    Row(
                      children: List.generate(weeks, (weekIndex) {
                        return Column(
                          children: List.generate(7, (dayIndex) {
                            final dayOffset = weekIndex * 7 + dayIndex;
                            final date = _startDate.add(Duration(days: dayOffset));
                            
                            final isValidDate = !date.isBefore(DateTime(_selectedYear, 1, 1)) &&
                                               !date.isAfter(DateTime(_selectedYear, 12, 31));
                            
                            if (!isValidDate) {
                              return Container(
                                width: squareSize,
                                height: squareSize,
                                margin: EdgeInsets.all(gap / 2),
                              );
                            }
                            
                            final count = _dailyContributions[date] ?? 0;
                            
                            return Container(
                              width: squareSize,
                              height: squareSize,
                              margin: EdgeInsets.all(gap / 2),
                              child: Tooltip(
                                message: '${date.month}月${date.day}日: $count条记录',
                                child: InkWell(
                                  onTap: () => _showDateDetails(date, count),
                                  borderRadius: BorderRadius.circular(2),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getContributionColor(count, context),
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建月份标签
  Widget _buildMonthLabels(int weeks, double squareSize, double gap) {
    final labels = <Widget>[];
    final monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', 
                      '7月', '8月', '9月', '10月', '11月', '12月'];
    
    for (int month = 1; month <= 12; month++) {
      // 计算该月1号在网格中的位置
      final monthStart = DateTime(_selectedYear, month, 1);
      final daysSinceGridStart = monthStart.difference(_startDate).inDays;
      
      // 只显示在网格范围内且在月初几天的月份标签
      if (daysSinceGridStart >= 0 && daysSinceGridStart < weeks * 7) {
        final weekOffset = (daysSinceGridStart / 7).floor();
        
        // 确保月份标签显示在合理位置（月初几天内）
        final dayInMonth = monthStart.difference(_startDate).inDays % 7;
        if (dayInMonth <= 6) { // 该月1号在该周内
          labels.add(
            Positioned(
              left: weekOffset * (squareSize + gap),
              child: Text(
                monthNames[month - 1],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
          );
        }
      }
    }
    
    return SizedBox(
      height: 16,
      width: weeks * (squareSize + gap),
      child: Stack(children: labels),
    );
  }

  /// 构建年份选择器
  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final availableYears = List.generate(5, (index) => currentYear - index);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: Theme.of(context).colorScheme.primary,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: availableYears.map((year) => DropdownMenuItem(
            value: year,
            child: Text('$year'),
          )).toList(),
          onChanged: (year) {
            if (year != null && year != _selectedYear) {
              setState(() {
                _selectedYear = year;
                _setupDateRange();
                _loadContributionsData();
              });
            }
          },
        ),
      ),
    );
  }

  /// 获取总记录数
  int _getTotalContributions() {
    return _dailyContributions.values.fold(0, (sum, count) => sum + count);
  }

  /// 构建图例
  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          '少',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          // 生成0, 1, 2, 3, 4级别的示例颜色
          final count = index == 0 ? 0 : index;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getContributionColor(count, context),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '多',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}