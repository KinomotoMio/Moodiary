import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/art_style.dart';

/// 图片生成模式
enum GenerationMode {
  preset,  // 方案A：预设图片
  ai,      // 方案B：AI生成
  local,   // 方案C：本地渲染
}

/// 印象画生成服务
///
/// 支持三种方案：
/// - 方案A：预设图片（最快，降级方案）
/// - 方案B：AI文生图（最佳体验）
/// - 方案C：本地渲染（离线可用）
class ImpressionImageService {
  static ImpressionImageService? _instance;
  static ImpressionImageService get instance =>
      _instance ??= ImpressionImageService._();

  ImpressionImageService._();

  static const String _selectedStyleKey = 'selected_art_style';
  static const String _generationModeKey = 'image_generation_mode';

  /// 获取用户选择的艺术风格
  Future<ArtStyle> getSelectedStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final styleId = prefs.getString(_selectedStyleKey);

    if (styleId != null) {
      final style = ArtStyles.getStyleById(styleId);
      if (style != null) return style;
    }

    // 默认返回宫崎骏风格（治愈系）
    return ArtStyles.miyazaki;
  }

  /// 设置用户选择的艺术风格
  Future<void> setSelectedStyle(String styleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedStyleKey, styleId);
  }

  /// 获取图片生成模式
  Future<GenerationMode> getGenerationMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_generationModeKey);

    switch (mode) {
      case 'preset':
        return GenerationMode.preset;
      case 'ai':
        return GenerationMode.ai;
      case 'local':
        return GenerationMode.local;
      default:
        return GenerationMode.ai; // 默认使用AI生成
    }
  }

  /// 设置图片生成模式
  Future<void> setGenerationMode(GenerationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_generationModeKey, mode.name);
  }

  /// 生成印象画
  ///
  /// [emotionSummary] 情绪数据摘要
  /// [timeRange] 时间范围描述
  /// [style] 艺术风格（可选，默认使用用户设置）
  Future<ImpressionImageResult> generateImage({
    required String emotionSummary,
    required String timeRange,
    ArtStyle? style,
  }) async {
    style ??= await getSelectedStyle();
    final mode = await getGenerationMode();

    try {
      switch (mode) {
        case GenerationMode.ai:
          // 尝试AI生成
          try {
            return await _generateWithAI(emotionSummary, timeRange, style);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('AI generation failed, fallback to preset: $e');
            }
            // AI生成失败，降级到预设图片
            return _generateWithPreset(style);
          }

        case GenerationMode.preset:
          return _generateWithPreset(style);

        case GenerationMode.local:
          return _generateWithLocal(emotionSummary, timeRange, style);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image generation failed: $e');
      }
      // 最终降级方案
      return _generateWithPreset(style);
    }
  }

  /// 方案A：使用预设图片（随机选择）
  ImpressionImageResult _generateWithPreset(ArtStyle style) {
    // 从多张预设图片中随机选择一张
    final random = Random();
    final randomIndex = random.nextInt(style.fallbackImageUrls.length);
    final selectedUrl = style.fallbackImageUrls[randomIndex];

    return ImpressionImageResult(
      imageUrl: selectedUrl,
      style: style,
      generationMode: GenerationMode.preset,
      isLocal: false,
    );
  }

  /// 方案B：使用AI生成图片
  Future<ImpressionImageResult> _generateWithAI(
    String emotionSummary,
    String timeRange,
    ArtStyle style,
  ) async {
    // 生成提示词
    final prompt = style.generatePrompt(emotionSummary, timeRange);

    // 调用通义万相API
    final imageUrl = await _callTongyiWanxiangAPI(prompt);

    return ImpressionImageResult(
      imageUrl: imageUrl,
      style: style,
      generationMode: GenerationMode.ai,
      isLocal: false,
      prompt: prompt,
    );
  }

  /// 调用通义万相API
  Future<String> _callTongyiWanxiangAPI(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('dashscope_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先在设置中配置DashScope API Key');
    }

    // 通义万相API调用
    final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'X-DashScope-Async': 'enable',
      },
      body: jsonEncode({
        'model': 'wanx-v1',
        'input': {
          'prompt': prompt,
        },
        'parameters': {
          'size': '1024*1024',
          'n': 1,
        },
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final taskId = data['output']['task_id'];

      // 轮询获取结果
      return await _pollTaskResult(taskId, apiKey);
    } else {
      throw Exception('API调用失败: ${response.statusCode}');
    }
  }

  /// 轮询任务结果
  Future<String> _pollTaskResult(String taskId, String apiKey) async {
    const maxAttempts = 30; // 最多轮询30次
    const pollInterval = Duration(seconds: 2);

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(pollInterval);

      final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/tasks/$taskId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['output']['task_status'];

        if (status == 'SUCCEEDED') {
          final results = data['output']['results'] as List;
          return results[0]['url'];
        } else if (status == 'FAILED') {
          throw Exception('图片生成失败');
        }
        // 否则继续轮询
      } else {
        throw Exception('获取任务状态失败: ${response.statusCode}');
      }
    }

    throw Exception('图片生成超时');
  }

  /// 方案C：本地渲染生成
  ImpressionImageResult _generateWithLocal(
    String emotionSummary,
    String timeRange,
    ArtStyle style,
  ) {
    // 方案C使用本地渲染，返回特殊标记
    // 在UI层通过CustomPaint绘制
    return ImpressionImageResult(
      imageUrl: 'local://${style.id}', // 特殊URL标记
      style: style,
      generationMode: GenerationMode.local,
      isLocal: true,
      emotionData: emotionSummary,
    );
  }
}

/// 印象画生成结果
class ImpressionImageResult {
  /// 图片URL（如果是本地渲染，则为特殊标记）
  final String imageUrl;

  /// 使用的艺术风格
  final ArtStyle style;

  /// 生成模式
  final GenerationMode generationMode;

  /// 是否为本地渲染
  final bool isLocal;

  /// AI生成使用的提示词（可选）
  final String? prompt;

  /// 情绪数据（用于本地渲染）
  final String? emotionData;

  const ImpressionImageResult({
    required this.imageUrl,
    required this.style,
    required this.generationMode,
    required this.isLocal,
    this.prompt,
    this.emotionData,
  });
}
