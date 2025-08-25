import 'dart:convert';

/// 情绪分析提示词模板
/// 
/// 为AI情绪分析提供结构化的中文提示词，确保返回标准化的JSON响应
class EmotionAnalysisPrompt {
  /// 生成情绪分析的提示词
  /// 
  /// [content] 用户输入的心情记录内容
  /// 返回完整的提示词字符串，包含分析要求和JSON格式规范
  static String generatePrompt(String content) {
    return '''
你是一个专业的情绪分析师，擅长分析中文文本的情绪倾向。请分析以下用户的心情记录内容，并按照指定格式返回分析结果。

用户内容：
"$content"

分析要求：
1. 情绪分类：将内容分为积极(positive)、消极(negative)或中性(neutral)三类
2. 情绪强度：评分范围0-100，其中0为无情绪，50为中等强度，100为极强情绪
3. 关键词提取：提取能够反映情绪状态的关键词或短语，最多5个
4. 分析推理：简要说明分类依据，100字以内

请严格按照以下JSON格式返回结果，不要添加任何其他内容：

```json
{
  "moodType": "positive/negative/neutral",
  "emotionScore": 数字(0-100),
  "extractedTags": ["关键词1", "关键词2", "关键词3"],
  "reasoning": "分析推理说明",
  "confidence": 数字(0.0-1.0)
}
```

注意事项：
- moodType必须是positive、negative或neutral之一
- emotionScore必须是0-100之间的整数
- extractedTags数组最多包含5个字符串
- reasoning要简洁明了，聚焦关键情绪表达
- confidence表示分析结果的置信度，0.0-1.0之间的小数
- 所有字段都必须存在，不能为null或undefined
''';
  }

  /// 生成批量分析的提示词
  /// 
  /// [contents] 多个心情记录内容的列表
  /// 返回用于批量分析的提示词，适用于处理多个记录
  static String generateBatchPrompt(List<String> contents) {
    if (contents.isEmpty) {
      throw ArgumentError('Contents list cannot be empty');
    }

    final numberedContents = contents.asMap().entries
        .map((entry) => '${entry.key + 1}. "${entry.value}"')
        .join('\n');

    return '''
你是一个专业的情绪分析师，擅长分析中文文本的情绪倾向。请分析以下${contents.length}条用户心情记录内容，并按照指定格式返回分析结果。

用户内容：
$numberedContents

分析要求：
1. 对每条内容进行独立的情绪分析
2. 情绪分类：积极(positive)、消极(negative)或中性(neutral)
3. 情绪强度：评分0-100
4. 关键词提取：每条最多3个关键词
5. 简要推理：50字以内

请严格按照以下JSON数组格式返回结果：

```json
[
  {
    "index": 1,
    "moodType": "positive/negative/neutral",
    "emotionScore": 数字(0-100),
    "extractedTags": ["关键词1", "关键词2"],
    "reasoning": "分析推理",
    "confidence": 数字(0.0-1.0)
  },
  {
    "index": 2,
    "moodType": "positive/negative/neutral",
    "emotionScore": 数字(0-100),
    "extractedTags": ["关键词1", "关键词2"],
    "reasoning": "分析推理",
    "confidence": 数字(0.0-1.0)
  }
]
```

注意：返回的数组长度必须与输入内容数量一致，index从1开始对应输入顺序。
''';
  }

  /// 验证API响应格式是否正确
  /// 
  /// [response] 从LLM API返回的原始响应文本
  /// 返回解析后的Map，如果格式错误则抛出异常
  static Map<String, dynamic> validateAndParseResponse(String response) {
    // 提取JSON部分（去除可能的markdown代码块标记）
    String jsonStr = response.trim();
    
    // 移除markdown代码块标记
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    }
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    
    jsonStr = jsonStr.trim();
    
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Response is not a JSON object');
      }
      
      final result = decoded;
      
      // 验证必需字段
      if (!result.containsKey('moodType') ||
          !result.containsKey('emotionScore') ||
          !result.containsKey('extractedTags') ||
          !result.containsKey('reasoning') ||
          !result.containsKey('confidence')) {
        throw const FormatException('Missing required fields in response');
      }
      
      // 验证moodType值
      final moodType = result['moodType'] as String?;
      if (moodType == null || !['positive', 'negative', 'neutral'].contains(moodType)) {
        throw const FormatException('Invalid moodType value');
      }
      
      // 验证emotionScore范围
      final emotionScore = result['emotionScore'];
      if (emotionScore is! int || emotionScore < 0 || emotionScore > 100) {
        throw const FormatException('Invalid emotionScore value');
      }
      
      // 验证extractedTags类型
      final extractedTags = result['extractedTags'];
      if (extractedTags is! List || extractedTags.any((tag) => tag is! String)) {
        throw const FormatException('Invalid extractedTags format');
      }
      
      // 验证confidence范围
      final confidence = result['confidence'];
      if (confidence is! num || confidence < 0.0 || confidence > 1.0) {
        throw const FormatException('Invalid confidence value');
      }
      
      return result;
    } catch (e) {
      throw FormatException('Failed to parse response as valid JSON: $e');
    }
  }

  /// 验证批量分析响应格式
  /// 
  /// [response] API返回的批量分析响应
  /// [expectedCount] 期望的结果数量
  /// 返回解析后的List<Map>，格式错误则抛出异常
  static List<Map<String, dynamic>> validateAndParseBatchResponse(
    String response, 
    int expectedCount,
  ) {
    String jsonStr = response.trim();
    
    // 移除markdown标记
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    }
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    
    jsonStr = jsonStr.trim();
    
    try {
      final decoded = json.decode(jsonStr);
      if (decoded is! List) {
        throw const FormatException('Batch response is not a JSON array');
      }
      
      final results = decoded;
      
      if (results.length != expectedCount) {
        throw FormatException(
          'Expected $expectedCount results, got ${results.length}',
        );
      }
      
      // 验证每个结果
      final validatedResults = <Map<String, dynamic>>[];
      for (int i = 0; i < results.length; i++) {
        if (results[i] is! Map<String, dynamic>) {
          throw FormatException('Result $i is not a JSON object');
        }
        
        final result = results[i] as Map<String, dynamic>;
        
        // 验证index字段
        if (result['index'] != i + 1) {
          throw FormatException('Invalid index in result $i');
        }
        
        // 验证其他字段（复用单个分析的验证逻辑）
        validateAndParseResponse(json.encode({
          'moodType': result['moodType'],
          'emotionScore': result['emotionScore'],
          'extractedTags': result['extractedTags'],
          'reasoning': result['reasoning'],
          'confidence': result['confidence'],
        }));
        
        validatedResults.add(result);
      }
      
      return validatedResults;
    } catch (e) {
      throw FormatException('Failed to parse batch response: $e');
    }
  }
}