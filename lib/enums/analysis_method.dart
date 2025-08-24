/// 情绪分析方式枚举
/// 
/// 定义系统支持的各种情绪分析方法，便于配置化选择和扩展
enum AnalysisMethod {
  /// 基于规则的传统分析方法
  /// 使用关键词匹配和简单规则进行情绪判断
  rule('规则分析', 'rule'),
  
  /// 基于大语言模型的AI分析
  /// 调用远程AI服务API进行智能情绪分析
  llm('AI分析', 'llm'),
  
  /// 基于本地AI模型的分析（预留）
  /// 使用设备本地运行的轻量级AI模型
  local('本地AI', 'local');

  const AnalysisMethod(this.displayName, this.value);
  
  /// 显示名称，用于UI展示
  final String displayName;
  
  /// 配置值，用于存储和序列化
  final String value;
  
  /// 从配置值创建枚举实例
  static AnalysisMethod fromValue(String value) {
    return AnalysisMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => AnalysisMethod.rule, // 默认使用规则分析
    );
  }
  
  /// 获取描述信息
  String get description {
    switch (this) {
      case AnalysisMethod.rule:
        return '使用关键词和规则进行快速分析，离线可用';
      case AnalysisMethod.llm:
        return '使用AI大模型进行智能分析，需要网络连接';
      case AnalysisMethod.local:
        return '使用本地AI模型分析，兼顾准确性和隐私';
    }
  }
  
  /// 是否需要网络连接
  bool get requiresNetwork {
    switch (this) {
      case AnalysisMethod.rule:
        return false;
      case AnalysisMethod.llm:
        return true;
      case AnalysisMethod.local:
        return false;
    }
  }
  
  /// 是否可用（本地AI暂未实现）
  bool get isAvailable {
    switch (this) {
      case AnalysisMethod.rule:
        return true;
      case AnalysisMethod.llm:
        return true;
      case AnalysisMethod.local:
        return false; // 预留功能，暂未实现
    }
  }
}