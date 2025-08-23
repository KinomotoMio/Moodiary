import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';
import '../events/app_events.dart';
import 'storage_service.dart';

class FragmentStorageService {
  static const String _fragmentsKey = 'mood_fragments';
  static const String _topicTagsKey = 'topic_tags';
  static const String _migrationKey = 'fragment_migration_completed';
  
  static FragmentStorageService? _instance;
  static FragmentStorageService get instance => _instance ??= FragmentStorageService._();
  
  FragmentStorageService._();
  
  late SharedPreferences _prefs;
  final StorageService _legacyStorage = StorageService.instance;
  
  // 初始化服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateLegacyData();
  }
  
  // 迁移旧数据到新的Fragment模型
  Future<void> _migrateLegacyData() async {
    final migrationCompleted = _prefs.getBool(_migrationKey) ?? false;
    if (migrationCompleted) return;
    
    debugPrint('Starting migration from MoodEntry to MoodFragment...');
    
    try {
      // 获取旧的MoodEntry数据
      final legacyEntries = await _legacyStorage.getAllMoodEntries();
      
      if (legacyEntries.isNotEmpty) {
        // 转换为Fragment
        final fragments = legacyEntries.map((entry) => 
          MoodFragment.fromMoodEntry(entry)
        ).toList();
        
        // 保存到新存储
        await _saveFragments(fragments);
        
        debugPrint('Migrated ${fragments.length} entries to fragments');
        
        // 提取并保存话题标签
        await _updateTopicTags(fragments);
      }
      
      // 标记迁移完成
      await _prefs.setBool(_migrationKey, true);
      debugPrint('Migration completed successfully');
      
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }
  
  // 保存单个Fragment
  Future<void> saveFragment(MoodFragment fragment) async {
    final fragments = await getAllFragments();
    
    // 检查是否已存在，如果存在则更新，否则添加
    final existingIndex = fragments.indexWhere((f) => f.id == fragment.id);
    if (existingIndex != -1) {
      fragments[existingIndex] = fragment;
    } else {
      fragments.add(fragment);
    }
    
    // 更新话题标签（在保存和事件触发之前）
    if (fragment.hasTopicTags) {
      await _updateTopicTagsFromFragment(fragment);
    }
    
    await _saveFragments(fragments);
    
    // 发送事件
    final isUpdate = existingIndex != -1;
    if (isUpdate) {
      StorageService.eventBus.fire(MoodEntryUpdatedEvent(fragment.toMoodEntry()));
    } else {
      StorageService.eventBus.fire(MoodEntryAddedEvent(fragment.toMoodEntry()));
    }
    StorageService.eventBus.fire(MoodDataChangedEvent());
  }
  
  // 获取所有Fragment
  Future<List<MoodFragment>> getAllFragments() async {
    final jsonString = _prefs.getString(_fragmentsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => MoodFragment.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 按时间降序排列
    } catch (e) {
      debugPrint('Error parsing fragments: $e');
      return [];
    }
  }
  
  // 根据日期范围获取Fragment
  Future<List<MoodFragment>> getFragmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allFragments = await getAllFragments();
    return allFragments.where((fragment) {
      return fragment.timestamp.isAfter(startDate) && 
             fragment.timestamp.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
  
  // 根据话题标签获取Fragment
  Future<List<MoodFragment>> getFragmentsByTopicTag(String tag) async {
    final allFragments = await getAllFragments();
    return allFragments.where((fragment) {
      return fragment.topicTags.contains(tag);
    }).toList();
  }
  
  // 根据Fragment类型获取
  Future<List<MoodFragment>> getFragmentsByType(FragmentType type) async {
    final allFragments = await getAllFragments();
    return allFragments.where((fragment) => fragment.type == type).toList();
  }
  
  // 搜索Fragment（内容和标签）
  Future<List<MoodFragment>> searchFragments(String query) async {
    if (query.isEmpty) return getAllFragments();
    
    final allFragments = await getAllFragments();
    final lowerQuery = query.toLowerCase();
    
    return allFragments.where((fragment) {
      // 搜索文本内容
      final contentMatch = fragment.textContent?.toLowerCase().contains(lowerQuery) ?? false;
      
      // 搜索话题标签
      final tagMatch = fragment.topicTags.any((tag) => 
        tag.toLowerCase().contains(lowerQuery));
      
      return contentMatch || tagMatch;
    }).toList();
  }
  
  // 根据ID获取特定Fragment
  Future<MoodFragment?> getFragmentById(String id) async {
    final fragments = await getAllFragments();
    try {
      return fragments.firstWhere((fragment) => fragment.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // 删除Fragment
  Future<void> deleteFragment(String id) async {
    final fragments = await getAllFragments();
    fragments.removeWhere((fragment) => fragment.id == id);
    await _saveFragments(fragments);
    
    // 发送事件
    StorageService.eventBus.fire(MoodEntryDeletedEvent(id));
    StorageService.eventBus.fire(MoodDataChangedEvent());
  }
  
  // 清空所有Fragment
  Future<void> clearAllFragments() async {
    await _prefs.remove(_fragmentsKey);
    await _prefs.remove(_topicTagsKey);
    
    // 发送事件
    StorageService.eventBus.fire(DataClearedEvent());
    StorageService.eventBus.fire(MoodDataChangedEvent());
  }
  
  // 获取所有话题标签
  Future<List<TopicTag>> getAllTopicTags() async {
    final jsonString = _prefs.getString(_topicTagsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => TopicTag.fromJson(json))
          .toList()
        ..sort((a, b) => b.usageCount.compareTo(a.usageCount)); // 按使用频率排序
    } catch (e) {
      debugPrint('Error parsing topic tags: $e');
      return [];
    }
  }
  
  // 获取热门话题标签
  Future<List<TopicTag>> getPopularTopicTags({int limit = 10}) async {
    final allTags = await getAllTopicTags();
    return allTags.take(limit).toList();
  }
  
  // 兼容性方法：转换为MoodEntry列表（供现有代码使用）
  Future<List<MoodEntry>> getAllMoodEntries() async {
    final fragments = await getAllFragments();
    return fragments.map((fragment) => fragment.toMoodEntry()).toList();
  }
  
  // 兼容性方法：根据日期范围获取MoodEntry列表
  Future<List<MoodEntry>> getMoodEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final fragments = await getFragmentsByDateRange(startDate, endDate);
    return fragments.map((fragment) => fragment.toMoodEntry()).toList();
  }
  
  // 兼容性方法：获取心情统计数据
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
  
  // 兼容性方法：保存MoodEntry（自动转换为Fragment）
  Future<void> saveMoodEntry(MoodEntry entry) async {
    final fragment = MoodFragment.fromMoodEntry(entry);
    await saveFragment(fragment);
  }
  
  // 私有方法：保存Fragment列表
  Future<void> _saveFragments(List<MoodFragment> fragments) async {
    final jsonString = json.encode(fragments.map((f) => f.toJson()).toList());
    await _prefs.setString(_fragmentsKey, jsonString);
  }
  
  // 私有方法：更新话题标签统计
  Future<void> _updateTopicTags(List<MoodFragment> fragments) async {
    final Map<String, TopicTag> tagMap = {};
    
    // 获取现有标签
    final existingTags = await getAllTopicTags();
    for (final tag in existingTags) {
      tagMap[tag.name] = tag;
    }
    
    // 统计所有Fragment中的标签
    for (final fragment in fragments) {
      for (final tagName in fragment.topicTags) {
        if (tagMap.containsKey(tagName)) {
          // 更新现有标签
          final existing = tagMap[tagName]!;
          tagMap[tagName] = existing.copyWith(
            usageCount: existing.usageCount + 1,
          );
        } else {
          // 创建新标签
          tagMap[tagName] = TopicTag(
            name: tagName,
            firstUsed: fragment.timestamp,
            usageCount: 1,
          );
        }
      }
    }
    
    // 保存更新后的标签
    await _saveTopicTags(tagMap.values.toList());
  }
  
  // 私有方法：从单个Fragment更新话题标签
  Future<void> _updateTopicTagsFromFragment(MoodFragment fragment) async {
    final Map<String, TopicTag> tagMap = {};
    
    // 获取现有标签
    final existingTags = await getAllTopicTags();
    for (final tag in existingTags) {
      tagMap[tag.name] = tag;
    }
    
    // 更新Fragment中的标签
    for (final tagName in fragment.topicTags) {
      if (tagMap.containsKey(tagName)) {
        // 更新现有标签
        final existing = tagMap[tagName]!;
        tagMap[tagName] = existing.copyWith(
          usageCount: existing.usageCount + 1,
        );
      } else {
        // 创建新标签
        tagMap[tagName] = TopicTag(
          name: tagName,
          firstUsed: fragment.timestamp,
          usageCount: 1,
        );
      }
    }
    
    await _saveTopicTags(tagMap.values.toList());
  }
  
  // 私有方法：保存话题标签列表
  Future<void> _saveTopicTags(List<TopicTag> tags) async {
    final jsonString = json.encode(tags.map((t) => t.toJson()).toList());
    await _prefs.setString(_topicTagsKey, jsonString);
  }
  
  // 公共方法：重建话题标签统计（用于修复现有数据）
  Future<void> rebuildTopicTagsStatistics() async {
    final allFragments = await getAllFragments();
    await _updateTopicTags(allFragments);
    
    // 触发事件通知所有监听者数据已更新
    StorageService.eventBus.fire(MoodDataChangedEvent());
  }
}