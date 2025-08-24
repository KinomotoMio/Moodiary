import 'package:flutter/foundation.dart';
import 'providers/base_llm_provider.dart';
import 'providers/siliconflow_provider.dart';
import 'providers/deepseek_provider.dart';

/// 统一的LLM客户端
/// 
/// 管理多个LLM提供商，提供统一的调用接口
class LLMClient {
  static LLMClient? _instance;
  static LLMClient get instance => _instance ??= LLMClient._();
  
  LLMClient._();
  
  // 注册的LLM提供商
  final Map<String, BaseLLMProvider> _providers = {
    'siliconflow': SiliconFlowProvider(),
    'deepseek': DeepSeekProvider(),
  };
  
  /// 获取所有可用的提供商
  List<String> get availableProviders => _providers.keys.toList();
  
  /// 获取指定提供商
  BaseLLMProvider? getProvider(String providerName) {
    return _providers[providerName];
  }
  
  /// 添加新的提供商
  void registerProvider(String name, BaseLLMProvider provider) {
    _providers[name] = provider;
    if (kDebugMode) {
      debugPrint('Registered LLM provider: $name');
    }
  }
  
  /// 调用指定提供商的API
  /// 
  /// [providerName] 提供商名称
  /// [prompt] 输入提示词
  /// [model] 使用的模型，为null时使用默认模型
  /// [apiKey] API密钥
  /// [parameters] 额外参数
  Future<String> generateText({
    required String providerName,
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? parameters,
  }) async {
    final provider = _providers[providerName];
    if (provider == null) {
      throw LLMException('Unknown provider: $providerName');
    }
    
    if (provider.requiresApiKey && (apiKey == null || apiKey.isEmpty)) {
      throw LLMException(
        'API key required for provider: $providerName',
        providerName: providerName,
      );
    }
    
    try {
      final result = await provider.generateText(
        prompt: prompt,
        model: model,
        apiKey: apiKey,
        parameters: parameters,
      );
      
      if (kDebugMode) {
        debugPrint('LLM call successful: $providerName');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LLM call failed: $providerName - $e');
      }
      rethrow;
    }
  }
  
  /// 测试指定提供商的连接
  Future<bool> testProviderConnection({
    required String providerName,
    String? apiKey,
  }) async {
    final provider = _providers[providerName];
    if (provider == null) {
      return false;
    }
    
    try {
      return await provider.testConnection(apiKey: apiKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Provider connection test failed: $providerName - $e');
      }
      return false;
    }
  }
  
  /// 获取指定提供商的模型信息
  Future<List<LLMModelInfo>> getProviderModels({
    required String providerName,
    String? apiKey,
  }) async {
    final provider = _providers[providerName];
    if (provider == null) {
      throw LLMException('Unknown provider: $providerName');
    }
    
    try {
      return await provider.getAvailableModels(apiKey: apiKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get models for $providerName: $e');
      }
      rethrow;
    }
  }
  
  /// 获取提供商的基本信息
  Map<String, dynamic> getProviderInfo(String providerName) {
    final provider = _providers[providerName];
    if (provider == null) {
      throw LLMException('Unknown provider: $providerName');
    }
    
    return {
      'name': provider.name,
      'displayName': provider.displayName,
      'baseUrl': provider.baseUrl,
      'requiresApiKey': provider.requiresApiKey,
      'defaultModel': provider.defaultModel,
      'supportedModels': provider.supportedModels,
    };
  }
  
  /// 获取所有提供商的信息
  Map<String, Map<String, dynamic>> getAllProvidersInfo() {
    final result = <String, Map<String, dynamic>>{};
    for (final entry in _providers.entries) {
      result[entry.key] = getProviderInfo(entry.key);
    }
    return result;
  }
  
  /// 选择最佳的提供商
  /// 
  /// 基于可用性、性能等因素选择推荐的提供商
  String? getBestProvider({List<String>? excludeProviders}) {
    final available = availableProviders
        .where((name) => excludeProviders?.contains(name) != true)
        .toList();
    
    if (available.isEmpty) return null;
    
    // 简单的优先级排序，后续可以基于性能数据优化
    const priority = ['siliconflow', 'deepseek'];
    
    for (final provider in priority) {
      if (available.contains(provider)) {
        return provider;
      }
    }
    
    return available.first;
  }
}