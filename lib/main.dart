import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日期格式化（Web端兼容）
  try {
    await initializeDateFormatting('zh_CN', null);
  } catch (e) {
    // Web端回退，使用默认格式化
    debugPrint('Date formatting initialization failed: $e');
  }
  
  // 初始化存储服务
  await StorageService.instance.initialize();
  
  runApp(const MoodiaryApp());
}
