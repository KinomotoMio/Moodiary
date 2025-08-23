import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood_fragment.dart';
import '../models/mood_entry.dart';

class FragmentCard extends StatelessWidget {
  final MoodFragment fragment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FragmentCard({
    super.key,
    required this.fragment,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: _getMoodColor(fragment.mood).withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _getMoodColor(fragment.mood).withValues(alpha: 0.1),
        highlightColor: _getMoodColor(fragment.mood).withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部行：心情类型、评分、删除按钮
              Row(
                children: [
                  _buildMoodChip(),
                  const Spacer(),
                  _buildEmotionScore(),
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    _buildDeleteButton(context),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 文本内容
              if (fragment.textContent != null && fragment.textContent!.isNotEmpty) ...[
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    height: 1.4,
                  ),
                  child: Text(
                    fragment.displayContent,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // 图片展示
              if (fragment.hasMedia) ...[
                _buildMediaSection(),
                const SizedBox(height: 12),
              ],
              
              // 话题标签
              if (fragment.hasTopicTags) ...[
                _buildTopicTags(context),
                const SizedBox(height: 8),
              ],
              
              // 时间戳
              Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(fragment.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Fragment类型指示器
                  Icon(
                    _getFragmentTypeIcon(),
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _getMoodColor(fragment.mood).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getMoodColor(fragment.mood).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMoodColor(fragment.mood).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fragment.mood.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            fragment.mood.displayName,
            style: TextStyle(
              color: _getMoodColor(fragment.mood),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionScore() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor().withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor().withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '${fragment.emotionScore}分',
        style: TextStyle(
          color: _getScoreColor(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onDelete,
        borderRadius: BorderRadius.circular(20),
        splashColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.delete_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (fragment.media.isEmpty) return const SizedBox();
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fragment.media.length,
        itemBuilder: (context, index) {
          final media = fragment.media[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(media.filePath),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopicTags(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: fragment.topicTags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  IconData _getFragmentTypeIcon() {
    switch (fragment.type) {
      case FragmentType.text:
        return Icons.text_fields_outlined;
      case FragmentType.image:
        return Icons.photo_outlined;
      case FragmentType.mixed:
        return Icons.collections_outlined;
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

  Color _getScoreColor() {
    if (fragment.emotionScore >= 70) {
      return const Color(0xFF4CAF50);
    } else if (fragment.emotionScore >= 40) {
      return const Color(0xFFFF9800);
    } else {
      return const Color(0xFFFF5722);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      try {
        return DateFormat('EEEE HH:mm', 'zh_CN').format(dateTime);
      } catch (e) {
        return DateFormat('EEEE HH:mm').format(dateTime);
      }
    } else if (dateTime.year == now.year) {
      return DateFormat('MM月dd日 HH:mm').format(dateTime);
    } else {
      return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
    }
  }
}