import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'base_llm_provider.dart';

/// DeepSeek LLM提供商实现
/// 
/// DeepSeek提供兼容OpenAI格式的API服务
/// API文档: https://api-docs.deepseek.com
class DeepSeekProvider implements BaseLLMProvider {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static const int _defaultTimeoutMs = 30000;
  
  late final Dio _dio;
  
  DeepSeekProvider() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: _defaultTimeoutMs),
      receiveTimeout: Duration(milliseconds: _defaultTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[DeepSeek] $obj'),
      ));
    }
  }
  
  @override
  String get name => 'deepseek';
  
  @override
  String get displayName => 'DeepSeek';
  
  @override
  String get baseUrl => _baseUrl;
  
  @override
  bool get requiresApiKey => true;
  
  @override
  String get defaultModel => 'deepseek-chat';
  
  @override
  List<String> get supportedModels => ['deepseek-chat'];
  
  @override
  Future<String> generateText({
    required String prompt,
    String? model,
    String? apiKey,
    Map<String, dynamic>? parameters,
  }) async {
    if (apiKey == null || apiKey.isEmpty) {
      throw const LLMException('DeepSeek API key is required');
    }
    
    final requestModel = model ?? defaultModel;
    
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
      ...?parameters,
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
            throw const LLMException('Empty response content from DeepSeek');
          }
          
          return content.trim();
        } else {
          throw const LLMException('No response choices returned from DeepSeek');
        }
      } else {
        throw LLMException(
          'DeepSeek API returned status ${response.statusCode}',
          providerName: name,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw LLMException(
        'Unexpected error calling DeepSeek: $e',
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
      await generateText(
        prompt: '测试',
        apiKey: apiKey,
        parameters: {'max_tokens': 5},
      );
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DeepSeek connection test failed: $e');
      }
      return false;
    }
  }
  
  @override
  Future<List<LLMModelInfo>> getAvailableModels({String? apiKey}) async {
    return [
      const LLMModelInfo(
        name: 'deepseek-chat',
        displayName: 'DeepSeek Chat',
        description: 'DeepSeek对话模型，推理能力强',
        maxContextLength: 32768, // 32K上下文
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
    // DeepSeek成本估算（暂不实现，返回null）
    return null;
  }
  
  LLMException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return LLMException(
          'DeepSeek请求超时，请检查网络连接',
          providerName: name,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String message = 'DeepSeek请求失败';
        
        switch (statusCode) {
          case 400:
            message = '请求参数错误';
            break;
          case 401:
            message = 'DeepSeek API密钥无效或已过期';
            break;
          case 429:
            message = '请求频率过高，请稍后重试';
            break;
          case 503:
            message = 'DeepSeek服务暂时不可用，请稍后重试';
            break;
        }
        
        return LLMException(
          message,
          providerName: name,
          statusCode: statusCode,
        );
      default:
        return LLMException(
          'DeepSeek网络错误: ${e.message}',
          providerName: name,
        );
    }
  }
}