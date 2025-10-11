import 'dart:convert';
import '../../../models/mood_fragment.dart';
import '../../../models/mood_entry.dart';

/// 睡前阅读摘要Prompt生成器
///
/// 设计理念：
/// 1. 帮助用户快速回顾一天发生的事情和情绪流向
/// 2. 温暖、治愈的语言风格，不评判
/// 3. 个性化的正念冥想引导，助眠
/// 4. 结合具体事件，让内容有温度
class BedtimeSummaryPrompt {
  /// 生成睡前摘要的Prompt
  ///
  /// [fragments] 今日的所有Fragment记录
  /// [dominantMood] 今日主导情绪
  /// [averageScore] 今日平均情绪评分
  static String generateSummaryPrompt({
    required List<MoodFragment> fragments,
    String? dominantMood,
    double? averageScore,
  }) {
    // 准备上下文信息
    final context = _buildContext(fragments, dominantMood, averageScore);

    return '''
你是一位温暖、专业的心理健康陪伴者。现在是睡前时光，请根据用户今天的心情记录，生成一段治愈的睡前阅读内容。

## 用户今日记录

$context

## 任务要求

请生成包含以下三部分的内容（使用JSON格式返回）：

### 1. 事件回顾 (event_summary)
- **目的**：让用户快速了解"今天发生了什么"
- **字数**：80-120字
- **风格**：简洁、客观、时间线叙述
- **内容要点**：
  * 按时间顺序梳理今天的主要事件（如果有多条记录）
  * 提及具体的活动、人物、场景（基于标签和内容）
  * 如果只有一条记录，简要概括这条记录的核心事件
  * 用叙述性语言，不加情绪评判
- **示例**：
  - "上午你投入工作中，处理了项目的一些技术问题。中午和朋友聊了会儿天，下午继续忙碌。晚上终于有时间放松，看了会儿书。"
  - "今天主要围绕工作展开，你参加了几个会议，也完成了一些任务。"

### 2. 情绪流向 (emotion_review)
- **目的**：帮助用户理解情绪与事件的关联
- **字数**：120-160字
- **风格**：温暖、肯定、非评判性
- **内容要点**：
  * 点出今天情绪的整体走向（平稳/起伏/低落/愉悦）
  * 自然地关联到具体事件（如"工作上的挑战让你感到压力"）
  * 肯定用户觉察和记录情绪的行为
  * 用第二人称"你"，营造亲切感
  * 不评判对错，只陪伴和理解
- **禁止**：
  * 不使用"加油""努力"等打鸡血式鼓励
  * 不说教，不给建议（如"你应该..."）
  * 不否定负面情绪

### 3. 冥想引导词 (meditation_guide)
- **目的**：引导用户放松身心，进入睡眠
- **字数**：100-130字
- **风格**：舒缓、节奏缓慢、引导性
- **内容要点**：
  * 从呼吸开始，引导放松身体
  * **个性化**：根据今天的事件或情绪，自然地引导接纳
    - 如果今天有具体事件：引导将事件"安放"
    - 如果情绪低落：引导温柔地接纳这份感受
    - 如果情绪愉悦：引导带着这份美好入眠
  * 温柔地引导进入睡眠
  * 使用"慢慢地""轻轻地""允许"等舒缓词汇
- **禁止**：
  * 不使用刺激性词汇
  * 不涉及复杂的冥想技巧
  * 不说教或强迫用户"必须放下"

## 返回格式

严格按照以下JSON格式返回（不要包含markdown代码块标记```）：

{
  "event_summary": "事件回顾内容...",
  "emotion_review": "情绪流向内容...",
  "meditation_guide": "冥想引导词内容..."
}

## 完整示例

假设用户今天记录了：
- 上午：工作压力大，#工作 #压力
- 晚上：和朋友聚餐，#朋友 #放松

应该生成：

{
  "event_summary": "上午你投入到工作中，面对一些挑战和压力。晚上，你和朋友一起聚餐，享受了轻松的时光。一天之中，生活在忙碌和放松之间切换。",
  "emotion_review": "今天的你经历了情绪的小起伏。上午工作上的挑战让你感到有些压力和紧张，这份感受很真实。好在晚上，朋友的陪伴给你带来了放松和愉悦。你能够觉察到这些变化，并且愿意记录下来，这本身就是一种温柔的自我陪伴。无论是压力还是放松，每一种感受都在诉说着你真实的生活。",
  "meditation_guide": "现在，慢慢地把注意力带回到呼吸上。轻轻吸气，感受空气缓缓流入身体；慢慢呼气，让一天的忙碌随之流出。今天工作上的那些挑战，可以先放在一边；朋友带来的温暖，可以留在心里。所有的情绪，无论是紧张还是放松，都可以在这里安放。慢慢地，让身体沉入床铺，允许自己放松，允许自己休息。祝你今晚好梦。"
}

## 特殊情况处理

### 如果今天只有一条记录：
- event_summary：简要概括这条记录的事件
- emotion_review：围绕这一条记录展开，肯定用户记录的行为
- meditation_guide：个性化引导（基于这条记录的情绪或事件）

### 如果今天情绪波动较大（多条记录，情绪类型不同）：
- event_summary：按时间线梳理主要事件
- emotion_review：重点点出情绪的起伏变化
- meditation_guide：引导接纳这种起伏，"情绪有起有落是很自然的"

### 如果今天情绪持续低落（多条negative记录）：
- emotion_review：更多的理解和陪伴，不急于引导"看到好的一面"
- meditation_guide：温柔地引导接纳，不强迫"放下"或"想开"

请开始生成：
''';
  }

  /// 构建上下文信息
  static String _buildContext(
    List<MoodFragment> fragments,
    String? dominantMood,
    double? averageScore,
  ) {
    final buffer = StringBuffer();

    // 基础统计
    buffer.writeln('**今日记录数量**: ${fragments.length}条');
    if (dominantMood != null) {
      buffer.writeln('**主导情绪**: $dominantMood');
    }
    if (averageScore != null) {
      buffer.writeln('**平均情绪评分**: ${averageScore.toStringAsFixed(1)}/100');
    }
    buffer.writeln();

    if (fragments.isEmpty) {
      buffer.writeln('（今日暂无记录）');
      return buffer.toString();
    }

    // 记录详情（最多显示6条，确保AI有足够的上下文）
    buffer.writeln('**今日记录内容**:');
    buffer.writeln();
    final displayFragments = fragments.take(6).toList();

    for (int i = 0; i < displayFragments.length; i++) {
      final fragment = displayFragments[i];
      final time = _formatTime(fragment.timestamp);
      final mood = fragment.mood.displayName;
      final score = fragment.emotionScore;

      buffer.writeln('【记录${i + 1}】$time - $mood情绪 ($score分)');

      // 添加文本内容（完整内容，让AI能更好地理解事件）
      if (fragment.textContent != null && fragment.textContent!.isNotEmpty) {
        final content = fragment.displayContent.trim();
        final truncated = content.length > 150
            ? '${content.substring(0, 150)}...'
            : content;
        buffer.writeln('内容: "$truncated"');
      }

      // 添加标签
      if (fragment.hasTopicTags) {
        buffer.writeln('标签: ${fragment.topicTags.map((t) => '#$t').join(' ')}');
      }

      buffer.writeln();
    }

    if (fragments.length > 6) {
      buffer.writeln('（还有${fragments.length - 6}条记录未显示，但AI已了解全天情绪趋势）');
    }

    // 添加情绪趋势分析提示
    if (fragments.length > 1) {
      buffer.writeln('**注意**: 用户今天有多条记录，请注意梳理时间线和情绪变化。');
    }

    return buffer.toString();
  }

  /// 格式化时间
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 生成无记录时的默认睡前内容
  static Map<String, String> getDefaultContent() {
    return {
      'event_summary': '今天没有留下具体的记录，也许是平静地度过，也许是忙碌到忘记了记录。无论如何，这一天都是你生命中独特的一天。',
      'emotion_review': '虽然没有记录心情，但这不代表你的一天没有意义。每一天都有它的节奏，有时平静，有时匆忙。当你想要记录的时候，这里会一直等着你，陪伴你觉察和记录每一个瞬间的感受。',
      'meditation_guide': '轻轻闭上眼睛，感受呼吸的节奏。吸气，让新鲜的空气充盈身体；呼气，让今天的一切慢慢沉淀。不必评判今天做了什么、没做什么，允许自己就这样安静地休息。慢慢地，让身体放松下来，进入梦乡。晚安。',
    };
  }

  /// 解析LLM返回的JSON响应
  ///
  /// 返回 Map 包含 'event_summary', 'emotion_review' 和 'meditation_guide'
  /// 如果解析失败，返回null
  static Map<String, String>? parseResponse(String response) {
    try {
      // 移除可能的markdown代码块标记
      String cleaned = response.trim();

      // 移除```json 或 ``` 标记
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      // 解析JSON
      final Map<String, dynamic> json = jsonDecode(cleaned);

      // 验证必需字段
      if (json.containsKey('event_summary') &&
          json.containsKey('emotion_review') &&
          json.containsKey('meditation_guide')) {
        return {
          'event_summary': (json['event_summary'] as String).trim(),
          'emotion_review': (json['emotion_review'] as String).trim(),
          'meditation_guide': (json['meditation_guide'] as String).trim(),
        };
      }

      // 字段不完整
      return null;
    } catch (e) {
      // JSON解析失败
      return null;
    }
  }

  /// 验证生成的内容质量
  ///
  /// 检查字数是否符合要求，内容是否为空
  static bool validateContent(Map<String, String> content) {
    // 检查必需字段
    if (!content.containsKey('event_summary') ||
        !content.containsKey('emotion_review') ||
        !content.containsKey('meditation_guide')) {
      return false;
    }

    // 检查内容不为空
    if (content['event_summary']!.trim().isEmpty ||
        content['emotion_review']!.trim().isEmpty ||
        content['meditation_guide']!.trim().isEmpty) {
      return false;
    }

    // 检查字数范围（允许一定的弹性）
    final eventLength = content['event_summary']!.length;
    final emotionLength = content['emotion_review']!.length;
    final meditationLength = content['meditation_guide']!.length;

    // event_summary: 80-120字（允许50-200）
    if (eventLength < 50 || eventLength > 250) return false;

    // emotion_review: 120-160字（允许80-250）
    if (emotionLength < 80 || emotionLength > 300) return false;

    // meditation_guide: 100-130字（允许70-200）
    if (meditationLength < 70 || meditationLength > 250) return false;

    return true;
  }
}
