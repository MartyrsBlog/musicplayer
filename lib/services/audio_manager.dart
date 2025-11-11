import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class AudioManager {
  // 支持的音频格式
  static const List<String> supportedFormats = [
    '.mp3',
    '.flac',
    '.aac',
    '.wav',
    '.ogg',
  ];

  // 扫描本地音乐文件
  Future<List<Song>> scanLocalMusic() async {
    // 检查是否为移动端平台
    if (Platform.isAndroid || Platform.isIOS) {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // 如果常规存储权限被拒绝，尝试使用管理外部存储权限（Android 10+）
        if (Platform.isAndroid) {
          final manageExternalStorageStatus = await Permission.manageExternalStorage.request();
          if (!manageExternalStorageStatus.isGranted) {
            throw Exception('存储权限未授予');
          }
        } else {
          throw Exception('存储权限未授予');
        }
      }
    }
    // 对于桌面平台（Linux、Windows、macOS），不需要请求权限，直接扫描

    // 获取音乐目录
    final Directory? musicDir = await _getMusicDirectory();
    if (musicDir == null) {
      throw Exception('无法访问音乐目录');
    }

    // 扫描音乐文件
    final songs = await _scanDirectory(musicDir);
    return songs;
  }

  // 获取音乐目录
  Future<Directory?> _getMusicDirectory() async {
    try {
      // 对于 Android 平台，尝试获取外部存储目录
      if (Platform.isAndroid) {
        try {
          // 尝试获取外部存储目录
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            // 返回外部存储目录下的 Music 文件夹
            return Directory('${externalDir.parent.parent.path}/Music');
          }
        } catch (e) {
          // 如果无法获取外部存储目录，则使用文档目录
          final docDir = await getApplicationDocumentsDirectory();
          return Directory('${docDir.path}/Music');
        }
      }
      
      // 对于 iOS 平台，使用文档目录
      if (Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${docDir.path}/Music');
        return musicDir;
      }
      
      // 对于桌面平台（Linux、Windows、macOS），使用用户主目录下的音乐文件夹
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final homeDir = _getHomeDirectory();
        if (homeDir != null) {
          // 不同平台的音乐目录路径不同
          String musicPath;
          if (Platform.isLinux) {
            musicPath = '$homeDir/Music';  // Linux 通常使用 Music 目录
          } else if (Platform.isWindows) {
            musicPath = '$homeDir/Music';  // Windows 通常使用 Music 目录
          } else {
            musicPath = '$homeDir/Music';  // macOS 通常使用 Music 目录
          }
          return Directory(musicPath);
        }
      }
      
      // 默认使用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      return Directory('${docDir.path}/Music');
    } catch (e) {
      // 如果无法获取外部存储目录，则使用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      return Directory('${docDir.path}/Music');
    }
  }

  // 获取用户主目录（仅用于桌面平台）
  String? _getHomeDirectory() {
    // Linux 和 macOS 使用 HOME 环境变量
    if (Platform.isLinux || Platform.isMacOS) {
      return Platform.environment['HOME'];
    }
    
    // Windows 使用 USERPROFILE 环境变量
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'];
    }
    
    return null;
  }

  // 扫描目录中的音乐文件
  Future<List<Song>> _scanDirectory(Directory directory) async {
    final songs = <Song>[];
    
    try {
      // 检查目录是否存在
      if (!await directory.exists()) {
        // 如果目录不存在则创建
        await directory.create(recursive: true);
      }
      
      // 列出目录中的所有文件
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final file = entity;
          final fileName = file.uri.pathSegments.last;
          
          // 检查文件扩展名是否为支持的音频格式
          for (final format in supportedFormats) {
            if (fileName.toLowerCase().endsWith(format)) {
              // 创建歌曲对象（模拟数据）
              final song = Song(
                id: file.path.hashCode.toString(),
                title: _extractTitle(fileName),
                artist: '未知艺术家',
                album: '未知专辑',
                filePath: file.path,
                duration: const Duration(seconds: 210), // 模拟时长
              );
              songs.add(song);
              break;
            }
          }
        }
      }
    } catch (e) {
      // 处理扫描错误
      print('扫描音乐文件时出错: $e');
    }
    
    return songs;
  }

  // 从文件名提取标题
  String _extractTitle(String fileName) {
    // 移除文件扩展名
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex > 0) {
      fileName = fileName.substring(0, dotIndex);
    }
    
    // 将下划线和连字符替换为空格
    return fileName.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  // 释放资源
  void dispose() {
    // 这里可以添加清理代码
  }
}