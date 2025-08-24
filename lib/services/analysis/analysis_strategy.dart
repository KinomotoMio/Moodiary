import '../../models/analysis_result.dart';

/// 情绪分析策略接口
/// 
/// 定义统一的分析接口，支持多种分析实现方式：
/// - 基于规则的传统分析
/// - 基于LLM的AI分析  
/// - 基于本地模型的分析
/// 
/// 策略模式确保业务逻辑与具体实现解耦
abstract class AnalysisStrategy {
  /// 分析文本内容，返回统一格式的分析结果
  /// 
  /// [content] 用户输入的心情记录文本
  /// 返回包含情绪类型、分数、标签等信息的分析结果
  Future<AnalysisResult> analyze(String content);
  
  /// 策略名称，用于标识和日志
  String get strategyName;
  
  /// 策略描述，用于用户界面展示
  String get description;
  
  /// 是否需要网络连接
  bool get requiresNetwork;
  
  /// 是否当前可用
  /// 某些策略可能因为网络、配置等原因临时不可用
  Future<bool> get isAvailable;
  
  /// 获取策略的配置要求
  /// 返回该策略需要的配置项列表
  List<String> get requiredConfigs => [];
  
  /// 验证配置是否完整
  /// 在使用策略前检查必要的配置是否已设置
  Future<bool> validateConfig() async => true;
  
  /// 估算分析耗时（毫秒）
  /// 用于UI显示预期等待时间
  int get estimatedDurationMs;
  
  /// 策略的置信度基准
  /// 不同策略的可靠性参考值 (0.0-1.0)
  double get confidenceBaseline;
}