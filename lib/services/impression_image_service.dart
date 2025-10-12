import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/art_style.dart';
import 'settings_service.dart';

/// 图片生成模式
enum GenerationMode {
  preset, // 方案A：预设图片
  ai, // 方案B：AI生成
  local, // 方案C：本地渲染
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
  static const String _imageCacheKey = 'impression_image_cache';
  static const int _imageCacheLimit = 30;

  Map<String, Map<String, dynamic>> _imageCache = {};
  bool _imageCacheLoaded = false;

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
    if (kDebugMode) {
      debugPrint(
        '[ImpressionImage] Start AI generation with style=${style.id}',
      );
    }

    // 生成提示词
    final prompt = _preparePrompt(
      style.generatePrompt(emotionSummary, timeRange),
    );

    // 先尝试读取缓存
    final cachedImage = await _getCachedImage(prompt);
    if (cachedImage != null) {
      if (kDebugMode) {
        debugPrint('[ImpressionImage] Use cached image for style=${style.id}');
      }
      return ImpressionImageResult(
        imageUrl: cachedImage.sourceUrl ?? '',
        style: style,
        generationMode: GenerationMode.ai,
        isLocal: true,
        prompt: prompt,
        imageBytes: cachedImage.bytes,
      );
    }

    // 调用SiliconFlow文生图API
    final imageUrl = await _callSiliconFlowImageAPI(prompt);
    final imageBytes = await _downloadImageBytes(imageUrl);
    if (imageBytes != null) {
      await _storeCachedImage(
        prompt: prompt,
        imageUrl: imageUrl,
        bytes: imageBytes,
      );
    }

    return ImpressionImageResult(
      imageUrl: imageUrl,
      style: style,
      generationMode: GenerationMode.ai,
      isLocal: imageBytes != null,
      prompt: prompt,
      imageBytes: imageBytes,
    );
  }

  /// 调用SiliconFlow文生图API
  Future<String> _callSiliconFlowImageAPI(String prompt) async {
    // 从设置服务获取API Key（复用对话模型的Key）
    final settings = SettingsService.instance.currentSettings;
    final apiKey = settings.llmApiKey;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('请先在设置中配置SiliconFlow API Key');
    }

    // SiliconFlow文生图API
    final url = Uri.parse('https://api.siliconflow.cn/v1/images/generations');

    const modelId = 'Qwen/Qwen-Image';
    final primaryPayload = {
      'model': modelId,
      'prompt': prompt,
      'negative_prompt':
          'low quality, distorted, watermark, text, letters, words, typography, captions, subtitles, logos, signatures',
      'num_inference_steps': 20,
      'guidance_scale': 7,
      'image_size': '1024x512',
    };

    final firstAttempt = await _postImageRequest(
      url: url,
      apiKey: apiKey,
      payload: primaryPayload,
    );

    if (firstAttempt.isSuccess) {
      return firstAttempt.url!;
    }

    // 如果首次失败且是参数问题，尝试使用精简参数重试一次
    if (kDebugMode) {
      debugPrint(
        '[ImpressionImage] First attempt failed (${firstAttempt.errorMessage ?? 'unknown'}), retrying without optional parameters...',
      );
    }

    final fallbackPayload = {'model': modelId, 'prompt': prompt};

    final secondAttempt = await _postImageRequest(
      url: url,
      apiKey: apiKey,
      payload: fallbackPayload,
    );

    if (secondAttempt.isSuccess) {
      return secondAttempt.url!;
    }

    final errorMessage =
        secondAttempt.errorMessage ?? firstAttempt.errorMessage;
    throw Exception(errorMessage ?? '文生图API调用失败');
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

  String _preparePrompt(String prompt) {
    final normalized = prompt.replaceAll('\r', '').trim();
    const maxLength = 1800;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength).trimRight()}…';
  }

  Future<_CachedImage?> _getCachedImage(String prompt) async {
    await _ensureCacheLoaded();
    final key = _hashPrompt(prompt);
    final entry = _imageCache[key];
    if (entry == null) return null;

    final base64Data = entry['base64'] as String?;
    if (base64Data == null || base64Data.isEmpty) {
      return null;
    }

    try {
      final bytes = base64Decode(base64Data);
      final sourceUrl = entry['url'] as String?;
      return _CachedImage(bytes: bytes, sourceUrl: sourceUrl);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImpressionImage] Failed to decode cached image: $e');
      }
      return null;
    }
  }

  Future<void> _storeCachedImage({
    required String prompt,
    required String imageUrl,
    required Uint8List bytes,
  }) async {
    await _ensureCacheLoaded();
    final key = _hashPrompt(prompt);

    _imageCache[key] = {
      'url': imageUrl,
      'base64': base64Encode(bytes),
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    };

    _pruneCacheIfNeeded();
    await _persistCache();
  }

  Future<void> _ensureCacheLoaded() async {
    if (_imageCacheLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_imageCacheKey);
    if (cacheString != null && cacheString.isNotEmpty) {
      try {
        final decoded = jsonDecode(cacheString) as Map<String, dynamic>;
        _imageCache = decoded.map(
          (key, value) =>
              MapEntry(key, Map<String, dynamic>.from(value as Map)),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ImpressionImage] Failed to load cache: $e');
        }
        _imageCache = {};
      }
    }

    _imageCacheLoaded = true;
  }

  Future<void> _persistCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imageCacheKey, jsonEncode(_imageCache));
  }

  void _pruneCacheIfNeeded() {
    if (_imageCache.length <= _imageCacheLimit) return;

    final entries = _imageCache.entries.toList()
      ..sort((a, b) {
        final aTime = (a.value['savedAt'] ?? 0) as int;
        final bTime = (b.value['savedAt'] ?? 0) as int;
        return aTime.compareTo(bTime);
      });

    final removeCount = _imageCache.length - _imageCacheLimit;
    for (var i = 0; i < removeCount; i++) {
      _imageCache.remove(entries[i].key);
    }
  }

  String _hashPrompt(String prompt) {
    final bytes = utf8.encode(prompt);
    return sha1.convert(bytes).toString();
  }

  Future<Uint8List?> _downloadImageBytes(String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      if (kDebugMode) {
        debugPrint(
          '[ImpressionImage] Failed to download image: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImpressionImage] Download exception: $e');
      }
    }
    return null;
  }

  Future<_ImageApiResult> _postImageRequest({
    required Uri url,
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[ImpressionImage] POST images/generations payload=${payload.keys}',
        );
      }

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final urlCandidate = _extractImageUrl(data);
        if (urlCandidate != null) {
          if (kDebugMode) {
            debugPrint('[ImpressionImage] Image generated: $urlCandidate');
          }
          return _ImageApiResult.success(urlCandidate);
        }
        return _ImageApiResult.failure('API返回的图片字段无法解析');
      }

      final errorBody = response.body;
      if (kDebugMode) {
        debugPrint(
          '[ImpressionImage] SiliconFlow error ${response.statusCode}: $errorBody',
        );
      }

      String? errorMessage;
      try {
        final error = jsonDecode(errorBody);
        errorMessage =
            '文生图API调用失败: ${response.statusCode} - ${error['error']?['message'] ?? error['message'] ?? 'Unknown error'}';
      } catch (_) {
        errorMessage = '文生图API调用失败: ${response.statusCode}';
      }
      return _ImageApiResult.failure(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ImpressionImage] Request failed: $e');
      }
      return _ImageApiResult.failure('文生图API调用异常: $e');
    }
  }

  String? _extractImageUrl(Map<String, dynamic> data) {
    // 兼容多种响应格式
    final candidates = <dynamic>[
      data['images'],
      data['data'],
      data['output'],
    ].where((element) => element != null);

    for (final candidate in candidates) {
      if (candidate is List && candidate.isNotEmpty) {
        final first = candidate.first;
        if (first is Map<String, dynamic>) {
          final url =
              first['url'] ??
              first['image_url'] ??
              first['image'] ??
              first['src'];
          if (url is String && url.isNotEmpty) {
            return url;
          }
        } else if (first is String && first.startsWith('http')) {
          return first;
        }
      } else if (candidate is Map<String, dynamic>) {
        // 某些响应可能是 { "url": "...", ... }
        final url =
            candidate['url'] ??
            candidate['image_url'] ??
            candidate['image'] ??
            candidate['src'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
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

  /// 图片二进制数据（缓存使用）
  final Uint8List? imageBytes;

  const ImpressionImageResult({
    required this.imageUrl,
    required this.style,
    required this.generationMode,
    required this.isLocal,
    this.prompt,
    this.emotionData,
    this.imageBytes,
  });
}

class _CachedImage {
  final Uint8List bytes;
  final String? sourceUrl;

  const _CachedImage({required this.bytes, this.sourceUrl});
}

class _ImageApiResult {
  final bool isSuccess;
  final String? url;
  final String? errorMessage;

  const _ImageApiResult._({
    required this.isSuccess,
    this.url,
    this.errorMessage,
  });

  factory _ImageApiResult.success(String url) {
    return _ImageApiResult._(isSuccess: true, url: url);
  }

  factory _ImageApiResult.failure(String? message) {
    return _ImageApiResult._(isSuccess: false, errorMessage: message);
  }
}
