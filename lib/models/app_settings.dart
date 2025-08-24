import '../enums/analysis_method.dart';

/// 应用设置数据模型
/// 
/// 管理用户的个性化配置，使用SharedPreferences持久化存储
class AppSettings {
  /// 情绪分析方式
  final AnalysisMethod analysisMethod;
  
  /// LLM服务提供商（仅当analysisMethod为llm时有效）
  final String? llmProvider;
  
  /// LLM API密钥
  final String? llmApiKey;
  
  /// LLM模型名称（可选，使用默认模型）
  final String? llmModel;
  
  /// 是否启用调试模式
  final bool debugMode;
  
  /// 应用主题模式（预留）
  final String themeMode;
  
  /// 数据同步设置（预留）
  final bool enableDataSync;

  const AppSettings({
    this.analysisMethod = AnalysisMethod.rule, // 默认使用规则分析
    this.llmProvider,
    this.llmApiKey,
    this.llmModel,
    this.debugMode = false,
    this.themeMode = 'system', // system/light/dark
    this.enableDataSync = false,
  });

  /// 从JSON创建设置对象
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      analysisMethod: AnalysisMethod.fromValue(
        json['analysisMethod'] as String? ?? 'rule',
      ),
      llmProvider: json['llmProvider'] as String?,
      llmApiKey: json['llmApiKey'] as String?,
      llmModel: json['llmModel'] as String?,
      debugMode: json['debugMode'] as bool? ?? false,
      themeMode: json['themeMode'] as String? ?? 'system',
      enableDataSync: json['enableDataSync'] as bool? ?? false,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'analysisMethod': analysisMethod.value,
      'llmProvider': llmProvider,
      'llmApiKey': llmApiKey,
      'llmModel': llmModel,
      'debugMode': debugMode,
      'themeMode': themeMode,
      'enableDataSync': enableDataSync,
    };
  }

  /// 创建默认设置
  factory AppSettings.defaultSettings() {
    return const AppSettings();
  }

  /// 创建副本，支持部分字段修改
  AppSettings copyWith({
    AnalysisMethod? analysisMethod,
    String? llmProvider,
    String? llmApiKey,
    String? llmModel,
    bool? debugMode,
    String? themeMode,
    bool? enableDataSync,
  }) {
    return AppSettings(
      analysisMethod: analysisMethod ?? this.analysisMethod,
      llmProvider: llmProvider ?? this.llmProvider,
      llmApiKey: llmApiKey ?? this.llmApiKey,
      llmModel: llmModel ?? this.llmModel,
      debugMode: debugMode ?? this.debugMode,
      themeMode: themeMode ?? this.themeMode,
      enableDataSync: enableDataSync ?? this.enableDataSync,
    );
  }

  /// 检查设置是否有效
  bool get isValid {
    // 如果使用LLM分析，必须指定提供商和API密钥
    if (analysisMethod == AnalysisMethod.llm) {
      if (llmProvider == null || llmProvider!.isEmpty) {
        return false;
      }
      if (llmApiKey == null || llmApiKey!.isEmpty) {
        return false;
      }
    }
    
    // 主题模式必须是有效值
    if (!['system', 'light', 'dark'].contains(themeMode)) {
      return false;
    }
    
    return true;
  }

  /// 获取当前有效的LLM提供商列表
  static List<String> get availableLLMProviders {
    return ['siliconflow', 'deepseek']; // 后续在第二阶段扩展
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          analysisMethod == other.analysisMethod &&
          llmProvider == other.llmProvider &&
          llmApiKey == other.llmApiKey &&
          llmModel == other.llmModel &&
          debugMode == other.debugMode &&
          themeMode == other.themeMode &&
          enableDataSync == other.enableDataSync;

  @override
  int get hashCode => Object.hash(
        analysisMethod,
        llmProvider,
        llmApiKey,
        llmModel,
        debugMode,
        themeMode,
        enableDataSync,
      );

  @override
  String toString() {
    return 'AppSettings('
        'analysisMethod: $analysisMethod, '
        'llmProvider: $llmProvider, '
        'llmApiKey: ${llmApiKey?.isNotEmpty == true ? '[CONFIGURED]' : null}, '
        'llmModel: $llmModel, '
        'debugMode: $debugMode, '
        'themeMode: $themeMode, '
        'enableDataSync: $enableDataSync'
        ')';
  }
}