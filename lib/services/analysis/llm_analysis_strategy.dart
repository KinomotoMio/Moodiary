import '../../models/analysis_result.dart';
import 'analysis_strategy.dart';

/// 基于大语言模型的AI情绪分析策略
/// 
/// 调用远程AI服务进行智能情绪分析
/// 注意：依然保持三分类结果(positive/negative/neutral)，确保与现有系统兼容
class LLMAnalysisStrategy implements AnalysisStrategy {
  @override
  String get strategyName => 'llm_analysis';

  @override
  String get description => '使用AI大模型进行智能分析，需要网络连接';

  @override
  bool get requiresNetwork => true;

  @override
  Future<bool> get isAvailable async {
    // TODO: 第二阶段实现网络和API检查
    return false; // 暂时返回不可用
  }

  @override
  List<String> get requiredConfigs => ['api_key', 'api_endpoint'];

  @override
  int get estimatedDurationMs => 3000; // AI分析预计3秒

  @override
  double get confidenceBaseline => 0.85; // AI分析置信度较高

  @override
  Future<AnalysisResult> analyze(String content) async {
    // TODO: 第二阶段实现LLM调用
    throw UnimplementedError('LLM分析将在第二阶段实现');
  }

  @override
  Future<bool> validateConfig() async {
    // TODO: 验证API密钥和端点配置
    return false;
  }
}