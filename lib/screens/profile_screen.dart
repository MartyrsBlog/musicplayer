import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'settings_screen.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '我的',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // 用户信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '用户',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              playerProvider.isDarkMode ? '夜间模式已开启' : '夜间模式已关闭',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 设置选项
              Card(
                child: ListTile(
                  title: const Text('设置'),
                  subtitle: const Text('主题、扫描音乐等设置'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 夜间模式切换
              Card(
                child: ListTile(
                  title: const Text('夜间模式'),
                  trailing: Switch(
                    value: playerProvider.isDarkMode,
                    onChanged: (value) {
                      playerProvider.toggleDarkMode();
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 扫描音乐
              Card(
                child: ListTile(
                  title: const Text('扫描音乐'),
                  subtitle: const Text('扫描本地音乐文件'),
                  trailing: const Icon(Icons.refresh),
                  onTap: () {
                    _scanMusic(context);
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // 添加音乐文件夹（仅在桌面平台显示）
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                Card(
                  child: ListTile(
                    title: const Text('添加音乐文件夹'),
                    subtitle: const Text('选择包含音乐的文件夹'),
                    trailing: const Icon(Icons.add),
                    onTap: () {
                      _pickMusicFolder(context);
                    },
                  ),
                ),
              
              if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                const SizedBox(height: 20),
              
              // 权限设置（仅在移动平台显示）
              if (Platform.isAndroid || Platform.isIOS)
                Card(
                  child: ListTile(
                    title: const Text('权限设置'),
                    subtitle: const Text('检查和管理应用权限'),
                    trailing: const Icon(Icons.security),
                    onTap: () {
                      _checkPermissions(context);
                    },
                  ),
                ),
              
              if (Platform.isAndroid || Platform.isIOS)
                const SizedBox(height: 20),
              
              // 关于
              Card(
                child: ListTile(
                  title: const Text('关于音乐播放器'),
                  subtitle: const Text('版本 1.0.0'),
                  trailing: const Icon(Icons.info),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 扫描音乐
  void _scanMusic(BuildContext context) {
    // 这里可以调用 AudioManager 来扫描音乐
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('音乐扫描功能将在完整版本中实现')),
    );
  }

  // 选择音乐文件夹（仅用于桌面平台）
  void _pickMusicFolder(BuildContext context) {
    // 仅在桌面平台可用
    if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件夹选择功能将在完整版本中实现')),
    );
  }

  // 检查权限（仅用于移动平台）
  void _checkPermissions(BuildContext context) {
    // 仅在移动平台可用
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('权限检查功能将在完整版本中实现')),
    );
  }

  // 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('关于音乐播放器'),
          content: const Text(
            '这是一个使用Flutter开发的本地音乐播放器。\n\n'
            '功能特点：\n'
            '• 支持多种音频格式\n'
            '• 简洁的用户界面\n'
            '• 夜间模式支持\n'
            '• 歌词同步显示\n\n'
            '版本：1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}