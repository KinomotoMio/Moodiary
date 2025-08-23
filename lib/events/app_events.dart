// 应用事件定义
// 用于在不同页面和组件之间进行数据同步和状态更新

import '../models/mood_entry.dart';

/// 基础事件类
abstract class AppEvent {
  final DateTime timestamp;
  
  AppEvent() : timestamp = DateTime.now();
}

/// ===================
/// 数据相关事件
/// ===================

/// 心情数据变化事件 - 当心情记录发生任何变化时触发
class MoodDataChangedEvent extends AppEvent {}

/// 心情记录添加事件
class MoodEntryAddedEvent extends AppEvent {
  final MoodEntry entry;
  
  MoodEntryAddedEvent(this.entry);
}

/// 心情记录更新事件
class MoodEntryUpdatedEvent extends AppEvent {
  final MoodEntry entry;
  
  MoodEntryUpdatedEvent(this.entry);
}

/// 心情记录删除事件
class MoodEntryDeletedEvent extends AppEvent {
  final String entryId;
  
  MoodEntryDeletedEvent(this.entryId);
}

/// 数据清空事件
class DataClearedEvent extends AppEvent {}

/// 测试数据添加事件
class TestDataAddedEvent extends AppEvent {
  final int count;
  
  TestDataAddedEvent(this.count);
}

/// ===================
/// UI/设置相关事件
/// ===================

/// 主题变化事件
class ThemeChangedEvent extends AppEvent {
  final ThemeMode themeMode;
  
  ThemeChangedEvent(this.themeMode);
}

/// 语言变化事件
class LanguageChangedEvent extends AppEvent {
  final String languageCode;
  
  LanguageChangedEvent(this.languageCode);
}

/// ===================
/// 分析相关事件
/// ===================

/// 分析数据刷新事件
class AnalyticsRefreshEvent extends AppEvent {}

/// 统计数据更新事件
class StatisticsUpdatedEvent extends AppEvent {}

/// ===================
/// 导航相关事件
/// ===================

/// 导航到首页事件
class NavigateToHomeEvent extends AppEvent {}

/// 导航到历史页面事件
class NavigateToHistoryEvent extends AppEvent {}

/// 导航到分析页面事件
class NavigateToAnalyticsEvent extends AppEvent {}

/// ===================
/// 枚举定义
/// ===================

enum ThemeMode {
  system,
  light,
  dark,
}