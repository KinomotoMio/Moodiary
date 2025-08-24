import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../screens/mood_detail_screen.dart';

class NavigationUtils {
  /// 统一的记录详情页导航方法
  /// 
  /// `context` - 导航上下文
  /// `entry` - 心情记录条目
  /// `heroTag` - Hero动画标签，用于流畅过渡
  /// 
  /// Returns: `Future<bool?>` - 如果记录被修改或删除，返回true
  static Future<bool?> navigateToMoodDetail(
    BuildContext context, 
    MoodEntry entry, {
    String? heroTag,
  }) async {
    return await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          MoodDetailScreen(entry: entry),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 从右滑入动画效果，类似iOS原生导航
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var slideTween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
            CurveTween(curve: curve),
          );

          // 结合滑动和淡入效果
          return SlideTransition(
            position: animation.drive(slideTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// 创建Hero动画的记录卡片导航
  /// 
  /// `context` - 导航上下文
  /// `entry` - 心情记录条目
  /// `heroTag` - Hero动画标签
  /// `child` - 要包裹Hero动画的子组件
  /// 
  /// Returns: Widget - 包装了Hero动画的组件
  static Widget createHeroNavigationCard(
    BuildContext context,
    MoodEntry entry,
    String heroTag,
    Widget child,
  ) {
    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigateToMoodDetail(context, entry, heroTag: heroTag),
          child: child,
        ),
      ),
    );
  }

  /// 获取记录的Hero标签
  /// 
  /// `entryId` - 记录ID
  /// `prefix` - 标签前缀，用于区分不同来源
  /// 
  /// Returns: String - Hero动画标签
  static String getHeroTag(String entryId, String prefix) {
    return '${prefix}_mood_card_$entryId';
  }

  /// 处理记录详情页返回结果
  /// 
  /// `result` - 详情页返回结果
  /// `onDataChanged` - 数据变更回调
  /// 
  static void handleDetailResult(bool? result, VoidCallback? onDataChanged) {
    if (result == true && onDataChanged != null) {
      onDataChanged();
    }
  }

  /// 创建统一的记录卡片点击处理
  /// 
  /// `context` - 上下文
  /// `entry` - 记录条目
  /// `onResult` - 结果回调
  /// `heroTag` - Hero标签
  /// 
  /// Returns: VoidCallback - 点击处理函数
  static VoidCallback createMoodCardTapHandler(
    BuildContext context,
    MoodEntry entry, {
    Function(bool?)? onResult,
    String? heroTag,
  }) {
    return () async {
      final result = await navigateToMoodDetail(context, entry, heroTag: heroTag);
      if (onResult != null) {
        onResult(result);
      }
    };
  }
}