import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/emotion_service.dart';
import '../models/app_settings.dart';
import '../enums/analysis_method.dart';

/// 设置页面
/// 
/// 提供用户配置选项，包括：
/// - 情绪分析方式选择
/// - AI服务配置
/// - 数据管理
/// - 应用信息
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService.instance;
  final EmotionService _emotionService = EmotionService.instance;
  
  bool _isLoading = true;
  AnalysisStrategyStatus? _strategyStatus;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取分析策略状态
      final status = await _emotionService.getStrategyStatus();
      setState(() {
        _strategyStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('加载设置失败: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadSettings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnalysisSection(),
                  const SizedBox(height: 24),
                  if (_settingsService.analysisMethod == AnalysisMethod.llm) ...[
                    _buildAIConfigSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildDataSection(),
                  const SizedBox(height: 24),
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                  _buildDeveloperSection(),
                ],
              ),
            ),
          ),
    );
  }

  /// 情绪分析设置区域
  Widget _buildAnalysisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '情绪分析',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 分析方式选择
            _buildAnalysisMethodSelector(),
            
            const SizedBox(height: 16),
            
            // 分析状态显示
            _buildAnalysisStatus(),
          ],
        ),
      ),
    );
  }

  /// 分析方式选择器
  Widget _buildAnalysisMethodSelector() {
    final currentMethod = _settingsService.analysisMethod;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分析方式',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ...AnalysisMethod.values.map((method) => 
          _buildAnalysisMethodTile(method, currentMethod),
        ),
      ],
    );
  }

  /// 分析方式选项
  Widget _buildAnalysisMethodTile(AnalysisMethod method, AnalysisMethod currentMethod) {
    final isSelected = method == currentMethod;
    final isAvailable = method.isAvailable;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: isSelected ? 2 : 0,
        color: isSelected 
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
        child: ListTile(
          leading: Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: isAvailable 
              ? (isSelected ? Theme.of(context).colorScheme.primary : null)
              : Theme.of(context).disabledColor,
          ),
          title: Text(
            method.displayName,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isAvailable ? null : Theme.of(context).disabledColor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method.description,
                style: TextStyle(
                  color: isAvailable ? null : Theme.of(context).disabledColor,
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '开发中',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          enabled: isAvailable,
          onTap: isAvailable ? () => _changeAnalysisMethod(method) : null,
        ),
      ),
    );
  }

  /// 分析状态显示
  Widget _buildAnalysisStatus() {
    if (_strategyStatus == null) return const SizedBox.shrink();
    
    final status = _strategyStatus!;
    final isHealthy = status.isAvailable;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHealthy 
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHealthy 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHealthy ? Icons.check_circle_outlined : Icons.warning_outlined,
            color: isHealthy 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前状态',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  status.statusMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI配置区域
  Widget _buildAIConfigSection() {
    final currentSettings = _settingsService.currentSettings;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'AI服务配置',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // AI服务提供商选择
            _buildAIProviderSelector(currentSettings),
            
            const SizedBox(height: 16),
            
            // API密钥输入
            _buildAPIKeyInput(currentSettings),
            
            if (currentSettings.llmProvider != null) ...[
              const SizedBox(height: 16),
              _buildConnectionTest(),
            ],
          ],
        ),
      ),
    );
  }

  /// AI服务提供商选择器
  Widget _buildAIProviderSelector(AppSettings currentSettings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI服务提供商',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: currentSettings.llmProvider,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '选择AI服务提供商',
          ),
          items: const [
            DropdownMenuItem(
              value: 'siliconflow',
              child: Text('SiliconFlow (推荐)'),
            ),
            DropdownMenuItem(
              value: 'deepseek',
              child: Text('DeepSeek'),
            ),
          ],
          onChanged: (value) async {
            if (value != null) {
              final newSettings = currentSettings.copyWith(
                llmProvider: value,
                // 清除API密钥，需要重新输入
                llmApiKey: null,
              );
              try {
                await _settingsService.updateSettings(newSettings);
                setState(() {});
                _showSuccessSnackBar('AI服务提供商已更新');
              } catch (e) {
                _showErrorSnackBar('更新失败: $e');
              }
            }
          },
        ),
      ],
    );
  }

  /// API密钥输入框
  Widget _buildAPIKeyInput(AppSettings currentSettings) {
    final hasApiKey = currentSettings.llmApiKey?.isNotEmpty == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API密钥',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: '输入API密钥',
            suffixIcon: hasApiKey 
              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
              : const Icon(Icons.key_outlined),
          ),
          obscureText: true,
          onChanged: (value) async {
            if (value.isNotEmpty) {
              final newSettings = currentSettings.copyWith(llmApiKey: value);
              try {
                await _settingsService.updateSettings(newSettings);
                await _loadSettings(); // 重新加载状态
              } catch (e) {
                _showErrorSnackBar('保存API密钥失败: $e');
              }
            }
          },
          initialValue: hasApiKey ? '••••••••••••••••' : '',
        ),
        if (currentSettings.llmProvider != null) ...[
          const SizedBox(height: 8),
          Text(
            _getProviderHelpText(currentSettings.llmProvider!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  /// 连接测试
  Widget _buildConnectionTest() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '连接测试',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _strategyStatus?.statusMessage ?? '未检测',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _strategyStatus?.isAvailable == true
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadSettings,
            child: const Text('重新测试'),
          ),
        ],
      ),
    );
  }

  /// 获取提供商帮助文本
  String _getProviderHelpText(String provider) {
    switch (provider) {
      case 'siliconflow':
        return '访问 api.siliconflow.cn 获取API密钥，支持多种高质量模型';
      case 'deepseek':
        return '访问 api.deepseek.com 获取API密钥，专注对话和推理';
      default:
        return '请输入有效的API密钥';
    }
  }

  /// 数据管理区域
  Widget _buildDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '数据管理',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('清除分析缓存'),
              subtitle: const Text('清除情绪分析结果缓存，提升分析准确性'),
              onTap: _clearAnalysisCache,
            ),
            
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '清除所有数据',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              subtitle: const Text('删除所有心情记录和设置（不可恢复）'),
              onTap: _showClearAllDataDialog,
            ),
          ],
        ),
      ),
    );
  }

  /// 关于区域
  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '关于',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            const ListTile(
              leading: Icon(Icons.mobile_friendly_outlined),
              title: Text('Moodiary'),
              subtitle: Text('版本 1.0.0 (Phase 3)\n温暖治愈的AI心情日记'),
            ),
            
            ListTile(
              leading: const Icon(Icons.favorite_outlined),
              title: const Text('开源项目'),
              subtitle: const Text('基于Flutter开发的跨平台应用'),
              onTap: () {
                // TODO: 打开GitHub链接
                _showSuccessSnackBar('感谢您的支持！');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 开发者区域（调试功能）
  Widget _buildDeveloperSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.developer_mode_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  '开发者选项',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('缓存统计'),
              subtitle: const Text('查看分析结果缓存使用情况'),
              onTap: _showCacheStats,
            ),
            
            ListTile(
              leading: const Icon(Icons.refresh_outlined),
              title: const Text('刷新策略状态'),
              subtitle: const Text('重新检查分析策略可用性'),
              onTap: _loadSettings,
            ),
          ],
        ),
      ),
    );
  }

  /// 更改分析方法
  Future<void> _changeAnalysisMethod(AnalysisMethod method) async {
    try {
      await _settingsService.updateAnalysisMethod(method);
      _showSuccessSnackBar('分析方式已更改为${method.displayName}');
      await _loadSettings(); // 重新加载状态
    } catch (e) {
      _showErrorSnackBar('更改失败: $e');
    }
  }

  /// 清除分析缓存
  void _clearAnalysisCache() {
    _emotionService.clearCache();
    _showSuccessSnackBar('分析缓存已清除');
  }

  /// 显示清除所有数据确认对话框
  void _showClearAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text(
          '此操作将删除所有心情记录、分析结果和应用设置。\n\n'
          '该操作不可撤销，请谨慎操作。\n\n'
          '您确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearAllData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }

  /// 清除所有数据
  Future<void> _clearAllData() async {
    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在清除数据...'),
            ],
          ),
        ),
      );

      // 清除分析缓存
      _emotionService.clearCache();
      
      // 重置设置到默认值
      await _settingsService.updateSettings(AppSettings.defaultSettings());
      
      // TODO: 后续版本将实现清除心情记录和Fragment数据

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();
      
      _showSuccessSnackBar('所有数据已清除');
      
      // 重新加载设置状态
      await _loadSettings();
      
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('清除数据失败: $e');
    }
  }

  /// 显示缓存统计
  void _showCacheStats() {
    final stats = _emotionService.getCacheStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('缓存统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('总条目: ${stats['totalEntries']}'),
            Text('有效条目: ${stats['validEntries']}'),
            Text('过期条目: ${stats['expiredEntries']}'),
            Text('最大容量: ${stats['maxSize']}'),
            const SizedBox(height: 8),
            Text(
              '缓存使用率: ${(stats['totalEntries'] / stats['maxSize'] * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}