import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../enums/analysis_method.dart';

/// 应用设置管理服务
/// 
/// 负责用户设置的持久化存储和访问，使用SharedPreferences实现
class SettingsService {
  static const String _settingsKey = 'app_settings';
  
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  late SharedPreferences _prefs;
  AppSettings _currentSettings = AppSettings.defaultSettings();
  
  /// 初始化设置服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    
    if (kDebugMode) {
      debugPrint('SettingsService initialized with: $_currentSettings');
    }
  }
  
  /// 获取当前设置
  AppSettings get currentSettings => _currentSettings;
  
  /// 获取情绪分析方式
  AnalysisMethod get analysisMethod => _currentSettings.analysisMethod;
  
  /// 获取LLM提供商
  String? get llmProvider => _currentSettings.llmProvider;
  
  /// 是否启用调试模式
  bool get debugMode => _currentSettings.debugMode;
  
  /// 获取主题模式
  String get themeMode => _currentSettings.themeMode;
  
  /// 是否启用数据同步
  bool get enableDataSync => _currentSettings.enableDataSync;
  
  /// 更新设置
  Future<void> updateSettings(AppSettings newSettings) async {
    if (!newSettings.isValid) {
      throw ArgumentError('Invalid settings provided');
    }
    
    _currentSettings = newSettings;
    await _saveSettings();
    
    if (kDebugMode) {
      debugPrint('Settings updated: $_currentSettings');
    }
  }
  
  /// 更新情绪分析方式
  Future<void> updateAnalysisMethod(AnalysisMethod method, {String? llmProvider}) async {
    final newSettings = _currentSettings.copyWith(
      analysisMethod: method,
      llmProvider: method == AnalysisMethod.llm ? llmProvider : null,
    );
    await updateSettings(newSettings);
  }
  
  /// 更新LLM提供商
  Future<void> updateLLMProvider(String provider) async {
    if (_currentSettings.analysisMethod != AnalysisMethod.llm) {
      throw StateError('Cannot update LLM provider when not using LLM analysis');
    }
    
    final newSettings = _currentSettings.copyWith(llmProvider: provider);
    await updateSettings(newSettings);
  }
  
  /// 更新调试模式
  Future<void> updateDebugMode(bool enabled) async {
    final newSettings = _currentSettings.copyWith(debugMode: enabled);
    await updateSettings(newSettings);
  }
  
  /// 更新主题模式
  Future<void> updateThemeMode(String mode) async {
    if (!['system', 'light', 'dark'].contains(mode)) {
      throw ArgumentError('Invalid theme mode: $mode');
    }
    
    final newSettings = _currentSettings.copyWith(themeMode: mode);
    await updateSettings(newSettings);
  }
  
  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    await updateSettings(AppSettings.defaultSettings());
  }
  
  /// 检查设置是否为默认值
  bool get isDefaultSettings {
    return _currentSettings == AppSettings.defaultSettings();
  }
  
  /// 获取设置摘要信息
  Map<String, dynamic> getSettingsSummary() {
    return {
      'analysisMethod': _currentSettings.analysisMethod.displayName,
      'llmProvider': _currentSettings.llmProvider ?? '未设置',
      'debugMode': _currentSettings.debugMode ? '开启' : '关闭',
      'themeMode': _getThemeModeDisplayName(_currentSettings.themeMode),
      'enableDataSync': _currentSettings.enableDataSync ? '开启' : '关闭',
    };
  }
  
  /// 获取主题模式显示名称
  String _getThemeModeDisplayName(String mode) {
    switch (mode) {
      case 'system':
        return '跟随系统';
      case 'light':
        return '浅色主题';
      case 'dark':
        return '深色主题';
      default:
        return mode;
    }
  }
  
  /// 从SharedPreferences加载设置
  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs.getString(_settingsKey);
      if (settingsJson != null && settingsJson.isNotEmpty) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AppSettings.fromJson(settingsMap);
      } else {
        // 首次运行，使用默认设置
        _currentSettings = AppSettings.defaultSettings();
        await _saveSettings(); // 保存默认设置
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // 加载失败时使用默认设置
      _currentSettings = AppSettings.defaultSettings();
      await _saveSettings();
    }
  }
  
  /// 将设置保存到SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final settingsJson = json.encode(_currentSettings.toJson());
      await _prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }
  
  /// 清除所有设置（用于调试和测试）
  Future<void> clearAllSettings() async {
    await _prefs.remove(_settingsKey);
    _currentSettings = AppSettings.defaultSettings();
    
    if (kDebugMode) {
      debugPrint('All settings cleared');
    }
  }
  
  /// 导出设置为JSON字符串（用于备份）
  String exportSettings() {
    return json.encode(_currentSettings.toJson());
  }
  
  /// 从JSON字符串导入设置（用于恢复）
  Future<void> importSettings(String settingsJson) async {
    try {
      final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
      final importedSettings = AppSettings.fromJson(settingsMap);
      await updateSettings(importedSettings);
    } catch (e) {
      throw ArgumentError('Invalid settings JSON: $e');
    }
  }
}