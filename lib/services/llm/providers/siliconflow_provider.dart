import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'base_llm_provider.dart';

/// SiliconFlow LLM提供商实现
/// 
/// SiliconFlow提供兼容OpenAI格式的API服务
/// API文档: https://docs.siliconflow.cn/cn/api-reference/chat-completions/chat-completions
class SiliconFlowProvider implements BaseLLMProvider {
  static const String _baseUrl = 'https://api.siliconflow.cn/v1';
  static const int _defaultTimeoutMs = 30000; // 30秒超时
  
  late final Dio _dio;
  
  SiliconFlowProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: _defaultTimeoutMs),
      receiveTimeout: Duration(milliseconds: _defaultTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // 添加日志拦截器（仅调试模式）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[SiliconFlow] $obj'),
      ));
    }
  }
  
  @override
  String get name => 'siliconflow';
  
  @override
  String get displayName => 'SiliconFlow';
  
  @override
  String get baseUrl => _baseUrl;
  
  @override
  bool get requiresApiKey => true;
  
  @override
  String get defaultModel => 'Qwen/Qwen3-14B';
  
  @override
  List<String> get supportedModels => [
    'Qwen/Qwen3-14B',
    'deepseek-ai/DeepSeek-V3',
  ];
  
  @override
  Future<String> generateText({
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? parameters,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw const LLMException('SiliconFlow API key is required');
    }
    
    final requestModel = model ?? defaultModel;
    
    // 构建OpenAI兼容的请求数据
    final requestData = {
      'model': requestModel,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': 1000,
      'temperature': 0.7,
      'stream': false,
      ...?parameters, // 合并用户自定义参数
    };
    
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final choices = data['choices'] as List;
        
        if (choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>;
          final content = message['content'] as String;
          
          if (content.trim().isEmpty) {
            throw const LLMException('Empty response content from SiliconFlow');
          }
          
          return content.trim();
        } else {
          throw const LLMException('No response choices returned from SiliconFlow');
        }
      } else {
        throw LLMException(
          'SiliconFlow API returned status ${response.statusCode}',
          providerName: name,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw LLMException(
        'Unexpected error calling SiliconFlow: $e',
        providerName: name,
      );
    }
  }
  
  @override
  Future<bool> testConnection({String? apiKey}) async {
    if (apiKey == null || apiKey.isEmpty) {
      return false;
    }
    
    try {
      // 用一个简单的测试请求验证连接
      await generateText(
        prompt: '测试',
        apiKey: apiKey,
        parameters: {'max_tokens': 5},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SiliconFlow connection test failed: $e');
      }
      return false;
    }
  }
  
  @override
  Future<List<LLMModelInfo>> getAvailableModels({String? apiKey}) async {
    // 返回支持的模型列表
    return [
      const LLMModelInfo(
        name: 'Qwen/Qwen3-14B',
        displayName: 'Qwen3-14B (推荐)',
        description: '通义千问3代14B模型，中文理解和推理能力优秀',
        maxContextLength: 131072, // 128K
        supportsChinese: true,
        isAvailable: true,
      ),
      const LLMModelInfo(
        name: 'deepseek-ai/DeepSeek-V3',
        displayName: 'DeepSeek-V3',
        description: 'DeepSeek最新V3模型，推理和代码能力强',
        maxContextLength: 131072, // 128K
        supportsChinese: true,
        isAvailable: true,
      ),
    ];
  }
  
  @override
  double? estimateCost({
    required int inputTokens,
    required int outputTokens,
    String? model,
  }) {
    // SiliconFlow成本估算（暂不实现，返回null）
    return null;
  }
  
  /// 处理Dio网络异常
  LLMException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return LLMException(
          'SiliconFlow请求超时，请检查网络连接',
          providerName: name,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String message = 'SiliconFlow请求失败';
        
        // 根据实际API响应处理错误状态码
        switch (statusCode) {
          case 400:
            message = '请求参数错误，请检查模型名称和参数';
            break;
          case 401:
            message = 'SiliconFlow API密钥无效或已过期';
            break;
          case 404:
            message = '模型不存在或不可用';
            break;
          case 429:
            message = '请求频率过高，请稍后重试';
            break;
          case 503:
            message = '模型服务过载，请稍后重试 (Model service overloaded)';
            break;
          case 504:
            message = 'SiliconFlow服务网关超时，请稍后重试';
            break;
        }
        
        return LLMException(
          message,
          providerName: name,
          statusCode: statusCode,
        );
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return LLMException(
            '网络连接失败，请检查网络设置',
            providerName: name,
          );
        }
        return LLMException(
          'SiliconFlow连接错误: ${e.message}',
          providerName: name,
        );
      default:
        return LLMException(
          'SiliconFlow网络错误: ${e.message}',
          providerName: name,
        );
    }
  }
}