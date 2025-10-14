# Moodiary

[中文文档](README_zh.md) | English

<div align="center">

**A Privacy-First AI-Enhanced Mood Journal**

*Record, Understand, and Regulate Your Daily Emotions with Warmth and Care*

![Version](https://img.shields.io/badge/version-1.0.0--beta.1-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.9.0+-02569B.svg?logo=flutter)
![License](https://img.shields.io/badge/license-Open%20Source-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)

</div>

---

## 📖 About

**Moodiary** is a cross-platform mood journal application that combines the power of AI insights with a warm, healing user experience. Built with Flutter, it emphasizes privacy by storing all data locally while offering optional AI-powered emotional analysis through secure API calls.

### ✨ Key Highlights

- 🔒 **Privacy-First**: All data stored locally on your device
- 🤖 **AI-Enhanced**: Optional intelligent emotional analysis and insights
- 🎨 **Beautiful Design**: Material Design 3 with warm, healing color schemes
- 📊 **Rich Analytics**: Visualize your emotional patterns over time
- 🌍 **Cross-Platform**: Runs on Android, iOS, Web, Windows, macOS, and Linux
- 💝 **Open Source**: Community-driven development

---

## 🚀 Features

### 📝 Mood Recording
- **Quick Fragments**: Capture moments with simple text entries
- **Detailed Entries**: Add rich mood records with scores, tags, and notes
- **Conversational Mode**: Natural dialogue-style mood recording
- **Voice Input**: Speech-to-text support for hands-free recording
- **Image Support**: Attach photos to your mood entries

### 🧠 AI-Powered Insights
- **Emotional Analysis**: AI-driven mood pattern recognition
- **Daily Summaries**: Automated daily mood recaps
- **Insight Reports**: Deep analysis of your emotional trends (7-day, 30-day, 90-day)
- **Personalized Tips**: Tailored suggestions for emotional well-being
- **Smart Conversations**: AI companion for reflective dialogue

### 📊 Analytics & Visualization
- **Mood Charts**: Beautiful visualizations of your emotional journey
- **Streak Tracking**: Monitor your journaling consistency
- **Topic Tags**: Organize entries by themes and topics
- **Historical Timeline**: Review your emotional history at a glance
- **Statistics Dashboard**: Comprehensive mood metrics

### 🎨 Customization
- **Theme Support**: Light and dark modes with warm color palettes
- **Art Styles**: Choose from various artistic impression styles
- **Bedtime Reading**: Curated mood-based content for relaxation

### 🔐 Privacy & Security
- **Local Storage**: All data encrypted and stored on your device
- **Optional AI**: Choose when to enable AI features
- **No Account Required**: Use without registration
- **Open Source**: Transparent and auditable codebase

---

## 🛠️ Technology Stack

- **Framework**: Flutter 3.9.0+
- **Language**: Dart
- **State Management**: Provider & Event Bus
- **Local Storage**: SharedPreferences
- **Charts**: FL Chart
- **AI Integration**: 
  - SiliconFlow (DeepSeek-V3, Kimi K2, GLM-4.6)
  - DeepSeek API
- **Image Generation**: Qwen-Image via SiliconFlow

---

## 📦 Installation

### Prerequisites
- Flutter SDK (≥3.9.0)
- Dart SDK
- Android Studio / Xcode / VS Code
- Git

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/KinomotoMio/Moodiary.git
   cd Moodiary
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # For mobile/desktop
   flutter run
   
   # For web
   flutter run -d chrome
   
   # For specific platform
   flutter run -d windows  # Windows
   flutter run -d macos    # macOS
   flutter run -d linux    # Linux
   ```

4. **Build for production**
   ```bash
   # Android APK
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   
   # Web
   flutter build web --release
   
   # Desktop
   flutter build windows --release
   flutter build macos --release
   flutter build linux --release
   ```

---

## 🎯 Usage

### Getting Started

1. **Create Your First Entry**
   - Tap the "+" button on the home screen
   - Choose between quick fragment or detailed mood entry
   - Add your thoughts, select mood score, and optional tags

2. **Enable AI Features (Optional)**
   - Go to Settings > AI Configuration
   - Choose your preferred AI provider (SiliconFlow or DeepSeek)
   - Enter your API key
   - Test the connection
   - Start using AI-powered insights!

3. **View Analytics**
   - Navigate to the Analytics tab
   - Explore mood trends, patterns, and statistics
   - Generate AI-powered insight reports

4. **Explore History**
   - Browse your mood timeline
   - Search by tags or date
   - Review detailed mood statistics

### AI Configuration

Moodiary supports multiple AI providers:

- **SiliconFlow**: DeepSeek-V3 (recommended), Kimi K2, GLM-4.6
- **DeepSeek**: Direct API access to DeepSeek models

All AI analysis happens on-demand and requires an API key from your chosen provider.

---

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md) before submitting pull requests.

### Ways to Contribute

- 🐛 Report bugs using [Bug Report Template](https://github.com/KinomotoMio/Moodiary/issues/new?template=bug_report.yml)
- 💡 Suggest features using [Feature Request Template](https://github.com/KinomotoMio/Moodiary/issues/new?template=feature_request.yml)
- 📖 Improve documentation
- 🌍 Add translations
- 💻 Submit code improvements
- 🎨 Design enhancements

---

## 📄 License

This project is open source. Please check the repository for license details.

---

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- UI inspired by [Material Design 3](https://m3.material.io/)
- AI powered by SiliconFlow and DeepSeek
- Icons from Material Icons

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/KinomotoMio/Moodiary/issues)
- **Discussions**: [GitHub Discussions](https://github.com/KinomotoMio/Moodiary/discussions)
- **Repository**: [https://github.com/KinomotoMio/Moodiary](https://github.com/KinomotoMio/Moodiary)

---

## 📊 Project Status

**Current Version**: v1.0.0-beta.1 · Tranquillity (静海)  
**Phase**: Phase 3 - AI Enhancement

### Roadmap

- [x] Core mood journaling features
- [x] AI-powered emotional analysis
- [x] Cross-platform support
- [x] Data visualization and analytics
- [ ] Multi-language support (i18n)
- [ ] Cloud backup (optional)
- [ ] Mobile widgets
- [ ] Advanced export features

---

<div align="center">

**Made with ❤️ by the Moodiary Community**

*Take care of your emotional well-being, one entry at a time.*

</div>
