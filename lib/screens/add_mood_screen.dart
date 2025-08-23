import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import '../services/emotion_service.dart';

class AddMoodScreen extends StatefulWidget {
  const AddMoodScreen({super.key});

  @override
  State<AddMoodScreen> createState() => _AddMoodScreenState();
}

class _AddMoodScreenState extends State<AddMoodScreen> {
  final TextEditingController _textController = TextEditingController();
  final StorageService _storageService = StorageService.instance;
  final EmotionService _emotionService = EmotionService.instance;
  
  bool _isAnalyzing = false;
  bool _isSaving = false;
  EmotionAnalysisResult? _analysisResult;
  int _characterCount = 0;
  String? _validationMessage;
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录心情'),
        elevation: 0,
        actions: [
          if (_textController.text.isNotEmpty && _analysisResult != null)
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
                hintText: '记录下你的想法、感受或今天发生的事情...\n\n你可以写下：\n• 今天的心情如何\n• 遇到了什么事情\n• 有什么感想或想法',
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
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
                Expanded(
                  child: _buildAnalysisItem(
                    '置信度',
                    '${(result.confidence * 100).toStringAsFixed(0)}%',
                    Icons.verified_outlined,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
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

  Future<void> _analyzeEmotion() async {
    if (!_canAnalyze()) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = _emotionService.analyzeEmotion(_textController.text.trim());
      setState(() {
        _analysisResult = result;
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
    if (_textController.text.trim().isEmpty || _analysisResult == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final entry = MoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _textController.text.trim(),
        timestamp: DateTime.now(),
        mood: _analysisResult!.moodType,
        emotionScore: _analysisResult!.score,
      );

      await _storageService.saveMoodEntry(entry);

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