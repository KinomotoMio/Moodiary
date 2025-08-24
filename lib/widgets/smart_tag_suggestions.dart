import 'package:flutter/material.dart';
import '../services/smart_tag_extractor_service.dart';

/// 智能标签建议弹窗
class SmartTagSuggestionSheet extends StatefulWidget {
  final SmartTagSuggestion suggestion;
  final Function(List<String> selectedKeywords) onConfirm;

  const SmartTagSuggestionSheet({
    super.key,
    required this.suggestion,
    required this.onConfirm,
  });

  @override
  State<SmartTagSuggestionSheet> createState() => _SmartTagSuggestionSheetState();
}

class _SmartTagSuggestionSheetState extends State<SmartTagSuggestionSheet> {
  final Set<String> _selectedKeywords = <String>{};

  @override
  void initState() {
    super.initState();
    // 默认选中评分最高的3个建议
    final topSuggestions = widget.suggestion.suggestions.take(3);
    for (final suggestion in topSuggestions) {
      _selectedKeywords.add(suggestion.keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildContent(),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '智能标签化',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '发现 ${widget.suggestion.suggestionCount} 个建议',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '选择要转换为标签的关键词，我们会在原文中自动添加#标记',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选择状态指示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '已选择 ${_selectedKeywords.length} 个关键词',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 建议列表
            ...widget.suggestion.suggestions.map((suggestion) {
              final isSelected = _selectedKeywords.contains(suggestion.keyword);
              return _buildSuggestionItem(suggestion, isSelected);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(TagSuggestionItem suggestion, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedKeywords.remove(suggestion.keyword);
              } else {
                _selectedKeywords.add(suggestion.keyword);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected 
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // 选择指示器
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  child: isSelected 
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
                ),
                
                const SizedBox(width: 12),
                
                // 关键词内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${suggestion.keyword}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getReasonColor(suggestion.reason).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              suggestion.reason,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getReasonColor(suggestion.reason),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (suggestion.positions.length > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          '出现 ${suggestion.positions.length} 次',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 评分指示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    suggestion.score.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // 全选/取消全选
          TextButton.icon(
            onPressed: () {
              setState(() {
                if (_selectedKeywords.length == widget.suggestion.suggestions.length) {
                  _selectedKeywords.clear();
                } else {
                  _selectedKeywords.clear();
                  _selectedKeywords.addAll(
                    widget.suggestion.suggestions.map((s) => s.keyword),
                  );
                }
              });
            },
            icon: Icon(
              _selectedKeywords.length == widget.suggestion.suggestions.length 
                ? Icons.deselect 
                : Icons.select_all,
              size: 18,
            ),
            label: Text(
              _selectedKeywords.length == widget.suggestion.suggestions.length 
                ? '取消全选' 
                : '全选',
            ),
          ),
          
          const Spacer(),
          
          // 取消按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          
          const SizedBox(width: 8),
          
          // 确认按钮
          FilledButton.icon(
            onPressed: _selectedKeywords.isEmpty 
              ? null 
              : () {
                  widget.onConfirm(_selectedKeywords.toList());
                  Navigator.of(context).pop();
                },
            icon: const Icon(Icons.auto_fix_high, size: 18),
            label: Text(
              _selectedKeywords.isEmpty 
                ? '请选择关键词' 
                : '转换为标签 (${_selectedKeywords.length})',
            ),
          ),
        ],
      ),
    );
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case '常用标签':
        return Colors.blue;
      case '情绪相关':
        return Colors.orange;
      case '场景活动':
        return Colors.green;
      case '关键词':
      default:
        return Colors.grey;
    }
  }
}

/// 智能标签化按钮组件
class SmartTagButton extends StatelessWidget {
  final int suggestionCount;
  final VoidCallback onPressed;
  final bool isLoading;

  const SmartTagButton({
    super.key,
    required this.suggestionCount,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: suggestionCount > 0 && !isLoading ? onPressed : null,
        icon: isLoading 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : Icon(
              Icons.auto_awesome,
              size: 18,
              color: suggestionCount > 0 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
        label: Text(
          isLoading 
            ? '分析中...'
            : suggestionCount > 0 
              ? '智能标签化 ($suggestionCount)'
              : '智能标签化',
          style: TextStyle(
            color: suggestionCount > 0 && !isLoading
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: suggestionCount > 0 && !isLoading
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}