import 'package:flutter/material.dart';
import '../services/impression_image_service.dart';

/// 印象画横幅Widget
///
/// 在报告顶部展示基于情绪数据生成的艺术化图片
class ImpressionImageBanner extends StatefulWidget {
  /// 情绪数据摘要（如："本周主要情绪为积极，平均分85分，情绪波动较小"）
  final String emotionSummary;

  /// 时间范围描述（如："2025年1月第2周"）
  final String timeRange;

  /// 横幅高度
  final double height;

  const ImpressionImageBanner({
    super.key,
    required this.emotionSummary,
    required this.timeRange,
    this.height = 200,
  });

  @override
  State<ImpressionImageBanner> createState() => _ImpressionImageBannerState();
}

class _ImpressionImageBannerState extends State<ImpressionImageBanner> {
  final ImpressionImageService _imageService = ImpressionImageService.instance;

  ImpressionImageResult? _imageResult;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _imageService.generateImage(
        emotionSummary: widget.emotionSummary,
        timeRange: widget.timeRange,
      );

      if (mounted) {
        setState(() {
          _imageResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 12),
              Text(
                '正在生成印象画...',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _imageResult == null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                '印象画加载失败',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 根据生成模式显示不同内容
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildImageContent(theme),

        // 艺术风格标签
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  _imageResult!.style.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(ThemeData theme) {
    final result = _imageResult!;

    switch (result.generationMode) {
      case GenerationMode.ai:
        // AI生成：优先使用缓存的内存图片
        if (result.imageBytes != null) {
          return Image.memory(result.imageBytes!, fit: BoxFit.cover);
        }

        if (result.imageUrl.isNotEmpty) {
          return Image.network(
            result.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder(theme);
            },
          );
        }

        return _buildErrorPlaceholder(theme);

      case GenerationMode.preset:
        // 预设图片：显示网络图片（fallback URL）
        return Image.network(
          result.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildLocalRenderFallback(theme, result);
          },
        );

      case GenerationMode.local:
        // 本地渲染：使用CustomPaint绘制
        return _buildLocalRenderFallback(theme, result);
    }
  }

  /// 本地渲染降级方案：使用渐变色背景
  Widget _buildLocalRenderFallback(
    ThemeData theme,
    ImpressionImageResult result,
  ) {
    // 根据艺术风格的颜色主题创建渐变
    final colors = result.style.colorTheme.map((hex) {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.8),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              result.style.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 48,
        ),
      ),
    );
  }
}
