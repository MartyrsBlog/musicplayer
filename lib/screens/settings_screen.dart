import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../services/audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  _scanMusic();
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
                    _pickMusicFolder();
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
                    _checkPermissions();
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
                  _showAboutDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 扫描音乐
  void _scanMusic() async {
    try {
      final audioManager = AudioManager();
      final songs = await audioManager.scanLocalMusic();
      
      if (mounted) {
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        playerProvider.setPlaylist(songs);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('音乐扫描完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描失败: $e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _scanMusic,
            ),
          ),
        );
      }
    }
  }

  // 选择音乐文件夹（仅用于桌面平台）
  void _pickMusicFolder() async {
    // 仅在桌面平台可用
    if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      return;
    }
    
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      
      if (result != null && mounted) {
        // 在实际应用中，这里会扫描选定的文件夹
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('文件夹选择功能将在完整版本中实现')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件夹失败: $e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _pickMusicFolder,
            ),
          ),
        );
      }
    }
  }

  // 检查权限（仅用于移动平台）
  void _checkPermissions() async {
    // 仅在移动平台可用
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }
    
    try {
      // 检查存储权限
      final status = await Permission.storage.status;
      
      if (mounted) {
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('存储权限已授予')),
          );
        } else {
          // 请求权限
          final requested = await Permission.storage.request();
          if (requested.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('存储权限已授予')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('存储权限被拒绝')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查权限时出错: $e')),
        );
      }
    }
  }

  // 显示关于对话框
  void _showAboutDialog() {
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