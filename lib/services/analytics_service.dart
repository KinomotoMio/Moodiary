import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/mood_entry.dart';
import 'storage_service.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  
  AnalyticsService._();
  
  StorageService get _storageService => StorageService.instance;
  
  // 获取情绪趋势数据（用于折线图）
  Future<List<FlSpot>> getMoodTrendData({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final entries = await _storageService.getMoodEntriesByDateRange(startDate, endDate);
    
    if (entries.isEmpty) return [];
    
    // 按日期分组并计算每日平均情绪分数
    final dailyScores = <DateTime, List<int>>{};
    
    for (final entry in entries) {
      final day = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      dailyScores.putIfAbsent(day, () => []).add(entry.emotionScore);
    }
    
    // 生成趋势数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      
      double averageScore = 0;
      if (dailyScores.containsKey(dayKey)) {
        final scores = dailyScores[dayKey]!;
        averageScore = scores.reduce((a, b) => a + b) / scores.length;
      }
      
      spots.add(FlSpot(i.toDouble(), averageScore));
    }
    
    return spots;
  }
  
  // 获取情绪分布数据（用于饼状图）
  Future<List<PieChartSectionData>> getMoodDistributionData({int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final entries = await _storageService.getMoodEntriesByDateRange(startDate, endDate);
    
    if (entries.isEmpty) return [];
    
    // 统计各情绪类型数量
    final moodCounts = <MoodType, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    
    final colors = {
      MoodType.positive: Color(0xFF4CAF50),  // 绿色
      MoodType.neutral: Color(0xFFFF9800),   // 橙色  
      MoodType.negative: Color(0xFFF44336),  // 红色
    };
    
    final sections = <PieChartSectionData>[];
    moodCounts.forEach((mood, count) {
      final percentage = (count / entries.length) * 100;
      sections.add(
        PieChartSectionData(
          color: colors[mood]!,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });
    
    return sections;
  }
  
  // 获取记录频率数据（用于柱状图）
  Future<List<BarChartGroupData>> getRecordFrequencyData({int days = 7}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final entries = await _storageService.getMoodEntriesByDateRange(startDate, endDate);
    
    // 按日期统计记录数量
    final dailyCounts = <DateTime, int>{};
    
    for (final entry in entries) {
      final day = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
    }
    
    // 生成柱状图数据
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      final count = dailyCounts[dayKey] ?? 0;
      
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Color(0xFF6B73FF),
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return groups;
  }
  
  // 获取情绪洞察报告
  Future<MoodInsightsReport> getMoodInsights({int days = 30}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final entries = await _storageService.getMoodEntriesByDateRange(startDate, endDate);
    
    if (entries.isEmpty) {
      return MoodInsightsReport.empty();
    }
    
    // 计算基础统计数据
    final totalEntries = entries.length;
    final averageScore = entries.map((e) => e.emotionScore).reduce((a, b) => a + b) / totalEntries;
    
    // 情绪分布统计
    final moodCounts = <MoodType, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }
    
    // 计算趋势（与上周期对比）
    final previousPeriodStart = startDate.subtract(Duration(days: days));
    final previousEntries = await _storageService.getMoodEntriesByDateRange(previousPeriodStart, startDate);
    
    double trendPercentage = 0;
    if (previousEntries.isNotEmpty) {
      final previousAverage = previousEntries.map((e) => e.emotionScore).reduce((a, b) => a + b) / previousEntries.length;
      trendPercentage = ((averageScore - previousAverage) / previousAverage) * 100;
    }
    
    // 最活跃的记录时段
    final hourCounts = <int, int>{};
    for (final entry in entries) {
      final hour = entry.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    int mostActiveHour = 12;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        mostActiveHour = hour;
      }
    });
    
    // 连续记录天数
    int streakDays = await _calculateRecordStreak(entries);
    
    return MoodInsightsReport(
      totalEntries: totalEntries,
      averageScore: averageScore,
      moodDistribution: moodCounts,
      trendPercentage: trendPercentage,
      mostActiveHour: mostActiveHour,
      streakDays: streakDays,
      period: days,
    );
  }
  
  // 计算连续记录天数
  Future<int> _calculateRecordStreak(List<MoodEntry> entries) async {
    if (entries.isEmpty) return 0;
    
    // 获取所有有记录的日期
    final recordedDates = entries
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // 从最新日期开始
    
    if (recordedDates.isEmpty) return 0;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // 检查今天是否有记录，如果没有从昨天开始计算
    DateTime currentDate = recordedDates.first.isAtSameMomentAs(todayDate) 
        ? todayDate 
        : todayDate.subtract(const Duration(days: 1));
    
    int streak = 0;
    
    for (final recordDate in recordedDates) {
      if (recordDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (recordDate.isBefore(currentDate)) {
        // 如果记录日期早于当前检查日期，说明中断了
        break;
      }
    }
    
    return streak;
  }
  
  // 获取本周和本月快速统计
  Future<QuickStats> getQuickStats() async {
    final now = DateTime.now();
    
    // 本周数据（从周一开始）
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEntries = await _storageService.getMoodEntriesByDateRange(weekStart, now);
    
    // 本月数据
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEntries = await _storageService.getMoodEntriesByDateRange(monthStart, now);
    
    return QuickStats(
      weekCount: weekEntries.length,
      weekAverage: weekEntries.isEmpty ? 0 : 
          weekEntries.map((e) => e.emotionScore).reduce((a, b) => a + b) / weekEntries.length,
      monthCount: monthEntries.length,
      monthAverage: monthEntries.isEmpty ? 0 :
          monthEntries.map((e) => e.emotionScore).reduce((a, b) => a + b) / monthEntries.length,
    );
  }
}

// 情绪洞察报告数据类
class MoodInsightsReport {
  final int totalEntries;
  final double averageScore;
  final Map<MoodType, int> moodDistribution;
  final double trendPercentage;
  final int mostActiveHour;
  final int streakDays;
  final int period;
  
  const MoodInsightsReport({
    required this.totalEntries,
    required this.averageScore,
    required this.moodDistribution,
    required this.trendPercentage,
    required this.mostActiveHour,
    required this.streakDays,
    required this.period,
  });
  
  factory MoodInsightsReport.empty() {
    return const MoodInsightsReport(
      totalEntries: 0,
      averageScore: 0,
      moodDistribution: {},
      trendPercentage: 0,
      mostActiveHour: 12,
      streakDays: 0,
      period: 30,
    );
  }
  
  // 获取主导情绪类型
  MoodType? get dominantMoodType {
    if (moodDistribution.isEmpty) return null;
    
    return moodDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  // 获取情绪趋势描述
  String get trendDescription {
    if (trendPercentage.abs() < 1) return '保持稳定';
    if (trendPercentage > 0) return '情绪向好 +${trendPercentage.toStringAsFixed(1)}%';
    return '需要关注 ${trendPercentage.toStringAsFixed(1)}%';
  }
  
  // 获取最活跃时段描述
  String get activeTimeDescription {
    if (mostActiveHour < 6) return '深夜时光';
    if (mostActiveHour < 12) return '上午时光';
    if (mostActiveHour < 18) return '下午时光';
    return '晚间时光';
  }
}

// 快速统计数据类
class QuickStats {
  final int weekCount;
  final double weekAverage;
  final int monthCount;
  final double monthAverage;
  
  const QuickStats({
    required this.weekCount,
    required this.weekAverage,
    required this.monthCount,
    required this.monthAverage,
  });
}