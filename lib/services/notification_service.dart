import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知服务
///
/// 提供定时提醒功能
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const int _dailyReminderId = 0;

  /// 初始化通知服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 初始化时区数据
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

      // 请求通知权限
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          if (kDebugMode) {
            debugPrint('Notification permission denied');
          }
          return false;
        }
      }

      // Android设置
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS/macOS设置
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      // 初始化插件
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = initialized ?? false;
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize notifications: $e');
      }
      return false;
    }
  }

  /// 处理通知点击事件
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${response.payload}');
    }
    // TODO: 导航到睡前阅读页面
  }

  /// 设置每日提醒
  Future<bool> setDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      // 取消现有提醒
      await cancelDailyReminder();

      // 设置新提醒时间
      final now = tz.TZDateTime.now(tz.local);
      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // 如果时间已过，设置为明天
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Android通知详情
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder',
        '每日提醒',
        channelDescription: '提醒你记录今天的心情',
        importance: Importance.high,
        priority: Priority.high,
      );

      // iOS/macOS通知详情
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // 调度每日重复通知
      await _notifications.zonedSchedule(
        _dailyReminderId,
        '记录今天的心情吧 📝',
        '回顾今天的经历，整理你的情绪，让心情日记陪伴你～',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // 每天重复
      );

      // 保存设置
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, true);
      await prefs.setString(
        _reminderTimeKey,
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );

      if (kDebugMode) {
        debugPrint('Daily reminder set for $hour:$minute');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to set daily reminder: $e');
      }
      return false;
    }
  }

  /// 取消每日提醒
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(_dailyReminderId);

      // 更新设置
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_reminderEnabledKey, false);

      if (kDebugMode) {
        debugPrint('Daily reminder cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to cancel daily reminder: $e');
      }
    }
  }

  /// 获取提醒是否启用
  Future<bool> isReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  /// 获取提醒时间
  Future<String?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_reminderTimeKey);
  }

  /// 测试通知（立即发送）
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'test',
      '测试通知',
      channelDescription: '测试通知是否正常工作',
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _notifications.show(
      999,
      '测试通知 🔔',
      '通知功能正常工作！',
      notificationDetails,
    );
  }
}
