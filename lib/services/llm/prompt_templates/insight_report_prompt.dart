import 'dart:convert';
import '../../../models/mood_fragment.dart';
import '../../../models/insight_report.dart';
import '../../../models/mood_entry.dart';

/// 心理洞察报告Prompt生成器
///
/// 基于CBT（认知行为疗法）框架：
/// 1. 识别情绪模式和触发因素
/// 2. 探索情绪-思维-行为的关联
/// 3. 提供具体可执行的认知重构和行为策略
class InsightReportPrompt {
  /// 生成洞察报告的Prompt
  ///
  /// [fragments] 周期内的所有Fragment记录
  /// [stats] 统计数据
  /// [reportType] 报告类型（周报/月报）
  static String generateInsightPrompt({
    required List<MoodFragment> fragments,
    required ReportStats stats,
    required ReportType reportType,
  }) {
    // 准备上下文信息
    final context = _buildContext(fragments, stats, reportType);

    return '''
你是一位温暖、专业的心理健康专家，擅长CBT（认知行为疗法）。现在需要为用户生成一份${reportType == ReportType.weekly ? '周度' : '月度'}心理洞察报告。

## 核心理念

**CBT三角模型**：情绪、思维、行为相互影响
- 情绪：用户记录的心情状态
- 思维：从记录内容推断的认知模式
- 行为：从标签和事件推断的行为模式

**目标**：
1. 帮助用户觉察情绪模式
2. 识别可能的自动化思维
3. 提供具体可执行的策略

## 用户数据

$context

## 任务要求

请生成包含以下三部分的内容（使用JSON格式返回）：

### 1. 核心洞察 (core_insight)
- **目的**：总结用户这段时间的整体情绪状态和关键发现
- **建议字数**：200-400字（可根据实际情况适当增减）
- **风格**：温暖、深刻、非评判性
- **内容要点**：
  * 描绘整体情绪画像（不只是简单概括，要有细节）
  * 识别2-3个关键情绪模式或转折点
  * 指出特别值得关注的亮点或挑战
  * 肯定用户的觉察和记录行为
  * 用"你"来称呼，营造亲切感和个性化
  * 可以引用用户的具体记录片段
- **写作要求**：
  * 用叙事性语言，让用户感受到"被看见"
  * 避免泛泛而谈，要结合具体数据和事件
  * 既要客观描述，也要传递温暖和理解
- **示例**：
  "这${reportType == ReportType.weekly ? '周' : '个月'}你的情绪经历了从波动到趋稳的过程。开始的几天，工作上的多个截止日期让你感到明显的压力和焦虑，情绪评分在30-45分之间徘徊。你在记录中写道'感觉被任务淹没'，这份真实的表达很珍贵。

  转折出现在周中，当你和老友见面聊天后，情绪有了明显回升。你提到'好久没这样放松了'，这次社交让你意识到自己需要更多这样的时刻。之后的几天，尽管工作依然忙碌，但你的情绪波动幅度明显减小，评分稳定在55-70分区间。

  整体来看，你展现出不错的情绪韧性——能够在低谷中觉察需求，并主动寻求支持。你愿意持续记录，这本身就是一种勇敢的自我关注。"

### 2. 情绪模式分析 (emotion_pattern)
- **目的**：深入剖析情绪的规律、触发因素和心理动力学
- **建议字数**：400-800字（这是核心部分，应该充分展开）
- **风格**：专业、深入、结构化、温和
- **CBT框架应用**：
  * **情绪层面**：详细分析情绪类型、波动规律、周期性、强度变化
  * **思维层面**：识别认知模式（灾难化、过度概括、读心术、情绪推理、非黑即白等）
  * **行为层面**：识别应对模式（回避、拖延、过度工作、寻求支持等）
  * **触发因素**：具体分析事件、人物、场景、时间规律
  * **关联分析**：情绪-思维-行为的相互影响
- **内容结构**：
  1. 情绪整体趋势和特征（200-300字）
  2. 触发因素的深入分析（150-250字）
  3. 认知模式的识别和解读（150-250字）
  4. 情绪调节能力和资源盘点（100-150字）
- **写作要求**：
  * 提供具体例子和记录片段
  * 用通俗语言解释心理学概念
  * 温和地提出可能的认知模式，不下诊断
  * 既要指出挑战，也要识别优势
  * 可以使用小标题分段，提高可读性
- **禁止**：
  * 不做心理疾病诊断
  * 不使用难懂的专业术语
  * 不评判用户的情绪对错
  * 不过度解读或臆测
- **示例**：
  "**情绪的整体画像**

  从数据来看，这${reportType == ReportType.weekly ? '周' : '个月'}你的情绪呈现'工作日低谷-休息日回升'的明显节奏。工作相关的记录（占比65%，带#工作、#压力标签）情绪评分集中在30-55分区间，而带有#朋友、#放松、#运动标签的记录则明显更高，达到70-85分。这种对比提示：工作环境和社交/休闲时光对你的情绪有着截然不同的影响。

  值得注意的是，你的情绪波动呈现一定的周期性。周一到周三情绪评分偏低，周四周五有所回升，周末达到峰值。这可能与工作压力的累积和释放节奏有关。

  **触发因素的深层分析**

  深入你的记录会发现，引发负面情绪的往往不只是'工作忙'本身，而是更具体的情境：
  - 任务不确定性（'不知道领导想要什么'）
  - 时间压力（'deadline临近，还有很多没做完'）
  - 自我怀疑（'担心做不好，怕出错'）

  这些表述背后，隐约可以看到一种模式：当面对不确定或有评价风险的情境时，焦虑会被放大。

  **认知模式的温和观察**

  从你的文字中，能感受到一种'高标准自我期待'的倾向。比如你提到'必须完美完成'、'不能出错'，这种想法在激励自己的同时，也可能会放大压力感。CBT称这种思维为'完美主义陷阱'——我们对自己设定过高标准，一旦达不到就容易自我批评。

  另外，在几条记录中能看到'灾难化思维'的痕迹，比如'如果搞砸了怎么办'、'肯定会被批评'。这种对未来的负面预期，会让当下的压力更重。但值得注意的是，实际情况往往比我们担心的要好——你提到几次'其实也没那么糟'。

  **你的情绪资源和优势**

  在挑战之外，也要看到你的优势：

  首先是觉察能力。你能够清晰地识别不同情境下的情绪变化，这本身就是情绪智力的体现。很多人连'我现在怎么了'都说不清楚，而你已经在做细致的自我观察。

  其次是恢复能力。数据显示，即使情绪跌到谷底（评分30分左右），你也能在1-2天内回升。你会主动采取行动——找朋友聊天、运动、听音乐——这些都是有效的情绪调节策略。

  最后是社交支持。你的记录中多次提到朋友带来的正面影响，这说明你有温暖的社交网络，这是心理韧性的重要来源。"

### 3. 行为建议 (behavior_suggestion)
- **目的**：提供基于CBT的具体、可执行、个性化的策略
- **建议字数**：300-600字（充分展开，提供详细指导）
- **风格**：建议性、温和、具体、可操作
- **CBT技术应用**：
  * **认知重构**：识别和挑战不合理信念的具体方法
  * **行为激活**：增加积极行为的详细计划
  * **情绪调节**：具体的应对技巧和练习
  * **资源强化**：如何更好地利用已有优势
- **内容要求**：
  * 3-5条具体建议，每条都充分展开
  * 提供Why（为什么）和How（如何做）
  * 包含具体的操作步骤或示例
  * 基于用户的实际数据和模式
  * 温和的语气，用"可以尝试"、"或许"、"建议"等词
  * 可以提供工具或资源推荐
- **建议结构**：
  每条建议包含：
  - 标题/主题
  - 理由说明（为什么有效）
  - 具体步骤（如何执行）
  - 预期效果
- **禁止**：
  * 不说教，不用"应该"、"必须"
  * 不提供医疗建议或药物建议
  * 不给出过于宏大或模糊的目标
  * 不忽视用户的现实限制
- **示例**：
  "基于你的情绪模式和实际情况，这里有几个温和的建议供你参考：

  **1. 认知重构练习：挑战'完美主义陷阱'**

  为什么这很重要：从你的记录中能看到，'必须完美'的想法在放大你的压力。当我们追求100分，哪怕做到90分也会觉得焦虑；但如果目标调整为80分，反而可能做得更好。

  具体怎么做：
  • 每天选一个任务，刻意练习'足够好就行'（Good Enough）。比如回复邮件时，不纠结措辞是否完美，写清楚意思就发送。
  • 当发现自己在想'不能出错'时，暂停3秒，问自己：'真的一点错都不能有吗？小错误的后果有我想的那么严重吗？'
  • 记录下'不完美但成功'的经历。你会发现，很多时候80分的结果和100分没什么差别。

  预期效果：2-3周后，你可能会发现自己在工作时更放松，效率反而提高了。

  **2. 主动安排'心理充电时间'**

  为什么这很重要：数据清楚地显示，社交和休闲时间能大幅提升你的情绪（提升20-30分）。但从记录频率看，这些活动偏少。你可能觉得'等忙完再放松'，但实际上，定期充电能让你更好地应对工作压力。

  具体怎么做：
  • 每周日晚上，在日历上标注2-3个'不可取消的充电时间'（和朋友约饭、运动、看电影等）。把它们当作重要会议对待。
  • 设定边界：比如'周五晚8点后不看工作消息'。给自己一个心理上的休息信号。
  • 如果觉得'没时间社交'，可以从小事开始：和朋友微信视频15分钟、午休时散步15分钟，也是有效的充电。

  预期效果：情绪基线可能会提升5-10分，应对工作压力时更有缓冲。

  **3. '情绪急救箱'：建立低落时的应对清单**

  为什么这很重要：你的恢复能力不错，但如果有更清晰的策略，可以恢复得更快。

  具体怎么做：
  • 写一份'情绪急救清单'，列出当你感到低落时，哪些事情对你有效（基于历史记录：和朋友聊天、运动、听音乐等）。
  • 按照执行难度分类：容易（5分钟就能做）、中等（需要30分钟）、需要规划（如约朋友见面）。
  • 当情绪跌到50分以下时，不要在原地打转，打开清单，从'容易'类别里挑一个立刻去做。

  预期效果：情绪谷底的持续时间可能从2天缩短到1天或更短。

  **4. 'worry time'技巧：给焦虑设定时间边界**

  为什么这很重要：你提到'担心这个担心那个'，焦虑会占据很多心智资源。这个技巧能帮你把焦虑'装进盒子'。

  具体怎么做：
  • 每天设定一个15分钟的'焦虑时间'（比如晚上7:00-7:15）。
  • 其他时间，如果焦虑冒出来，告诉自己：'我会处理它，但是在今晚7点。'把它写下来。
  • 到了7点，拿出清单，认真思考每个担忧。你会发现很多担忧到那时已经不重要了，或者你能想出应对方法。

  预期效果：白天工作时更专注，焦虑不再随时干扰你。

  **5. 如果持续低落，考虑寻求专业支持**

  虽然你有不错的自我调节能力，但如果发现：
  • 连续两周情绪评分持续低于40分
  • 自我调节的方法都不再起效
  • 影响到睡眠、食欲或日常功能

  可以考虑咨询专业心理咨询师。这不是'问题很严重'的信号，而是'我值得更专业的支持'的选择。很多人通过几次咨询就能获得很大帮助。"

## 返回格式

严格按照以下JSON格式返回（不要包含markdown代码块标记```）：

{
  "core_insight": "核心洞察内容...",
  "emotion_pattern": "情绪模式分析内容...",
  "behavior_suggestion": "行为建议内容..."
}

## 完整示例

假设用户${reportType == ReportType.weekly ? '这周' : '这个月'}记录了：
- 10条记录，平均评分55分
- 主导情绪：负面情绪（6条）
- 高频标签：#工作（5次）、#朋友（2次）、#焦虑（3次）
- 情绪波动度：较大（标准差28）

应该生成：

{
  "core_insight": "这${reportType == ReportType.weekly ? '周' : '个月'}你的情绪经历了不少起伏。从记录中可以看到，工作是主要的情绪触发源，带来了明显的压力和焦虑。同时，和朋友在一起的时光为你带来了短暂的放松。尽管整体情绪评分不算高，但你能够持续记录、觉察自己的状态，这本身就是很有价值的。你并没有回避低落的情绪，而是勇敢地面对和记录，这种态度是积极的第一步。",
  "emotion_pattern": "从情绪分布来看，负面情绪占据了这${reportType == ReportType.weekly ? '周' : '个月'}的主要部分，特别是与工作相关的记录。焦虑似乎是常见的伴随情绪，这可能与工作中的不确定性或高要求有关。从你的文字中，可以感受到一种'担心做不好'或'害怕出错'的想法，这种想法会放大焦虑感。\n\n不过，值得注意的是，当你和朋友在一起或者有意识地放松时，情绪会明显改善。这说明社交连接和主动休息是你的情绪资源。另外，情绪波动较大也意味着你对环境变化比较敏感，这既是挑战也是优势——敏感让你更能体察细微的情绪，但也需要更多的情绪调节策略。",
  "behavior_suggestion": "基于你的情绪模式，这里有几个温和的建议：\n\n1. **识别焦虑的想法**：下次感到焦虑时，可以尝试写下具体担心的事。然后问自己：'最坏的结果是什么？'、'这个概率有多大？'、'即使发生了我能应对吗？'这个过程能帮助你看清焦虑背后的想法，很多时候它们没有那么可怕。\n\n2. **主动安排积极活动**：既然朋友带来了正面情绪，可以尝试每周至少安排一次社交活动，哪怕只是简单的聊天。将它视为情绪充电的必要安排。\n\n3. **设定工作边界**：如果工作压力持续，可以尝试为自己设定一个'心理休息时间'，比如下班后的第一个小时不看工作消息。小的边界也能带来掌控感的提升。"
}

## 特殊情况处理

### 如果记录数量较少（< 5条）
- core_insight: 肯定用户开始记录的行为，说明数据有限但仍能看到一些趋势
- emotion_pattern: 基于有限数据，做谨慎的推断，提醒"这些观察基于较少的记录"
- behavior_suggestion: 第一条建议是"持续记录"，帮助积累更多数据

### 如果情绪持续低落（平均分<40，负面情绪>80%）
- core_insight: 更多的理解和陪伴，认可用户在低落中仍然记录的勇气
- emotion_pattern: 温和地点出低落的模式，但不制造恐慌
- behavior_suggestion: 提供更基础的情绪调节策略，并温和地建议"如果持续低落，寻求专业支持是明智的选择"

### 如果情绪波动极大（标准差>30）
- core_insight: 点出"情绪如同过山车"的特点
- emotion_pattern: 分析波动的可能原因（外部事件vs内部因素）
- behavior_suggestion: 提供稳定情绪的策略（如建立日常结构、情绪日记等）

### 如果情绪持续积极（平均分>75，正面情绪>80%）
- core_insight: 肯定用户当前的状态，同时不过度美化
- emotion_pattern: 识别维持积极情绪的因素
- behavior_suggestion: 帮助用户"保持"当前状态，并为未来可能的波动做准备

请开始生成：
''';
  }

  /// 构建上下文信息
  static String _buildContext(
    List<MoodFragment> fragments,
    ReportStats stats,
    ReportType reportType,
  ) {
    final buffer = StringBuffer();

    // 基础统计
    buffer.writeln('**统计概览**');
    buffer.writeln('- 报告周期：${reportType.displayName}');
    buffer.writeln('- 记录总数：${stats.totalEntries}条');
    buffer.writeln('- 平均情绪评分：${stats.averageScore.toStringAsFixed(1)}/100');
    if (stats.dominantMood != null) {
      buffer.writeln('- 主导情绪：${stats.dominantMood!.displayName}');
    }
    buffer.writeln('- 情绪波动度：${stats.emotionVolatility.toStringAsFixed(1)} (标准差)');
    buffer.writeln('- 最高评分：${stats.highestScore}分');
    buffer.writeln('- 最低评分：${stats.lowestScore}分');
    buffer.writeln();

    // 情绪分布
    buffer.writeln('**情绪分布**');
    for (final entry in stats.moodDistribution.entries) {
      final percentage = (entry.value / stats.totalEntries * 100).toStringAsFixed(1);
      buffer.writeln('- ${entry.key.displayName}：${entry.value}条 ($percentage%)');
    }
    buffer.writeln();

    // 活跃标签
    if (stats.topTags.isNotEmpty) {
      buffer.writeln('**高频标签（前5）**');
      for (int i = 0; i < stats.topTags.length && i < 5; i++) {
        buffer.writeln('${i + 1}. #${stats.topTags[i]}');
      }
      buffer.writeln();
    }

    if (fragments.isEmpty) {
      buffer.writeln('（本周期暂无记录）');
      return buffer.toString();
    }

    // 记录详情（显示有代表性的记录）
    buffer.writeln('**代表性记录片段**');
    buffer.writeln('（为帮助你理解用户的情绪上下文，以下是部分代表性记录）');
    buffer.writeln();

    // 选择代表性记录：最高分、最低分、和几条中间的
    final sortedByScore = List<MoodFragment>.from(fragments)
      ..sort((a, b) => b.emotionScore.compareTo(a.emotionScore));

    final representative = <MoodFragment>[];
    if (sortedByScore.isNotEmpty) {
      representative.add(sortedByScore.first); // 最高分
      if (sortedByScore.length > 1) {
        representative.add(sortedByScore.last); // 最低分
      }
      if (sortedByScore.length > 4) {
        // 添加几条中间值
        final mid = sortedByScore.length ~/ 2;
        representative.add(sortedByScore[mid]);
        if (sortedByScore.length > 8) {
          representative.add(sortedByScore[mid ~/ 2]);
          representative.add(sortedByScore[mid + (sortedByScore.length - mid) ~/ 2]);
        }
      }
    }

    // 按时间排序展示
    representative.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < representative.length; i++) {
      final fragment = representative[i];
      final date = '${fragment.timestamp.month}/${fragment.timestamp.day}';
      final mood = fragment.mood.displayName;
      final score = fragment.emotionScore;

      buffer.writeln('【记录${i + 1}】$date - $mood情绪 ($score分)');

      // 添加文本内容
      if (fragment.textContent != null && fragment.textContent!.isNotEmpty) {
        final content = fragment.displayContent.trim();
        final truncated = content.length > 100
            ? '${content.substring(0, 100)}...'
            : content;
        buffer.writeln('内容: "$truncated"');
      }

      // 添加标签
      if (fragment.hasTopicTags) {
        buffer.writeln('标签: ${fragment.topicTags.map((t) => '#$t').join(' ')}');
      }

      buffer.writeln();
    }

    // 添加分析提示
    buffer.writeln('**分析提示**');
    if (stats.totalEntries < 5) {
      buffer.writeln('- 记录数量较少，请做谨慎推断');
    }
    if (stats.averageScore < 40) {
      buffer.writeln('- 情绪整体偏低落，需要更多理解和支持性语言');
    }
    if (stats.emotionVolatility > 30) {
      buffer.writeln('- 情绪波动较大，需要关注稳定性问题');
    }
    if (stats.moodDistribution[MoodType.negative] != null &&
        stats.moodDistribution[MoodType.negative]! > stats.totalEntries * 0.7) {
      buffer.writeln('- 负面情绪占比较高，需要温和地识别模式');
    }

    return buffer.toString();
  }

  /// 解析LLM返回的JSON响应
  static Map<String, String>? parseResponse(String response) {
    try {
      // 移除可能的markdown代码块标记
      String cleaned = response.trim();

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
      if (json.containsKey('core_insight') &&
          json.containsKey('emotion_pattern') &&
          json.containsKey('behavior_suggestion')) {
        return {
          'core_insight': (json['core_insight'] as String).trim(),
          'emotion_pattern': (json['emotion_pattern'] as String).trim(),
          'behavior_suggestion': (json['behavior_suggestion'] as String).trim(),
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 验证生成的内容质量
  static bool validateContent(Map<String, String> content) {
    // 检查必需字段
    if (!content.containsKey('core_insight') ||
        !content.containsKey('emotion_pattern') ||
        !content.containsKey('behavior_suggestion')) {
      return false;
    }

    // 检查内容不为空
    if (content['core_insight']!.trim().isEmpty ||
        content['emotion_pattern']!.trim().isEmpty ||
        content['behavior_suggestion']!.trim().isEmpty) {
      return false;
    }

    // 检查字数范围（更宽松的限制，允许详细内容）
    final coreLength = content['core_insight']!.length;
    final patternLength = content['emotion_pattern']!.length;
    final suggestionLength = content['behavior_suggestion']!.length;

    // core_insight: 建议200-400字，允许150-700字
    if (coreLength < 150 || coreLength > 700) return false;

    // emotion_pattern: 建议400-800字，允许300-1500字
    if (patternLength < 300 || patternLength > 1500) return false;

    // behavior_suggestion: 建议300-600字，允许200-1200字
    if (suggestionLength < 200 || suggestionLength > 1200) return false;

    return true;
  }

  /// 生成默认内容（当记录数据不足或LLM调用失败时）
  static Map<String, String> getDefaultContent(ReportType type) {
    return {
      'core_insight':
          '这${type == ReportType.weekly ? '周' : '个月'}的记录还不够充分，暂时无法生成详细的洞察报告。但只要你开始记录，就是自我觉察的开始。继续保持记录，让数据积累起来，我们就能看到更多有意义的情绪模式。',
      'emotion_pattern':
          '由于记录数量有限，目前还难以识别出明显的情绪模式。情绪是复杂而多变的，需要更多的观察样本才能发现规律。建议你在接下来的时间里，尽量在不同的情绪状态下都进行记录——不仅仅是情绪低落时，也包括平静或愉悦的时刻。这样我们就能看到更完整的情绪图景。',
      'behavior_suggestion':
          '现阶段最重要的建议是：持续记录。尝试每天至少记录一次心情，可以是早晨醒来时、午休时或者晚上睡前。记录时不必纠结文字是否完美，简单记下当下的感受即可。随着记录的积累，你会逐渐发现一些有趣的模式，也能更好地了解自己的情绪规律。',
    };
  }
}
