import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../services/storage_service.dart';
import 'edit_mood_screen.dart';

class MoodDetailScreen extends StatelessWidget {
  final MoodEntry entry;

  const MoodDetailScreen({
    super.key,
    required this.entry,
  });

  StorageService get _storageService => StorageService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心情详情'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => EditMoodScreen(entry: entry),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true); // 返回到上一页并刷新数据
              }
            },
            tooltip: '编辑',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除记录', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeCard(context),
            const SizedBox(height: 16),
            _buildMoodAnalysisCard(context),
            const SizedBox(height: 16),
            _buildContentCard(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.schedule_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '记录时间',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDetailDateTime(entry.timestamp),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatRelativeTime(entry.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAnalysisCard(BuildContext context) {
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
                  '情绪分析',
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
                    context,
                    '情绪类型',
                    entry.mood.displayName,
                    entry.mood.emoji,
                    _getMoodColor(entry.mood),
                  ),
                ),
                Expanded(
                  child: _buildAnalysisItem(
                    context,
                    '情绪强度',
                    '${entry.emotionScore}分',
                    _getScoreIcon(entry.emotionScore),
                    _getScoreColor(entry.emotionScore),
                  ),
                ),
                Expanded(
                  child: _buildAnalysisItem(
                    context,
                    '情绪等级',
                    _getScoreLevel(entry.emotionScore),
                    Icons.trending_up_outlined,
                    _getScoreColor(entry.emotionScore),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildEmotionProgressBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(BuildContext context, String label, String value, dynamic icon, Color color) {
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmotionProgressBar(BuildContext context) {
    final progress = entry.emotionScore / 100.0;
    final color = _getScoreColor(entry.emotionScore);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '情绪强度指示',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${entry.emotionScore}/100',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.7),
                    color,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '心情记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => EditMoodScreen(entry: entry),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true); // 返回到上一页并刷新数据
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('编辑记录'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除记录'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条心情记录吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 关闭对话框
              
              // 执行删除操作
              try {
                await _storageService.deleteMoodEntry(entry.id);
                if (context.mounted) {
                  Navigator.of(context).pop(true); // 返回 true 表示已删除
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('心情记录已删除'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
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

  String _getScoreLevel(int score) {
    if (score >= 80) {
      return '非常积极';
    } else if (score >= 60) {
      return '比较积极';
    } else if (score >= 40) {
      return '中性平和';
    } else if (score >= 20) {
      return '比较消极';
    } else {
      return '非常消极';
    }
  }

  String _formatDetailDateTime(DateTime dateTime) {
    final now = DateTime.now();
    
    if (dateTime.year == now.year) {
      return DateFormat('MM月dd日 HH:mm').format(dateTime);
    } else {
      return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).round();
      return '$weeks周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return '$months个月前';
    } else {
      final years = (difference.inDays / 365).round();
      return '$years年前';
    }
  }
}