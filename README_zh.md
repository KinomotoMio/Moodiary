# Moodiary

中文文档 | [English](README.md)

<div align="center">

**温暖治愈的AI心情日记**

*以隐私为先，结合AI洞察与暖心陪伴，记录、理解并调节每日心情*

![版本](https://img.shields.io/badge/版本-1.0.0--beta.1-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-02569B.svg?logo=flutter)
![开源](https://img.shields.io/badge/许可证-开源-green.svg)
![平台](https://img.shields.io/badge/平台-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)

</div>

---

## 📖 关于

**Moodiary** 是一款跨平台的心情日记应用，将AI洞察力与温暖治愈的用户体验相结合。基于Flutter开发，强调隐私保护，所有数据本地存储，同时提供可选的AI驱动情绪分析功能。

### ✨ 核心亮点

- 🔒 **隐私优先**: 所有数据加密存储在本地设备
- 🤖 **AI增强**: 可选的智能情绪分析和洞察
- 🎨 **精美设计**: Material Design 3，温暖治愈的配色方案
- 📊 **丰富分析**: 可视化呈现情绪模式和趋势
- 🌍 **跨平台**: 支持 Android、iOS、Web、Windows、macOS 和 Linux
- 💝 **开源项目**: 社区驱动的开发模式

---

## 🚀 功能特性

### 📝 心情记录
- **快速碎片**: 用简短文字快速捕捉心情片段
- **详细记录**: 添加丰富的心情记录，包括分数、标签和详细笔记
- **对话模式**: 自然对话式的心情记录体验
- **语音输入**: 语音转文字，支持免提记录
- **图片支持**: 为心情记录附加照片

### 🧠 AI驱动洞察
- **情绪分析**: AI驱动的心情模式识别
- **每日总结**: 自动生成每日心情回顾
- **洞察报告**: 深度分析情绪趋势（7天、30天、90天）
- **个性化建议**: 根据你的情绪提供定制化的调节建议
- **智能对话**: AI陪伴进行反思性对话

### 📊 分析与可视化
- **心情图表**: 优美的情绪旅程可视化呈现
- **连续记录**: 跟踪你的记录习惯和连续天数
- **话题标签**: 按主题和话题组织记录
- **历史时间线**: 一目了然地回顾情绪历史
- **统计仪表板**: 全面的心情数据指标

### 🎨 个性化定制
- **主题支持**: 亮色和暗色模式，温暖色调
- **艺术风格**: 多种艺术印象风格可选
- **睡前阅读**: 基于心情的精选放松内容

### 🔐 隐私与安全
- **本地存储**: 所有数据加密存储在设备上
- **可选AI**: 自主选择是否启用AI功能
- **无需注册**: 无需账号即可使用
- **开源透明**: 代码公开，可审计

---

## 🛠️ 技术栈

- **开发框架**: Flutter 3.9.0+
- **编程语言**: Dart
- **状态管理**: Provider & Event Bus
- **本地存储**: SharedPreferences
- **图表可视化**: FL Chart
- **AI集成**: 
  - SiliconFlow (DeepSeek-V3、Kimi K2、GLM-4.6)
  - DeepSeek API
- **图像生成**: Qwen-Image (通过 SiliconFlow)

---

## 📦 安装指南

### 环境要求
- Flutter SDK (≥3.9.0)
- Dart SDK
- Android Studio / Xcode / VS Code
- Git

### 安装步骤

1. **克隆仓库**
   ```bash
   git clone https://github.com/KinomotoMio/Moodiary.git
   cd Moodiary
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   # 移动端/桌面端
   flutter run
   
   # Web端
   flutter run -d chrome
   
   # 指定平台
   flutter run -d windows  # Windows
   flutter run -d macos    # macOS
   flutter run -d linux    # Linux
   ```

4. **构建发布版本**
   ```bash
   # Android APK
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   
   # Web
   flutter build web --release
   
   # 桌面
   flutter build windows --release
   flutter build macos --release
   flutter build linux --release
   ```

---

## 🎯 使用说明

### 快速开始

1. **创建第一条记录**
   - 点击主屏幕的"+"按钮
   - 选择快速碎片或详细心情记录
   - 添加想法、选择心情分数和可选标签

2. **启用AI功能（可选）**
   - 进入设置 > AI配置
   - 选择AI服务商（SiliconFlow 或 DeepSeek）
   - 输入API密钥
   - 测试连接
   - 开始使用AI洞察功能！

3. **查看分析**
   - 导航到分析标签页
   - 探索心情趋势、模式和统计数据
   - 生成AI驱动的洞察报告

4. **浏览历史**
   - 浏览心情时间线
   - 按标签或日期搜索
   - 查看详细的心情统计

### AI配置说明

Moodiary 支持多个AI服务商：

- **SiliconFlow**: DeepSeek-V3（推荐）、Kimi K2、GLM-4.6
- **DeepSeek**: 直接访问 DeepSeek 模型

所有AI分析按需进行，需要您提供所选服务商的API密钥。

---

## 🤝 参与贡献

我们欢迎社区贡献！在提交Pull Request之前，请阅读我们的[贡献指南](CONTRIBUTING.md)和[行为准则](CODE_OF_CONDUCT.md)。

### 贡献方式

- 🐛 使用[Bug报告模板](https://github.com/KinomotoMio/Moodiary/issues/new?template=bug_report.yml)报告问题
- 💡 使用[功能请求模板](https://github.com/KinomotoMio/Moodiary/issues/new?template=feature_request.yml)建议新功能
- 📖 改进文档
- 🌍 添加翻译
- 💻 提交代码改进
- 🎨 设计增强

---

## 📄 许可证

本项目为开源项目。请查看仓库了解许可证详情。

---

## 🙏 致谢

- 使用 [Flutter](https://flutter.dev/) 构建
- UI设计灵感来自 [Material Design 3](https://m3.material.io/)
- AI服务由 SiliconFlow 和 DeepSeek 提供
- 图标来自 Material Icons

---

## 📞 联系与支持

- **问题反馈**: [GitHub Issues](https://github.com/KinomotoMio/Moodiary/issues)
- **讨论交流**: [GitHub Discussions](https://github.com/KinomotoMio/Moodiary/discussions)
- **项目仓库**: [https://github.com/KinomotoMio/Moodiary](https://github.com/KinomotoMio/Moodiary)

---

## 📊 项目状态

**当前版本**: v1.0.0-beta.1 · 静海 (Tranquillity)  
**阶段**: Phase 3 - AI增强版

### 开发路线图

- [x] 核心心情记录功能
- [x] AI驱动的情绪分析
- [x] 跨平台支持
- [x] 数据可视化和分析
- [ ] 多语言支持（i18n）
- [ ] 云端备份（可选）
- [ ] 移动端小组件
- [ ] 高级导出功能

---

<div align="center">

**用 ❤️ 由 Moodiary 社区打造**

*关爱你的情绪健康，从每一次记录开始。*

</div>
