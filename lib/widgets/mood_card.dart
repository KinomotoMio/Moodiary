import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodCard extends StatelessWidget {
  final MoodEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MoodCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry.mood).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getMoodColor(entry.mood).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.mood.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.mood.displayName,
                          style: TextStyle(
                            color: _getMoodColor(entry.mood),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildEmotionScore(),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDateTime(entry.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor().withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '${entry.emotionScore}分',
        style: TextStyle(
          color: _getScoreColor(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.positive:
        return const Color(0xFF4CAF50); // 绿色
      case MoodType.negative:
        return const Color(0xFFFF5722); // 橙红色
      case MoodType.neutral:
        return const Color(0xFF607D8B); // 蓝灰色
    }
  }

  Color _getScoreColor() {
    if (entry.emotionScore >= 70) {
      return const Color(0xFF4CAF50); // 绿色 - 高分
    } else if (entry.emotionScore >= 40) {
      return const Color(0xFFFF9800); // 橙色 - 中等
    } else {
      return const Color(0xFFFF5722); // 红色 - 低分
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 今天
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // 一周内
      try {
        return DateFormat('EEEE HH:mm', 'zh_CN').format(dateTime);
      } catch (e) {
        return DateFormat('EEEE HH:mm').format(dateTime);
      }
    } else if (dateTime.year == now.year) {
      // 今年
      return DateFormat('MM月dd日 HH:mm').format(dateTime);
    } else {
      // 其他年份
      return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
    }
  }
}