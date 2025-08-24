import 'package:flutter/material.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';

/// 搜索筛选条件
class SearchCriteria {
  final String? textQuery;
  final MoodType? moodFilter;
  final TimeFilter? timeFilter;
  final RangeValues? scoreRange;
  final MediaFilter? mediaFilter;

  const SearchCriteria({
    this.textQuery,
    this.moodFilter,
    this.timeFilter,
    this.scoreRange,
    this.mediaFilter,
  });

  bool get hasActiveFilters =>
      textQuery?.isNotEmpty == true ||
      moodFilter != null ||
      timeFilter != TimeFilter.all ||
      scoreRange != null && (scoreRange!.start > 0 || scoreRange!.end < 100) ||
      mediaFilter != MediaFilter.all;
}

/// 时间筛选选项
enum TimeFilter {
  all('全部时间'),
  today('今天'),
  week('本周'),
  month('本月');

  const TimeFilter(this.displayName);
  final String displayName;
}

/// 媒体类型筛选选项
enum MediaFilter {
  all('全部类型', Icons.all_inclusive),
  textOnly('纯文字', Icons.text_fields),
  withImage('包含图片', Icons.image),
  imageOnly('仅图片', Icons.photo),
  mixed('图文混合', Icons.collections);

  const MediaFilter(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// 统一搜索服务
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static SearchService get instance => _instance;

  /// 应用搜索筛选条件
  List<MoodFragment> filterFragments(
    List<MoodFragment> fragments,
    SearchCriteria criteria,
  ) {
    List<MoodFragment> filtered = List.from(fragments);

    // 文本搜索筛选（包括内容和标签）
    if (criteria.textQuery != null && criteria.textQuery!.trim().isNotEmpty) {
      final query = criteria.textQuery!.toLowerCase().trim();
      filtered = filtered.where((fragment) {
        final contentMatch =
            fragment.textContent?.toLowerCase().contains(query) ?? false;
        final tagMatch = fragment.topicTags
            .any((tag) => tag.toLowerCase().contains(query));
        return contentMatch || tagMatch;
      }).toList();
    }

    // 情绪类型筛选
    if (criteria.moodFilter != null) {
      filtered = filtered.where((fragment) {
        return fragment.mood == criteria.moodFilter;
      }).toList();
    }

    // 时间筛选
    if (criteria.timeFilter != null && criteria.timeFilter != TimeFilter.all) {
      final now = DateTime.now();
      DateTime startDate;

      switch (criteria.timeFilter!) {
        case TimeFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case TimeFilter.week:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case TimeFilter.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case TimeFilter.all:
          startDate = DateTime(1970);
          break;
      }

      filtered = filtered.where((fragment) {
        return fragment.timestamp.isAfter(startDate);
      }).toList();
    }

    // 评分筛选
    if (criteria.scoreRange != null) {
      filtered = filtered.where((fragment) {
        return fragment.emotionScore >= criteria.scoreRange!.start &&
            fragment.emotionScore <= criteria.scoreRange!.end;
      }).toList();
    }

    // 媒体类型筛选
    if (criteria.mediaFilter != null &&
        criteria.mediaFilter != MediaFilter.all) {
      filtered = filtered.where((fragment) {
        switch (criteria.mediaFilter!) {
          case MediaFilter.textOnly:
            return fragment.type == FragmentType.text;
          case MediaFilter.withImage:
            return fragment.type == FragmentType.image ||
                fragment.type == FragmentType.mixed;
          case MediaFilter.imageOnly:
            return fragment.type == FragmentType.image;
          case MediaFilter.mixed:
            return fragment.type == FragmentType.mixed;
          case MediaFilter.all:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  /// 获取筛选结果统计
  SearchStats getSearchStats(
    List<MoodFragment> originalFragments,
    List<MoodFragment> filteredFragments,
  ) {
    return SearchStats(
      totalCount: originalFragments.length,
      filteredCount: filteredFragments.length,
      hasResults: filteredFragments.isNotEmpty,
    );
  }
}

/// 搜索结果统计
class SearchStats {
  final int totalCount;
  final int filteredCount;
  final bool hasResults;

  const SearchStats({
    required this.totalCount,
    required this.filteredCount,
    required this.hasResults,
  });

  double get filterRatio =>
      totalCount > 0 ? filteredCount / totalCount : 0.0;
}

