/// LLM服务提供商基类
/// 
/// 定义统一的LLM API调用接口，支持不同的AI服务提供商
/// - SiliconFlow
/// - DeepSeek  
/// - 其他兼容OpenAI格式的服务
abstract class BaseLLMProvider {
  /// 提供商名称
  String get name;
  
  /// 提供商显示名称
  String get displayName;
  
  /// API基础URL
  String get baseUrl;
  
  /// 是否需要API密钥
  bool get requiresApiKey;
  
  /// 默认模型名称
  String get defaultModel;
  
  /// 支持的模型列表
  List<String> get supportedModels;
  
  /// 调用LLM API进行文本生成
  /// 
  /// [prompt] 输入的提示词
  /// [model] 使用的模型名称，为null时使用默认模型
  /// [apiKey] API密钥，某些提供商需要
  /// [parameters] 额外的API参数
  /// 
  /// 返回生成的文本内容
  Future<String> generateText({
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? parameters,
  });
  
  /// 检查API连接状态
  /// 
  /// [apiKey] API密钥
  /// 返回连接是否正常
  Future<bool> testConnection({String? apiKey});
  
  /// 获取模型信息
  /// 
  /// [apiKey] API密钥
  /// 返回可用的模型列表及其详细信息
  Future<List<LLMModelInfo>> getAvailableModels({String? apiKey});
  
  /// 估算API调用成本（可选实现）
  /// 
  /// [inputTokens] 输入token数量
  /// [outputTokens] 输出token数量  
  /// [model] 使用的模型
  /// 返回预估成本（人民币分）
  double? estimateCost({
    required int inputTokens,
    required int outputTokens,
    String? model,
  }) => null;
}

/// LLM模型信息
class LLMModelInfo {
  /// 模型名称
  final String name;
  
  /// 显示名称
  final String displayName;
  
  /// 模型描述
  final String description;
  
  /// 上下文长度限制
  final int maxContextLength;
  
  /// 是否支持中文
  final bool supportsChinese;
  
  /// 是否可用
  final bool isAvailable;

  const LLMModelInfo({
    required this.name,
    required this.displayName,
    required this.description,
    required this.maxContextLength,
    this.supportsChinese = true,
    this.isAvailable = true,
  });

  factory LLMModelInfo.fromJson(Map<String, dynamic> json) {
    return LLMModelInfo(
      name: json['name'] as String,
      displayName: json['displayName'] as String? ?? json['name'] as String,
      description: json['description'] as String? ?? '',
      maxContextLength: json['maxContextLength'] as int? ?? 4096,
      supportsChinese: json['supportsChinese'] as bool? ?? true,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'displayName': displayName,
      'description': description,
      'maxContextLength': maxContextLength,
      'supportsChinese': supportsChinese,
      'isAvailable': isAvailable,
    };
  }
}

/// LLM API异常类
class LLMException implements Exception {
  final String message;
  final String? providerName;
  final int? statusCode;
  final String? errorCode;

  const LLMException(
    this.message, {
    this.providerName,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() {
    final buffer = StringBuffer('LLMException: $message');
    if (providerName != null) {
      buffer.write(' (Provider: $providerName)');
    }
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (errorCode != null) {
      buffer.write(' (Code: $errorCode)');
    }
    return buffer.toString();
  }
}