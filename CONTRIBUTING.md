# 贡献指南

欢迎为Moodiary贡献代码！我们欣赏每一个贡献者的努力。

## 🌟 参与方式

### 报告问题
- 使用[Bug报告模板](https://github.com/KinomotoMio/Moodiary/issues/new?template=bug_report.yml)报告bug
- 使用[功能请求模板](https://github.com/KinomotoMio/Moodiary/issues/new?template=feature_request.yml)建议新功能
- 使用[问题咨询模板](https://github.com/KinomotoMio/Moodiary/issues/new?template=question.yml)寻求帮助

### 贡献代码
1. Fork本仓库
2. 创建feature分支 (`git checkout -b feature/amazing-feature`)
3. 提交变更 (`git commit -m 'feat: add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 🛠️ 开发环境设置

### 前置要求
- Flutter SDK (>=3.9.0)
- Dart SDK
- Android Studio / VS Code
- Git

### 设置步骤
```bash
# 克隆仓库
git clone https://github.com/KinomotoMio/Moodiary.git
cd Moodiary

# 获取依赖
flutter pub get

# 运行应用 (开发模式)
flutter run

# 代码分析
flutter analyze

# 运行测试
flutter test
```

### 平台特定设置

#### Android开发
- Android Studio 2024.1+
- Android SDK API 21+
- 配置Android虚拟设备或连接物理设备

#### iOS开发 (macOS only)
- Xcode 15.0+
- iOS Simulator或物理iOS设备
- Apple Developer账号 (用于真机测试)

#### Web开发
```bash
flutter run -d chrome
```

#### 桌面开发
```bash
# Windows
flutter run -d windows

# macOS  
flutter run -d macos

# Linux
flutter run -d linux
```

## 📝 代码规范

### Commit消息规范
采用[约定式提交](https://www.conventionalcommits.org/zh-hans/)规范：

```
类型(范围): 简短描述

- 具体改动点1
- 具体改动点2
```

#### 类型说明
- `feat`: 新功能
- `fix`: 错误修复  
- `refactor`: 重构
- `test`: 测试相关
- `docs`: 文档更新
- `style`: 代码格式
- `perf`: 性能优化
- `build`: 构建系统
- `ci`: CI配置

#### 范围示例
- `(ui)`: 界面相关
- `(analytics)`: 分析功能
- `(storage)`: 存储相关
- `(mood-entry)`: 心情记录功能

### 代码风格
- 使用 `flutter_lints` 规则
- 遵循Dart官方风格指南
- 类名：PascalCase (`MoodEntry`)
- 文件名：snake_case (`mood_entry.dart`)
- 变量和方法：camelCase (`analyzeEmotion`)
- 常量：SCREAMING_SNAKE_CASE (`API_BASE_URL`)

### 文件结构
```
lib/
├── screens/          # 页面组件
├── widgets/          # 可复用组件
├── services/         # 业务逻辑层
├── models/           # 数据模型
├── utils/            # 工具类
└── constants/        # 常量定义
```

## 🧪 测试

### 测试类型
- **单元测试**: 测试独立的函数和类
- **组件测试**: 测试UI组件
- **集成测试**: 测试完整功能流程

### 运行测试
```bash
# 所有测试
flutter test

# 指定测试文件
flutter test test/widget_test.dart

# 集成测试
flutter drive --target=test_driver/app.dart
```

### 测试要求
- 新功能必须包含相应测试
- Bug修复应包含回归测试
- 测试覆盖率目标：>80%

## 🎨 设计原则

### UI/UX指导
- 遵循Material Design 3规范
- 支持亮色/暗色主题
- 确保无障碍访问性
- 响应式设计，适配不同屏幕尺寸

### 性能要求
- 应用启动时间 <3秒
- 页面切换流畅 (60fps)
- 内存使用合理
- 网络请求优化

## 🔒 安全考虑

- 永远不要提交敏感信息 (API密钥、密码等)
- 用户数据本地加密存储
- API通信使用HTTPS
- 遵循最小权限原则

## 📋 Pull Request流程

### 提交前检查
- [ ] 代码遵循项目规范
- [ ] `flutter analyze` 无错误
- [ ] 相关测试通过
- [ ] 在目标平台测试功能
- [ ] 更新相关文档

### Review流程
1. 自动化检查 (CI)
2. 代码review
3. 功能测试
4. 合并到主分支

### Review标准
- 代码质量和可维护性
- 功能正确性和完整性
- 性能影响评估
- 安全性检查
- 文档完整性

## 🤝 社区行为准则

### 我们的承诺
为了营造一个开放和友好的环境，我们承诺：
- 尊重所有贡献者
- 欢迎不同观点和经验
- 接受建设性批评
- 关注社区最佳利益

### 不当行为
以下行为被视为不当行为：
- 使用性化语言或图像
- 人身攻击或侮辱
- 骚扰行为
- 发布他人私人信息
- 其他不专业行为

### 报告渠道
如果遇到不当行为，请通过以下方式报告：
- 创建private issue
- 直接联系维护者

## 💡 开发建议

### 开发最佳实践
- 保持函数简短和单一职责
- 使用有意义的变量名
- 添加适当的注释和文档
- 处理错误情况和边界条件
- 考虑国际化和本地化

### 调试技巧
```bash
# 启用调试模式
flutter run --debug

# 性能分析
flutter run --profile

# 查看日志
flutter logs
```

### 常见问题
- **构建失败**: 尝试 `flutter clean && flutter pub get`
- **热重载不工作**: 重启应用或IDE
- **依赖冲突**: 检查 `pubspec.yaml` 版本约束

## 📚 学习资源

### Flutter学习
- [Flutter官方文档](https://flutter.dev/docs)
- [Dart语言指南](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)

### 项目相关
- 查看 `CLAUDE.md` 了解项目架构
- 阅读现有代码了解实现模式
- 参与issue讨论了解需求

## 🎉 致谢

感谢所有贡献者让Moodiary变得更好！

### 贡献者类型
- 🐛 Bug报告者
- 💡 功能建议者  
- 💻 代码贡献者
- 📖 文档贡献者
- 🎨 设计贡献者
- 🧪 测试贡献者
- 🌍 翻译贡献者

---

**有疑问？** 随时创建[问题咨询](https://github.com/KinomotoMio/Moodiary/issues/new?template=question.yml)或参与[Discussions](https://github.com/KinomotoMio/Moodiary/discussions)！