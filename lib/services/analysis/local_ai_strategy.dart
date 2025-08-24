import '../../models/analysis_result.dart';
import 'analysis_strategy.dart';

/// 基于本地AI模型的分析策略（预留功能）
/// 
/// 使用设备本地运行的轻量级AI模型进行分析
/// - iOS: 可能使用CoreML + Metal加速
/// - Android: 可能使用TensorFlow Lite
/// - Web: 暂不支持
/// 注意：保持三分类结果(positive/negative/neutral)兼容性
class LocalAIStrategy implements AnalysisStrategy {
  @override
  String get strategyName => 'local_ai';

  @override
  String get description => '使用本地AI模型分析，兼顾准确性和隐私';

  @override
  bool get requiresNetwork => false;

  @override
  Future<bool> get isAvailable async => false; // 预留功能，暂未实现

  @override
  int get estimatedDurationMs => 1000; // 预估本地AI需要1秒

  @override
  double get confidenceBaseline => 0.8; // 本地AI置信度中高

  @override
  List<String> get requiredConfigs => ['model_path', 'hardware_acceleration'];

  @override
  Future<AnalysisResult> analyze(String content) async {
    throw UnimplementedError('本地AI分析是预留功能，将在后续版本实现');
  }

  @override
  Future<bool> validateConfig() async {
    // TODO: 检查设备是否支持本地AI加速
    // 检查Metal(iOS)、GPU(Android)等硬件支持
    return false;
  }
}