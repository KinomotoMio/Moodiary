import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/emotion_service.dart';
import '../services/fragment_storage_service.dart';
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
  final FragmentStorageService _fragmentStorage = FragmentStorageService.instance;
  
  final bool _isLoading = false;
  AnalysisStrategyStatus? _strategyStatus;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // 不再自动检查API连通性，设置页面加载应该是即时的
  }

  Future<void> _testAPIConnection() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
      _strategyStatus = null; // 重置之前的测试状态
    });

    try {
      final status = await _emotionService.getStrategyStatus();
      if (mounted) {
        setState(() {
          _strategyStatus = status;
          _isTesting = false;
        });
        
        if (status.isAvailable) {
          _showSuccessSnackBar('API连通性测试成功');
        } else {
          _showErrorSnackBar('API连通性测试失败: ${status.statusMessage}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _strategyStatus = AnalysisStrategyStatus(
            method: _settingsService.currentSettings.analysisMethod,
            isAvailable: false,
            statusMessage: '测试失败: $e',
            canFallback: false,
          );
        });
        _showErrorSnackBar('API连通性测试失败: $e');
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
                // 设置新提供商的默认模型
                llmModel: AppSettings.getDefaultModel(value),
              );
              try {
                await _settingsService.updateSettings(newSettings);
                setState(() {
                  // 重置API测试状态，因为提供商配置发生了变化
                  _strategyStatus = null;
                });
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
                // 重置API测试状态，因为API密钥发生了变化
                setState(() {
                  _strategyStatus = null;
                });
              } catch (e) {
                _showErrorSnackBar('保存API密钥失败: $e');
              }
            }
          },
          initialValue: hasApiKey ? '••••••••••••••••' : '',
        ),
        if (currentSettings.llmProvider != null) ...[
          const SizedBox(height: 16),
          _buildModelSelector(currentSettings),
          const SizedBox(height: 8),
          Text(
            _getProviderHelpText(currentSettings.llmProvider!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  /// 模型选择器
  Widget _buildModelSelector(AppSettings currentSettings) {
    final provider = currentSettings.llmProvider!;
    final availableModels = AppSettings.getAvailableModels(provider);
    final currentModel = currentSettings.llmModel ?? AppSettings.getDefaultModel(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '模型选择',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: availableModels.contains(currentModel) ? currentModel : null,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '选择AI模型',
          ),
          items: availableModels.map((model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Text(
                AppSettings.getModelDisplayName(provider, model),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? value) async {
            if (value != null) {
              final newSettings = currentSettings.copyWith(llmModel: value);
              try {
                await _settingsService.updateSettings(newSettings);
                // 重置API测试状态，因为模型配置发生了变化
                setState(() {
                  _strategyStatus = null;
                });
                _showSuccessSnackBar('AI模型已更新为 ${AppSettings.getModelDisplayName(provider, value)}');
              } catch (e) {
                _showErrorSnackBar('更新模型失败: $e');
              }
            }
          },
        ),
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
                  _isTesting 
                      ? '测试中...' 
                      : (_strategyStatus?.statusMessage ?? '点击测试按钮检查连接状态'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _isTesting 
                        ? Theme.of(context).colorScheme.secondary
                        : (_strategyStatus?.isAvailable == true
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isTesting ? null : _testAPIConnection,
            child: Text(_isTesting ? '测试中' : '测试连接'),
          ),
        ],
      ),
    );
  }

  /// 打开GitHub仓库
  Future<void> _openGitHubRepo() async {
    try {
      final uri = Uri.parse('https://github.com/KinomotoMio/Moodiary');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('无法打开链接，请检查浏览器设置');
      }
    } catch (e) {
      _showErrorSnackBar('打开链接失败: $e');
    }
  }
  
  /// 打开GitHub Issues
  Future<void> _openGitHubIssues() async {
    try {
      final uri = Uri.parse('https://github.com/KinomotoMio/Moodiary/issues');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('无法打开链接，请检查浏览器设置');
      }
    } catch (e) {
      _showErrorSnackBar('打开链接失败: $e');
    }
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

  /// 使用统计区域
  Widget _buildStatsSection() {
    return FutureBuilder(
      future: _getAppStatistics(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final stats = snapshot.data!;
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('使用统计'),
              subtitle: Text('您的Moodiary使用概况'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '总记录数',
                      '${stats['totalEntries']}',
                      Icons.edit_note_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '使用天数',
                      '${stats['usageDays']}',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '平均情绪',
                      '${stats['averageScore'].toStringAsFixed(1)}分',
                      Icons.psychology_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '当前分析',
                      stats['currentMethod'],
                      Icons.smart_toy_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// 统计项目组件
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  /// 获取应用统计数据
  Future<Map<String, dynamic>> _getAppStatistics() async {
    try {
      final fragments = await _fragmentStorage.getAllFragments();
      final settings = _settingsService.currentSettings;
      
      // 计算使用天数（从第一条记录到现在）
      int usageDays = 0;
      if (fragments.isNotEmpty) {
        final firstFragment = fragments.last; // 按时间降序排列，最后一个是最早的
        final daysSinceFirst = DateTime.now().difference(firstFragment.timestamp).inDays;
        usageDays = daysSinceFirst + 1; // 包含今天
      }
      
      // 计算平均情绪分数
      double averageScore = 0.0;
      if (fragments.isNotEmpty) {
        final totalScore = fragments.fold<int>(0, (sum, fragment) => sum + fragment.emotionScore);
        averageScore = totalScore / fragments.length;
      }
      
      // 获取当前分析方式
      String currentMethod = settings.analysisMethod.displayName;
      
      return {
        'totalEntries': fragments.length,
        'usageDays': usageDays,
        'averageScore': averageScore,
        'currentMethod': currentMethod,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'usageDays': 0,
        'averageScore': 0.0,
        'currentMethod': '规则分析',
      };
    }
  }

  /// 故事区域 - 设计理念
  Widget _buildStorySection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '静海 · 设计理念',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStoryText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取故事文本
  String _getStoryText() {
    return '''我们把这个版本叫做"静海"，取自月球表面那片名为Mare Tranquillitatis的宁静之海。

1969年7月，阿波罗11号在静海着陆，人类第一次踏足地外星球。宇航员看到的不是波涛汹涌的海洋，而是一片古老而宁静的平原——那里没有海水，只有岁月沉淀下来的宁静。

就像情绪的本质一样。

我们总是被表面的情绪波动所扰动，但在那些起伏的背后，存在着一片更深层的宁静之地。那里有你真实的感受，有你内心的声音，有你与自己对话的空间。

Moodiary想要做的，就是帮你找到那片静海。不是让你的情绪变得麻木，而是在情绪的潮起潮落中，为你保留一片可以安静感受、真实记录的地方。

当你在这里记录每一个情绪片段时，AI会像月球表面轻柔的引力一样，温和地理解你，不评判，只陪伴。让技术的智能与人心的温暖，在这片数字静海中安然相遇。

愿每个使用Moodiary的人，都能在生活的喧嚣中，找到属于自己的那片静海。''';
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
              subtitle: Text('版本 v1.0.0-beta.1 · 静海 (Tranquillity)\nPhase 3 - AI增强版\n温暖治愈的AI心情日记'),
            ),
            
            const Divider(),
            _buildStatsSection(),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.favorite_outlined),
              title: const Text('开源项目'),
              subtitle: const Text('基于Flutter开发的跨平台应用'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                _openGitHubRepo();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('问题反馈'),
              subtitle: const Text('报告问题或提出功能建议'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                _openGitHubIssues();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.info_outlined),
              title: const Text('AI功能说明'),
              subtitle: const Text('支持SiliconFlow、DeepSeek多种AI服务\n数据本地存储，仅分析时调用API'),
            ),
            
            const Divider(),
            _buildStorySection(),
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
      final currentSettings = _settingsService.currentSettings;
      AppSettings newSettings;
      
      if (method == AnalysisMethod.llm) {
        // 切换到AI分析时，提供默认的配置
        newSettings = currentSettings.copyWith(
          analysisMethod: method,
          llmProvider: currentSettings.llmProvider ?? 'siliconflow', // 默认使用SiliconFlow
          // 不设置API密钥，让用户后续配置
        );
      } else {
        // 切换到规则分析或本地AI
        newSettings = currentSettings.copyWith(
          analysisMethod: method,
        );
      }
      
      await _settingsService.updateSettings(newSettings);
      _showSuccessSnackBar('分析方式已更改为${method.displayName}');
      
      // 重置API测试状态，因为配置发生了变化
      setState(() {
        _strategyStatus = null;
      });
      
      if (method == AnalysisMethod.llm && newSettings.llmApiKey == null) {
        // 提示用户配置API密钥
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _showErrorSnackBar('请在下方配置AI服务提供商和API密钥');
          }
        });
      }
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