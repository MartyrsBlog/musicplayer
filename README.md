# 音乐播放器

一个使用 Flutter 开发的本地音乐播放器应用，支持多种音频格式播放和歌词同步显示。

## 功能特性

- 支持扫描本地音乐文件（mp3、flac、aac、wav、ogg）
- 使用 just_audio 实现音频播放
- 歌词同步显示
- 主界面（音乐列表）、播放界面、设置界面
- 使用 provider 管理播放状态
- Apple Music 风格的简约 UI 设计
- 夜间模式切换

## 项目结构

```
lib/
├── main.dart                 # 应用入口文件
├── models/
│   └── song.dart             # 音乐文件数据模型
├── providers/
│   └── player_provider.dart  # 播放状态管理
├── screens/
│   ├── main_screen.dart      # 主界面（包含音乐库和设置）
│   ├── player_screen.dart    # 播放界面
│   └── settings_screen.dart  # 设置界面
├── services/
│   └── audio_manager.dart    # 音频管理服务
└── utils/                    # 工具类目录
```

## 依赖包

- `just_audio`: 音频播放
- `flutter_lyric`: 歌词显示
- `provider`: 状态管理
- `permission_handler`: 权限处理
- `path_provider`: 路径访问
- `file_picker`: 文件选择

## 运行项目

1. 确保已安装 Flutter SDK
2. 克隆项目到本地
3. 运行 `flutter pub get` 安装依赖
4. 运行 `flutter run` 启动应用

## 注意事项

- 应用需要存储权限来扫描本地音乐文件
- 歌词功能需要 `.lrc` 格式的歌词文件与音频文件同名
- 支持 Android、iOS、Web 等多平台部署