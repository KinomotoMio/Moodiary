import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_entry.dart';

class StorageService {
  static const String _moodEntriesKey = 'mood_entries';
  
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  
  StorageService._();
  
  late SharedPreferences _prefs;
  
  // 初始化服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // 保存单个心情记录
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final entries = await getAllMoodEntries();
    
    // 检查是否已存在，如果存在则更新，否则添加
    final existingIndex = entries.indexWhere((e) => e.id == entry.id);
    if (existingIndex != -1) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }
    
    await _saveMoodEntries(entries);
  }
  
  // 获取所有心情记录
  Future<List<MoodEntry>> getAllMoodEntries() async {
    final jsonString = _prefs.getString(_moodEntriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MoodEntry.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 按时间降序排列
    } catch (e) {
      // 如果解析失败，返回空列表
      debugPrint('Error parsing mood entries: $e');
      return [];
    }
  }
  
  // 根据日期范围获取心情记录
  Future<List<MoodEntry>> getMoodEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allEntries = await getAllMoodEntries();
    return allEntries.where((entry) {
      return entry.timestamp.isAfter(startDate) && 
             entry.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  // 根据ID获取特定心情记录
  Future<MoodEntry?> getMoodEntryById(String id) async {
    final entries = await getAllMoodEntries();
    try {
      return entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // 删除心情记录
  Future<void> deleteMoodEntry(String id) async {
    final entries = await getAllMoodEntries();
    entries.removeWhere((entry) => entry.id == id);
    await _saveMoodEntries(entries);
  }
  
  // 清空所有心情记录
  Future<void> clearAllMoodEntries() async {
    await _prefs.remove(_moodEntriesKey);
  }
  
  // 获取心情统计数据
  Future<MoodStatistics> getMoodStatistics([DateTime? startDate, DateTime? endDate]) async {
    List<MoodEntry> entries;
    
    if (startDate != null && endDate != null) {
      entries = await getMoodEntriesByDateRange(startDate, endDate);
    } else {
      entries = await getAllMoodEntries();
    }
    
    if (entries.isEmpty) {
      return MoodStatistics.empty();
    }
    
    // 统计各种情绪类型的数量
    final moodCounts = <MoodType, int>{};
    int totalScore = 0;
    
    for (final entry in entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      totalScore += entry.emotionScore;
    }
    
    return MoodStatistics(
      totalEntries: entries.length,
      averageScore: totalScore / entries.length,
      moodCounts: moodCounts,
      dateRange: entries.isNotEmpty ? 
        DateRange(
          start: entries.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b),
          end: entries.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
        ) : null,
    );
  }
  
  // 私有方法：保存心情记录列表
  Future<void> _saveMoodEntries(List<MoodEntry> entries) async {
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await _prefs.setString(_moodEntriesKey, jsonString);
  }
}

// 心情统计数据类
class MoodStatistics {
  final int totalEntries;
  final double averageScore;
  final Map<MoodType, int> moodCounts;
  final DateRange? dateRange;
  
  const MoodStatistics({
    required this.totalEntries,
    required this.averageScore,
    required this.moodCounts,
    this.dateRange,
  });
  
  factory MoodStatistics.empty() {
    return const MoodStatistics(
      totalEntries: 0,
      averageScore: 0.0,
      moodCounts: {},
    );
  }
  
  // 获取主导情绪类型
  MoodType? get dominantMoodType {
    if (moodCounts.isEmpty) return null;
    
    return moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

// 日期范围类
class DateRange {
  final DateTime start;
  final DateTime end;
  
  const DateRange({
    required this.start,
    required this.end,
  });
  
  Duration get duration => end.difference(start);
  
  bool contains(DateTime date) {
    return date.isAfter(start) && date.isBefore(end);
  }
}