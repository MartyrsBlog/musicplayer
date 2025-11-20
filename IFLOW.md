# 音乐播放器项目文档

## 项目概述

这是一个使用 Flutter 开发的跨平台音乐播放器应用，支持本地音乐播放、在线音乐搜索下载和歌词同步显示。项目采用 Material Design 3 设计规范，提供 Apple Music 风格的简约优雅界面和流畅的音乐播放体验。

## 核心功能

### 🎵 音乐播放功能
- 支持多种音频格式：MP3、FLAC、AAC、WAV、OGG
- 基于高性能的 `just_audio` 引擎实现音频播放
- 完整的播放控制：播放/暂停、上一首/下一首、进度拖拽
- 实时播放进度显示和时间信息
- 播放列表管理和队列功能
- 跨平台音频支持（Linux平台使用 `just_audio_media_kit`）

### 🌐 在线音乐下载
- 音乐搜索功能：通过关键词搜索歌手或歌曲
- 多种下载选项：仅下载歌曲、仅下载歌词、同时下载歌曲和歌词
- 自动文件管理：智能创建下载目录，避免重复下载
- 跨平台存储支持：Android、iOS、Linux、Windows、macOS
- 下载历史管理和已下载音乐列表
- 主备网址自动切换机制

### 📝 歌词显示系统
- 支持内置歌词标签读取（使用 metadata_god）
- 支持外置 .lrc 歌词文件自动匹配
- 使用 `flutter_lyric` 实现歌词同步高亮显示
- 智能歌词加载策略：优先内置歌词，其次外置文件
- 歌词嵌入音频文件功能
- **歌词高亮颜色：黑色**（适配亮色主题）

### 🗂️ 音乐库管理
- 自动扫描本地音乐文件
- 支持多种存储权限处理（Android 各版本适配）
- 跨平台音乐目录访问（Android、iOS、Linux、Windows、macOS）
- 音乐元数据提取：标题、艺术家、专辑、封面、时长
- 音乐标签查看和编辑功能

### 🎨 用户界面
- Apple Music 风格的简约设计
- Material Design 3 规范
- **亮色主题**（默认配色：天蓝色主色调，白色背景）
- 响应式布局适配不同屏幕尺寸
- 多个专门界面：主界面、音乐库、播放界面、下载界面、播放列表等
- **底部导航栏当前页面文字高亮为黑色**

### 🔧 平台支持
- **Android**: 完整支持，包括存储权限适配
- **iOS**: 完整支持，支持通过 GitHub Actions 自动构建 IPA
- **Linux**: 使用 `just_audio_media_kit` 提供音频支持
- **Windows**: 完整支持
- **macOS**: 完整支持
- **Web**: 基础支持

## 项目架构

### 目录结构
```
lib/
├── main.dart                     # 应用入口和主题配置
├── models/
│   └── song.dart                 # 音乐文件数据模型
├── providers/
│   └── player_provider.dart      # 播放状态管理
├── screens/
│   ├── main_screen.dart          # 主界面（底部导航）
│   ├── music_library_screen.dart # 音乐库界面
│   ├── music_screen.dart         # 播放界面
│   ├── profile_screen.dart       # 个人资料界面（重新设计）
│   ├── settings_screen.dart      # 设置界面
│   ├── download_screen.dart      # 音乐下载界面
│   ├── download_list_screen.dart # 下载列表界面
│   ├── playlist_screen.dart      # 播放列表界面
│   └── music_tags_screen.dart    # 音乐标签界面
├── services/
│   ├── audio_manager.dart        # 音频管理和文件扫描
│   ├── lyrics_service.dart       # 歌词处理服务
│   └── music_download_service.dart # 音乐下载服务
└── utils/
    └── file_format_fixer.dart    # 文件格式修复工具

.github/workflows/
└── ios-build.yml                 # iOS 自动构建工作流
```

### 技术栈

#### 核心框架
- **Flutter**: ^3.9.2 - 跨平台UI框架
- **Dart**: ^3.9.2 - 编程语言

#### 状态管理
- **provider**: ^6.1.2 - 全局状态管理
- **ChangeNotifier** - 响应式状态更新

#### 音频处理
- **just_audio**: ^0.9.36 - 高性能音频播放引擎
- **just_audio_media_kit**: ^2.1.0 - 桌面平台音频支持
- **media_kit_libs_linux**: any - Linux 平台音频库

#### 歌词显示
- **flutter_lyric**: ^2.0.4 - 歌词同步显示组件

#### 权限与文件
- **permission_handler**: ^11.3.1 - 跨平台权限管理
- **path_provider**: ^2.1.3 - 系统路径访问
- **file_picker**: ^8.0.3 - 文件选择器

#### 元数据处理
- **metadata_god**: ^1.1.0 - 音频文件元数据读取和写入

#### 数据存储
- **shared_preferences**: ^2.3.2 - 本地配置存储

#### 网络与解析
- **http**: ^1.2.1 - HTTP 请求处理
- **html**: ^0.15.4 - HTML 解析
- **path**: ^1.9.0 - 路径操作
- **mime**: ^1.0.4 - MIME 类型检测

#### 开发工具
- **flutter_lints**: ^5.0.0 - 代码质量检查
- **flutter_launcher_icons**: ^0.13.1 - 应用图标生成
- **cupertino_icons**: ^1.0.8 - iOS 风格图标

## 开发指南

### 环境要求
- Flutter SDK 3.9.2 或更高版本
- Dart SDK 3.9.2 或更高版本
- Android SDK 21 或更高版本（Android 开发）
- Xcode 14 或更高版本（iOS 开发）

### 快速开始

1. **克隆项目**
   ```bash
   git clone https://github.com/MartyrsBlog/musicplayer.git
   cd musicplayer
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   # 调试模式
   flutter run
   
   # 发布模式
   flutter run --release
   ```

4. **构建应用**
   ```bash
   # Android APK
   flutter build apk --release
   
   # Android App Bundle
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   
   # Web
   flutter build web --release
   ```

### 开发命令

```bash
# 代码分析
flutter analyze

# 运行测试
flutter test

# 格式化代码
dart format .

# 生成应用图标
flutter pub run flutter_launcher_icons:main

# 修复音频文件格式
dart run fix_audio_formats.dart

# 清理构建缓存
flutter clean

# 获取依赖
flutter pub get
```

## iOS 自动构建

### GitHub Actions 工作流
项目包含完整的 iOS IPA 自动构建工作流，支持无 Mac 环境下构建 iOS 应用包。

#### 工作流特性
- **自动环境配置**: 使用 macOS runner 自动配置 Flutter 和 iOS 环境
- **智能项目结构**: 自动处理 iOS 项目文件和依赖
- **CocoaPods 集成**: 自动安装和配置 iOS 依赖
- **IPA 打包**: 自动生成可安装的 iOS 应用包
- **工件上传**: 自动上传构建产物，支持下载

#### 使用方法
1. 推送代码到 GitHub 仓库
2. 在 GitHub Actions 页面手动触发 "Build iOS IPA" 工作流
3. 等待构建完成（约 5-10 分钟）
4. 下载生成的 IPA 文件

#### 工作流文件位置
- 配置文件：`.github/workflows/ios-build.yml`
- 支持的 Flutter 版本：3.35.7（稳定版）

## 界面更新

### 主题变更
项目已从深色主题切换到亮色主题：

#### 主要颜色配置
```dart
colorScheme: const ColorScheme.light(
  primary: Color(0xFF60A5FA),      // 天蓝色主色调
  secondary: Color(0xFF93C5FD),    // 浅蓝色辅助色
  surface: Color(0xFFFFFFFF),      // 背景色
  background: Color(0xFFFFFFFF),   // 白色背景色
  onPrimary: Colors.white,          // 主色调上的文字
  onSecondary: Color(0xFF1F2937),  // 辅助色上的文字
  onSurface: Color(0xFF1F2937),    // 表面文字（深灰色）
  onBackground: Color(0xFF1F2937), // 背景文字（深灰色）
)
```

### 个人资料界面重新设计
- **上半部分**: 用户头像、姓名、个人短语展示
- **下半部分**: 圆角长方形控件，包含歌单和下载标签
- **布局比例**: 上下部分 1:1 比例
- **视觉风格**: 亮色主题，渐变背景，圆角设计

### 底部导航栏更新
- **当前页面高亮**: 文字颜色变为黑色 (`Color(0xFF1F2937)`)
- **非当前页面**: 灰色文字 (`Color(0xFF9CA3AF)`)
- **图标移除**: 移除了音乐库图标，仅保留文字

### 歌词显示优化
- **高亮颜色**: 黑色 (`Color(0xFF1F2937)`)，适配亮色主题
- **同步显示**: 使用 flutter_lyric 实现精准的歌词同步

## 核心组件详解

### PlayerProvider
- **职责**: 全局播放状态管理
- **功能**: 播放控制、播放列表管理、主题切换
- **位置**: `lib/providers/player_provider.dart`

### AudioManager
- **职责**: 音频文件扫描和元数据提取
- **功能**: 多平台音乐目录访问、权限处理、文件扫描
- **位置**: `lib/services/audio_manager.dart`

### LyricsService
- **职责**: 歌词加载和处理
- **功能**: 内置歌词读取、外置歌词文件匹配、歌词解析
- **位置**: `lib/services/lyrics_service.dart`

### MusicDownloadService
- **职责**: 在线音乐搜索和下载
- **功能**: 音乐搜索、文件下载、HTML解析、跨平台路径处理
- **位置**: `lib/services/music_download_service.dart`
- **特性**: 支持主备网址切换，动态URL构建，临时文件清理

### Song 模型
- **职责**: 音乐文件数据结构
- **属性**: ID、标题、艺术家、专辑、文件路径、时长、封面
- **位置**: `lib/models/song.dart`

### FileFormatFixer
- **职责**: 音频文件格式检测和修复
- **功能**: 自动检测文件实际格式、重命名错误扩展名
- **位置**: `lib/utils/file_format_fixer.dart`

### 文件格式修复工具
项目根目录包含独立的文件格式修复工具脚本：
- **位置**: `fix_audio_formats.dart`
- **功能**: 批量检测和修复音频文件扩展名错误
- **支持格式**: MP3、M4A、FLAC、WAV等
- **使用方式**: `dart run fix_audio_formats.dart`

## 界面组件

### 主界面 (MainScreen)
- 底部导航栏设计
- 集成音乐库、播放界面、下载等功能入口
- **更新**: 当前页面文字高亮为黑色

### 音乐库界面 (MusicLibraryScreen)
- 本地音乐文件展示
- 音乐分类和筛选功能
- 批量操作支持
- **更新**: 适配亮色主题

### 播放界面 (MusicScreen)
- 音乐播放控制
- 歌词同步显示（黑色高亮）
- 专辑封面展示
- 播放进度控制
- **新增**: 封面搜索和替换功能

### 下载界面 (DownloadScreen)
- 在线音乐搜索
- 下载选项选择
- 下载进度显示
- **更新**: 搜索框位置优化，按钮颜色协调

### 下载列表界面 (DownloadListScreen)
- 已下载音乐管理
- 文件操作功能

### 播放列表界面 (PlaylistScreen)
- 当前播放队列管理
- 歌曲顺序调整
- 队列清空功能

### 音乐标签界面 (MusicTagsScreen)
- 音频文件元数据显示
- 标签编辑功能
- 封面图片查看

### 设置界面 (SettingsScreen)
- 应用配置选项
- 主题设置
- 播放偏好设置
- **更新**: 移除黑色块，适配亮色主题

### 个人资料界面 (ProfileScreen)
- **完全重新设计**: 用户头像、姓名、短语展示
- 圆角长方形控件设计
- 歌单和下载标签整合
- **布局**: 上下 1:1 比例，头像位于上半部分中间

## 测试

项目包含完整的测试套件：

```
test/
├── widget_test.dart                    # 基础组件测试
├── music_screen_integration_test.dart  # 音乐界面集成测试
├── lyrics_service_test.dart            # 歌词服务测试
├── audio_tags_test.dart                # 音频标签测试
├── flac_lyrics_test.dart               # FLAC 歌词测试
├── album_lyrics_toggle_test.dart       # 专辑歌词切换测试
├── lyrics_screen_test.dart             # 歌词界面测试
└── download_service_test.dart          # 下载服务测试
```

### 运行测试
```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/lyrics_service_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

## 代码规范

项目遵循以下代码规范：

- **Dart/Flutter 官方规范**: 使用 `flutter_lints` 进行代码检查
- **命名约定**: 驼峰命名法（camelCase）
- **文件组织**: 按功能模块分层组织
- **注释规范**: 重要逻辑添加中文注释
- **代码格式**: 使用 `dart format` 自动格式化

## 权限配置

### Android 权限
在 `android/app/src/main/AndroidManifest.xml` 中添加：
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS 权限
在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSAppleMusicUsageDescription</key>
<string>此应用需要访问您的音乐库以播放本地音乐文件</string>
```

## 扩展建议

### 短期优化
1. **均衡器**: 添加音频均衡器功能
2. **睡眠定时器**: 添加播放定时关闭功能
3. **播放历史**: 记录最近播放的歌曲
4. **下载队列管理**: 实现批量下载和下载队列
5. **音乐分类**: 按艺术家、专辑、流派分类
6. **搜索功能**: 全文搜索音乐库

### 中期功能
1. **自定义播放列表**: 创建和管理用户自定义播放列表
2. **歌词编辑**: 内置歌词编辑器
3. **多音乐源支持**: 集成更多在线音乐源
4. **音乐推荐**: 基于播放历史的智能推荐
5. **云同步**: 播放列表和设置云同步
6. **社交功能**: 音乐分享和推荐

### 长期规划
1. **在线音乐流媒体**: 集成主流音乐流媒体服务
2. **AI 功能**: 智能音乐分类和推荐
3. **播客支持**: 添加播客播放功能
4. **音乐可视化**: 音频可视化效果
5. **多语言支持**: 国际化和本地化

## 故障排除

### 常见问题

1. **Android 权限问题**
   - 确保在 AndroidManifest.xml 中添加了必要的权限
   - Android 10+ 需要处理分区存储
   - Android 13+ 需要请求媒体权限

2. **音频文件无法播放**
   - 检查文件格式是否支持
   - 确认文件路径正确
   - 检查音频文件是否损坏
   - 使用文件格式修复工具处理格式错误

3. **歌词不显示**
   - 确认歌词文件格式为 .lrc
   - 检查歌词文件是否与音频文件同名
   - 验证歌词文件编码格式
   - 检查音频文件是否包含内置歌词

4. **桌面平台音频问题**
   - 确保安装了 `just_audio_media_kit`
   - Linux 平台需要安装 `media_kit_libs_linux`

5. **下载功能问题**
   - 确保网络连接正常
   - 检查存储权限是否已获取
   - 某些地区可能无法访问下载源
   - 检查网址配置是否正确

6. **文件格式问题**
   - 使用文件格式修复工具处理错误的文件扩展名
   - 检查下载文件的实际格式与扩展名是否匹配
   - 运行 `dart run fix_audio_formats.dart` 批量修复

7. **iOS 构建问题**
   - 确保 Flutter 版本兼容性（推荐 3.35.7）
   - 检查 GitHub Actions 工作流配置
   - 确认 iOS 项目文件结构正确
   - 验证 CocoaPods 依赖安装

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- 项目主页: https://github.com/MartyrsBlog/musicplayer
- 问题反馈: https://github.com/MartyrsBlog/musicplayer/issues

## 音乐下载功能详解

### 功能概述
音乐下载功能允许用户直接在应用内搜索和下载音乐文件及歌词，支持多种下载选项和智能文件管理。

### 主要特性
- **音乐搜索**: 通过关键词搜索音乐（歌手名或歌曲名）
- **下载选项**: 仅下载歌曲、仅下载歌词、同时下载歌曲和歌词
- **文件管理**: 自动创建下载目录，避免重复下载已存在文件
- **跨平台支持**: Android、iOS、Linux、Windows、macOS
- **主备网址**: 支持主网址和备用网址自动切换
- **封面图下载**: 自动下载并嵌入封面图片
- **歌词嵌入**: 支持将歌词嵌入音频文件
- **临时文件清理**: 自动清理过期的临时封面文件

### 网址配置
- **主网址**: `http://www.22a5.com`
- **备用网址**: `http://www.2t58.com`
- **歌词服务**: `https://js.eev3.com/lrc.php`
- **动态URL构建**: 播放URL自动构建为 `{baseUrl}/js/play.php`

### 使用方法
1. 打开应用，点击底部导航栏的"下载"标签
2. 在搜索框中输入歌手名或歌曲名
3. 点击"搜索"按钮
4. 从搜索结果中选择要下载的歌曲
5. 选择下载选项（歌曲/歌词/两者）
6. 等待下载完成

### 存储位置
- **Android**: `{外部存储}/Music/Downloads/`
- **iOS**: `{应用文档目录}/Downloads/`
- **桌面平台**: `{应用文档目录}/Downloads/`

## 文件格式修复工具

### 功能概述
文件格式修复工具可以自动检测音频文件的实际格式，并修复错误的文件扩展名。

### 主要特性
- 自动检测文件实际格式（基于文件头）
- 智能重命名错误扩展名
- 支持批量处理整个音乐目录
- 避免重复修复已正确命名的文件
- 支持格式：MP3、M4A、FLAC、WAV等

### 使用场景
- 下载的音频文件扩展名不正确
- 需要批量修复音乐库中的格式错误
- 确保播放器能正确识别所有音频文件

### 使用方法
```bash
# 运行格式修复工具
dart run fix_audio_formats.dart
```

## 项目初始化流程

### 启动流程
应用启动时会自动执行以下初始化步骤：
1. **音频引擎初始化**: `JustAudioMediaKit.ensureInitialized()` - 确保Linux平台音频支持
2. **元数据引擎初始化**: `MetadataGod.initialize()` - 初始化音频元数据读取功能
3. **临时文件清理**: `MusicDownloadService.cleanupOldTempCovers()` - 清理过期的临时封面文件

#---

*最后更新: 2025年11月20日*