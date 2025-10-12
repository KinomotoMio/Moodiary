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
Create an impressionist painting in Vincent van Gogh's style, featuring swirling brushstrokes and vibrant colors.
The artwork should express the emotional journey described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Bold, expressive brushstrokes with visible texture
- Rich, vibrant colors (blues, yellows, oranges)
- Swirling, dynamic patterns suggesting movement
- Starry night aesthetic with emotional depth
- Post-impressionist technique

The painting should capture the essence of the emotions rather than literal representation.
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
Create an impressionist painting in Claude Monet's style, with soft, dreamy brushwork and gentle color transitions.
The artwork should reflect the emotional atmosphere described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Soft, feathery brushstrokes creating atmospheric effects
- Gentle pastel colors with subtle gradations
- Water lilies, reflections, and natural elements
- Peaceful, contemplative mood
- Light and shadow interplay
- Impressionist technique focusing on fleeting moments

The painting should evoke a sense of tranquility and emotional reflection.
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
Create a cubist painting in Pablo Picasso's style, with geometric shapes and multiple perspectives.
The artwork should represent the emotional complexity described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Geometric shapes and angular forms
- Multiple viewpoints shown simultaneously
- Abstract representation of emotions
- Bold, contrasting colors
- Fragmented and reconstructed reality
- Cubist technique

The painting should express emotional complexity through geometric abstraction.
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
Create an artwork in Hayao Miyazaki's Studio Ghibli animation style, with dreamy landscapes and warm atmosphere.
The artwork should capture the emotional journey described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Soft watercolor-like colors
- Dreamy, fantastical landscapes
- Warm, comforting atmosphere
- Nature elements (clouds, grass, trees)
- Gentle lighting and peaceful scenes
- Studio Ghibli aesthetic

The artwork should evoke feelings of warmth, healing, and wonder.
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
Create an abstract painting in Wassily Kandinsky's style, with musical rhythm expressed through colors and shapes.
The artwork should translate the emotional rhythm described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Abstract geometric and organic shapes
- Vibrant, contrasting colors
- Musical rhythm and movement
- Circles, lines, and triangles
- Synesthesia between sound and color
- Non-representational emotional expression

The painting should feel like visual music, expressing emotions through pure abstraction.
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
Create an artwork in David Hockney's style, with bold colors and simplified forms capturing everyday beauty.
The artwork should celebrate the moments described below:

{emotion_data}

Time period: {time_range}

Style characteristics:
- Bold, flat areas of bright color
- Simplified forms and clear outlines
- California sunshine aesthetic
- Pool water blues and vibrant greens
- Contemporary pop art influence
- Optimistic, celebratory mood

The artwork should radiate warmth and capture the beauty of everyday moments.
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

  /// 根据情绪类型推荐风格
  static ArtStyle recommendByMood(String moodType) {
    switch (moodType.toLowerCase()) {
      case 'positive':
        return hockney; // 阳光回忆 - 适合积极情绪
      case 'negative':
        return vanGogh; // 星空印象 - 适合复杂情绪
      case 'neutral':
        return monet; // 睡莲之梦 - 适合平静情绪
      default:
        return miyazaki; // 治愈之境 - 通用温暖
    }
  }
}
