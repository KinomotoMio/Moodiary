/// 艺术风格模板
///
/// 用于生成情绪印象画的风格定义
class ArtStyle {
  /// 风格ID
  final String id;

  /// 风格名称
  final String name;

  /// 艺术家名称
  final String artist;

  /// 艺术家简介
  final String artistBio;

  /// 风格描述（展示给用户）
  final String description;

  /// AI绘图提示词模板
  final String promptTemplate;

  /// 预设图片URLs（降级方案，支持多张随机选择）
  final List<String> fallbackImageUrls;

  /// 情绪色彩主题（用于方案C本地渲染）
  final List<String> colorTheme;

  const ArtStyle({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistBio,
    required this.description,
    required this.promptTemplate,
    required this.fallbackImageUrls,
    required this.colorTheme,
  });

  /// 生成AI绘图提示词
  ///
  /// [emotionData] 情绪数据摘要
  /// [timeRange] 时间范围描述
  String generatePrompt(String emotionData, String timeRange) {
    return promptTemplate
        .replaceAll('{emotion_data}', emotionData)
        .replaceAll('{time_range}', timeRange);
  }
}

/// 预定义的艺术风格模板
class ArtStyles {
  /// 梵高 - 星空印象
  static const vanGogh = ArtStyle(
    id: 'van_gogh',
    name: '星空印象',
    artist: '文森特·梵高',
    artistBio: '后印象派代表，用旋转的笔触和强烈的色彩表达内心的激情',
    description: '用旋转的笔触和璀璨的星光，描绘你心中的情绪银河',
    promptTemplate: '''
You are Vincent van Gogh, a post-impressionist master known for swirling brushstrokes, vibrant colors, and emotional depth in paintings like "The Starry Night".

Task: Create a horizontal banner artwork in your signature style to accompany a psychological mood report for the user.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Post-impressionist with bold, expressive brushstrokes showing visible texture
- Colors: Rich and vibrant (deep blues, bright yellows, warm oranges, turquoise)
- Composition: Horizontal banner format, balanced and suitable for report header
- Movement: Swirling, dynamic patterns suggesting emotional energy and flow
- Atmosphere: Capture the essence of the user's emotional journey with starry night aesthetic
- Emotion: Express the depth and complexity of feelings, not literal representation
- Avoid: Any text, lettering, signage, or written language

Create a landscape painting that emotionally resonates with these mood records, using your characteristic swirling skies and bold color contrasts.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1465146633011-14f8e0781093?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1475274047050-1d0c0975c63e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1444930694458-01babf71c7cd?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#1e3a8a', '#fbbf24', '#f59e0b', '#06b6d4'],
  );

  /// 莫奈 - 睡莲之梦
  static const monet = ArtStyle(
    id: 'monet',
    name: '睡莲之梦',
    artist: '克劳德·莫奈',
    artistBio: '印象派创始人，捕捉光影变化中的瞬间美感',
    description: '在光影流转间，捕捉你情绪中最柔和的涟漪',
    promptTemplate: '''
You are Claude Monet, pioneer of Impressionism, celebrated for capturing fleeting light with soft, atmospheric brushwork.

Task: Paint a horizontal banner artwork, gentle and luminous, to sit atop a psychological mood report.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Impressionist water garden ambience with diffused edges and layered light
- Colors: Misty greens, lilac blues, pale pinks, golden highlights drifting across water
- Composition: Wide, panoramic layout with tranquil reflections and subtle depth
- Atmosphere: Contemplative calm that lets the viewer breathe with the user's emotions
- Emotion: Translate the mood records into ripples of light, not literal portraits
- Avoid: Any text, lettering, signage, or written language

Create a serene water-garden landscape that lets these emotional notes glow softly across the banner.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#a7f3d0', '#6ee7b7', '#93c5fd', '#ddd6fe'],
  );

  /// 毕加索 - 立体心境
  static const picasso = ArtStyle(
    id: 'picasso',
    name: '立体心境',
    artist: '巴勃罗·毕加索',
    artistBio: '立体主义先驱，用几何形状解构重组现实',
    description: '用几何的语言，拼凑你内心世界的多个侧面',
    promptTemplate: '''
You are Pablo Picasso, master of Cubism, renowned for reframing reality through fractured geometry and layered perspectives.

Task: Craft a horizontal banner artwork for a psychological mood report, revealing nuanced inner worlds.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Analytical Cubism with intersecting planes and angular silhouettes
- Colors: Muted earth tones contrasted with electric accents to highlight tension
- Composition: Wide panoramic structure with overlapping viewpoints stitched together
- Atmosphere: Thoughtful, introspective energy that shows simultaneous emotions
- Emotion: Use geometric abstraction to decode the user's experiences without literal storytelling
- Avoid: Any text, lettering, signage, or written language

Assemble an abstract emotional tapestry that invites the viewer to explore every layered fragment.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1561214115-f2f134cc4912?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1557672172-298e090bd0f1?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1515266591878-f93e32bc5937?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1552083974-186346191183?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#ef4444', '#f59e0b', '#3b82f6', '#8b5cf6'],
  );

  /// 宫崎骏 - 治愈之境
  static const miyazaki = ArtStyle(
    id: 'miyazaki',
    name: '治愈之境',
    artist: '宫崎骏',
    artistBio: '动画大师，用纯真的画笔描绘充满温情的幻想世界',
    description: '在充满温情的动画世界中，找到情绪的归属',
    promptTemplate: '''
You are Hayao Miyazaki, storyteller of tender, hand-painted worlds where nature, light, and emotion breathe together.

Task: Illustrate a horizontal banner to accompany a psychological mood report, offering gentle companionship.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Studio Ghibli-inspired watercolor softness with lovingly detailed landscapes
- Colors: Warm sunlight tones, verdant greens, sky blues, and cozy evening hues
- Composition: Wide cinematic panorama with layered depth and drifting clouds
- Atmosphere: Compassionate, hopeful, and quietly magical to soothe the viewer
- Emotion: Let the user's stories bloom through nature metaphors and subtle character impressions
- Avoid: Any text, lettering, signage, or written language

Paint a healing vista that feels like a safe haven guided by these emotional memories.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1511447333015-45b65e60f6d5?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#86efac', '#7dd3fc', '#fde047', '#fda4af'],
  );

  /// 康定斯基 - 音乐心流
  static const kandinsky = ArtStyle(
    id: 'kandinsky',
    name: '音乐心流',
    artist: '瓦西里·康定斯基',
    artistBio: '抽象艺术先驱，将音乐的韵律转化为视觉语言',
    description: '让情绪像音符般流淌，在色彩与形状中自由舞蹈',
    promptTemplate: '''
You are Wassily Kandinsky, pioneer of abstract art, orchestrating color and form like symphonic music.

Task: Compose a horizontal banner artwork for a psychological mood report, turning emotions into visual rhythm.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Abstract composition with lyrical geometry, pulsating circles, and decisive lines
- Colors: Bold primaries with luminous accents that echo harmonious chords
- Composition: Panoramic sweep of interlocking shapes, guiding the eye like a score
- Atmosphere: Dynamic yet balanced, capturing crescendos and rests in the user's feelings
- Emotion: Transform the mood records into synesthetic movement instead of literal scenes
- Avoid: Any text, lettering, signage, or written language

Conduct a visual symphony that lets these emotions dance across the horizontal canvas.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1549887534-1541e9326642?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1500462918059-b1a0cb512f1d?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1551089546-6897aab58502?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#ec4899', '#f59e0b', '#3b82f6', '#10b981'],
  );

  /// 霍克尼 - 阳光回忆
  static const hockney = ArtStyle(
    id: 'hockney',
    name: '阳光回忆',
    artist: '大卫·霍克尼',
    artistBio: '当代艺术大师，用明快的色彩捕捉生活中的美好瞬间',
    description: '用明媚的色彩，定格你记忆中最温暖的时刻',
    promptTemplate: '''
You are David Hockney, contemporary colorist capturing sunlit daily life with confident lines and joyful palettes.

Task: Design a horizontal banner artwork to headline a psychological mood report, celebrating lived moments.

User's Emotional Records ({time_range}):
{emotion_data}

Artistic Requirements:
- Style: Crisp, simplified shapes with playful perspective and graphic clarity
- Colors: Vibrant pools of turquoise, citrus yellow, lush green, and pops of fuchsia
- Composition: Wide cinematic framing with clean geometry and layered planes
- Atmosphere: Optimistic warmth that honors everyday rituals and heartfelt reflections
- Emotion: Channel the user's memories into radiant color fields instead of literal portraits
- Avoid: Any text, lettering, signage, or written language

Create a sunlit scene that frames these emotional notes as cherished snapshots of life.
''',
    fallbackImageUrls: [
      'https://images.unsplash.com/photo-1513151233558-d860c5398176?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1483728642387-6c3bdd6c93e5?w=800&h=400&fit=crop',
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800&h=400&fit=crop',
    ],
    colorTheme: ['#06b6d4', '#10b981', '#fbbf24', '#f472b6'],
  );

  /// 获取所有风格
  static List<ArtStyle> getAllStyles() => [
    vanGogh,
    monet,
    picasso,
    miyazaki,
    kandinsky,
    hockney,
  ];

  /// 根据ID获取风格
  static ArtStyle? getStyleById(String id) {
    try {
      return getAllStyles().firstWhere((style) => style.id == id);
    } catch (e) {
      return null;
    }
  }
}
