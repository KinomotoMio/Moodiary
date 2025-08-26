import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/mood_entry.dart';
import '../models/mood_fragment.dart';
import '../services/fragment_storage_service.dart';
import '../services/emotion_service.dart';
import '../services/smart_tag_extractor_service.dart';
import '../utils/tag_utils.dart';
import '../widgets/smart_tag_suggestions.dart';

class AddMoodScreen extends StatefulWidget {
  const AddMoodScreen({super.key});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final TextEditingController _textController = TextEditingController();
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  final EmotionService _emotionService = EmotionService.instance;
  final SmartTagExtractorService _smartTagExtractor = SmartTagExtractorService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isAnalyzing = false;
  bool _isSaving = false;
  EmotionAnalysisResult? _analysisResult;
  int _characterCount = 0;
  String? _validationMessage;
  
  // 多媒体相关
  List<XFile> _selectedImages = [];
  List<String> _extractedTopicTags = [];
  
  // 智能标签相关
  SmartTagSuggestion? _smartTagSuggestion;
  bool _isExtractingSmartTags = false;
  
  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final text = _textController.text;
    setState(() {
      _characterCount = text.length;
      _extractedTopicTags = TagUtils.extractTags(text);
    });
    
    // 异步提取智能标签建议
    _extractSmartTagsAsync();
  }
  
  Future<void> _extractSmartTagsAsync() async {
    final text = _textController.text.trim();
    
    if (text.isEmpty || text.length < 6) {
      setState(() {
        _smartTagSuggestion = null;
      });
      return;
    }
    
    setState(() {
      _isExtractingSmartTags = true;
    });
    
    try {
      final suggestion = await _smartTagExtractor.extractSmartTags(text);
      if (mounted) {
        setState(() {
          _smartTagSuggestion = suggestion;
          _isExtractingSmartTags = false;
        });
      }
    } catch (e) {
      debugPrint('Error extracting smart tags: $e');
      if (mounted) {
        setState(() {
          _smartTagSuggestion = null;
          _isExtractingSmartTags = false;
        });
      }
    }
  }
  
  void _showSmartTagSuggestions() {
    if (_smartTagSuggestion == null || !_smartTagSuggestion!.hasSuggestions) {
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SmartTagSuggestionSheet(
        suggestion: _smartTagSuggestion!,
        onConfirm: (selectedKeywords) {
          _applySmartTags(selectedKeywords);
        },
      ),
    );
  }
  
  void _applySmartTags(List<String> selectedKeywords) {
    if (selectedKeywords.isEmpty) return;
    
    final originalText = _textController.text;
    final modifiedText = _smartTagExtractor.convertKeywordsToTags(
      originalText, 
      selectedKeywords,
    );
    
    setState(() {
      _textController.text = modifiedText;
      // 重新提取标签
      _extractedTopicTags = TagUtils.extractTags(modifiedText);
    });
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已将 ${selectedKeywords.length} 个关键词转换为标签'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录心情'),
        elevation: 0,
        actions: [
          if ((_textController.text.isNotEmpty && _analysisResult != null) || _selectedImages.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveMoodEntry,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputCard(),
            const SizedBox(height: 16),
            if (_analysisResult != null) _buildAnalysisCard(),
            if (_analysisResult != null) const SizedBox(height: 16),
            if (_analysisResult != null) _buildAdviceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '今天发生了什么？',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: '记录下你的想法、感受或今天发生的事情...\n\n你可以：\n• 写下今天的心情和想法\n• 添加图片记录美好瞬间\n• 用 #标签 来分类你的记录',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (text) {
                setState(() {
                  _characterCount = text.length;
                  if (text.trim().isEmpty) {
                    _analysisResult = null;
                  }
                  _validationMessage = null; // 移除字数限制
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_validationMessage != null)
                  Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  )
                else
                  const SizedBox(),
                Text(
                  '$_characterCount 字符',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // 智能标签化按钮
            if (_characterCount >= 6) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  SmartTagButton(
                    suggestionCount: _smartTagSuggestion?.suggestionCount ?? 0,
                    onPressed: _showSmartTagSuggestions,
                    isLoading: _isExtractingSmartTags,
                  ),
                  const Spacer(),
                  if (_smartTagSuggestion?.hasSuggestions == true)
                    Text(
                      '发现 ${_smartTagSuggestion!.suggestionCount} 个关键词',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
            
            // 话题标签显示
            if (_extractedTopicTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '检测到的话题标签',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _extractedTopicTags.map((tag) => TagUtils.createTagChip(
                  context,
                  tag,
                  style: TagChipStyle.normal,
                )).toList(),
              ),
            ],
            
            // 图片展示
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '已选择图片 (${_selectedImages.length}/9)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildPreviewImage(image),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 操作按钮行
            Row(
              children: [
                // 图片选择按钮
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedImages.length < 9 ? _pickImages : null,
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(_selectedImages.isEmpty ? '添加图片' : '+${9 - _selectedImages.length}'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 情绪分析按钮
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _canAnalyze() ? _analyzeEmotion : null,
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology_outlined),
                    label: Text(_isAnalyzing ? '分析中...' : '分析情绪'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final result = _analysisResult!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '情绪分析结果',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalysisItem(
                    '情绪类型',
                    result.moodType.displayName,
                    result.moodType.emoji,
                    _getMoodColor(result.moodType),
                  ),
                ),
                Expanded(
                  child: _buildAnalysisItem(
                    '情绪强度',
                    '${result.score}分',
                    _getScoreIcon(result.score),
                    _getScoreColor(result.score),
                  ),
                ),
                // 置信度作为内部分析质量指标，不向用户展示
                // Expanded(
                //   child: _buildAnalysisItem(
                //     '置信度',
                //     '${(result.confidence * 100).toStringAsFixed(0)}%',
                //     Icons.verified_outlined,
                //     Theme.of(context).colorScheme.primary,
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, dynamic icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: icon is String
                ? Text(icon, style: const TextStyle(fontSize: 20))
                : Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceCard() {
    final result = _analysisResult!;
    final advice = _emotionService.getEmotionAdvice(result.moodType, result.score);
    
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '小贴士',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              advice,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canAnalyze() {
    return _textController.text.trim().isNotEmpty && !_isAnalyzing;
  }
  
  // 选择图片 - Web平台适配版本
  Future<void> _pickImages() async {
    try {
      if (kIsWeb) {
        // Web平台：限制图片数量和大小
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 800,  // Web版降低分辨率以节省localStorage空间
          maxHeight: 600,
          imageQuality: 70,
        );
        
        if (images.isNotEmpty) {
          // Web平台检查图片大小限制
          List<XFile> validImages = [];
          for (var image in images) {
            final bytes = await image.readAsBytes();
            // 限制单张图片不超过500KB（Base64后约700KB）
            if (bytes.length <= 500 * 1024) {
              validImages.add(image);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('图片 ${image.name} 过大，已跳过（Web版限制500KB）')),
              );
            }
          }
          
          setState(() {
            _selectedImages.addAll(validImages);
            // Web版限制最多6张图片以避免localStorage溢出
            if (_selectedImages.length > 6) {
              _selectedImages = _selectedImages.take(6).toList();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Web版最多支持6张图片')),
                );
              }
            }
          });
        }
      } else {
        // 移动平台：原有逻辑
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
            // 限制最多9张图片
            if (_selectedImages.length > 9) {
              _selectedImages = _selectedImages.take(9).toList();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
  
  // 移除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  // 保存图片到本地
  Future<List<MediaAttachment>> _saveImagesToLocal() async {
    if (_selectedImages.isEmpty) return [];
    
    final List<MediaAttachment> attachments = [];
    
    if (kIsWeb) {
      // Web平台：使用Base64编码存储
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        try {
          final bytes = await image.readAsBytes();
          final base64String = base64Encode(bytes);
          final extension = path.extension(image.name).toLowerCase();
          
          // 生成Web兼容的标识符（使用data URI格式）
          final mimeType = _getMimeType(extension);
          final dataUri = 'data:$mimeType;base64,$base64String';
          
          attachments.add(MediaAttachment(
            id: '${timestamp}_$i',
            filePath: dataUri, // Web平台存储data URI
            type: MediaType.image,
            createdAt: DateTime.now(),
          ));
        } catch (e) {
          if (kDebugMode) {
            print('Web平台图片处理失败: $e');
          }
        }
      }
    } else {
      // 移动平台：原有文件系统逻辑
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(appDir.path, 'mood_images'));
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = path.extension(image.name);
        final fileName = '${timestamp}_$i$extension';
        final localPath = path.join(imageDir.path, fileName);
        
        await File(image.path).copy(localPath);
        
        attachments.add(MediaAttachment(
          id: '${timestamp}_$i',
          filePath: localPath,
          type: MediaType.image,
          createdAt: DateTime.now(),
        ));
      }
    }
    
    return attachments;
  }
  
  // 获取MIME类型
  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // 构建预览图片Widget
  Widget _buildPreviewImage(XFile image) {
    if (kIsWeb) {
      // Web平台：使用网络图片
      return FutureBuilder<Uint8List>(
        future: image.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      );
    } else {
      // 移动平台：使用文件路径
      return Image.file(
        File(image.path),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      );
    }
  }

  Future<void> _analyzeEmotion() async {
    if (!_canAnalyze()) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _emotionService.analyzeEmotionUnified(_textController.text.trim());
      setState(() {
        // 转换为旧的结果格式以保持UI兼容
        _analysisResult = EmotionAnalysisResult(
          moodType: result.moodType,
          score: result.emotionScore,
          confidence: result.confidence ?? 0.5,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveMoodEntry() async {
    final textContent = _textController.text.trim();
    if (textContent.isEmpty && _selectedImages.isEmpty) {
      setState(() {
        _validationMessage = '请输入文字或选择图片';
      });
      return;
    }
    
    if (_analysisResult == null && textContent.isNotEmpty) {
      await _analyzeEmotion();
      if (_analysisResult == null) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 保存图片到本地
      final mediaAttachments = await _saveImagesToLocal();
      
      // 创建Fragment（仅图片时使用中性情绪）
      final fragment = MoodFragment.create(
        textContent: textContent.isNotEmpty ? textContent : null,
        media: mediaAttachments,
        mood: _analysisResult?.moodType ?? MoodType.neutral,
        emotionScore: _analysisResult?.score ?? 50,
      );

      await _fragmentStorage.saveFragment(fragment);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示成功保存
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('心情记录已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.positive:
        return const Color(0xFF4CAF50);
      case MoodType.negative:
        return const Color(0xFFFF5722);
      case MoodType.neutral:
        return const Color(0xFF607D8B);
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 70) {
      return const Color(0xFF4CAF50);
    } else if (score >= 40) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFFF5722);
    }
  }

  IconData _getScoreIcon(int score) {
    if (score >= 80) {
      return Icons.sentiment_very_satisfied;
    } else if (score >= 60) {
      return Icons.sentiment_satisfied;
    } else if (score >= 40) {
      return Icons.sentiment_neutral;
    } else if (score >= 20) {
      return Icons.sentiment_dissatisfied;
    } else {
      return Icons.sentiment_very_dissatisfied;
    }
  }
}