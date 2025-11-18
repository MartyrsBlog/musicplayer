import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class AudioManager {
  // 支持的音频格式
  static const List<String> supportedFormats = [
    '.mp3',
    '.m4a',
    '.flac',
    '.aac',
    '.wav',
    '.ogg',
  ];

  // 扫描本地音乐文件
  Future<List<Song>> scanLocalMusic() async {
    // 检查是否为移动端平台
    if (Platform.isAndroid) {
      // 请求存储权限
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // 如果常规存储权限被拒绝，尝试使用管理外部存储权限（Android 10+）
        final manageExternalStorageStatus = await Permission
            .manageExternalStorage
            .request();
        if (!manageExternalStorageStatus.isGranted) {
          // 如果管理外部存储权限也被拒绝，尝试使用媒体权限（Android 13+）
          final audioPermission = await Permission.audio.request();
          if (!audioPermission.isGranted) {
            throw Exception('存储权限未授予');
          }
        }
      }
    }

    // 对于 iOS 平台，不需要请求存储权限，但需要确保在Info.plist中添加了适当的权限声明
    // 对于桌面平台（Linux、Windows、macOS），不需要请求权限，直接扫描

    // 获取音乐目录
    final Directory? musicDir = await _getMusicDirectory();
    if (musicDir == null) {
      throw Exception('无法访问音乐目录');
    }

    // 检查目录是否存在，如果不存在则创建
    if (!await musicDir.exists()) {
      try {
        await musicDir.create(recursive: true);
      } catch (e) {
        print('创建音乐目录时出错: $e');
        // 如果无法创建目录，使用文档目录作为备选
        final docDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${docDir.path}/Music');
        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }
        return await _scanDirectory(fallbackDir);
      }
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
            print('外部存储目录: ${externalDir.path}');
            // 对于Android 10及以上版本，使用应用专属目录
            // 对于Android 9及以下版本，尝试访问公共音乐目录
            if (Platform.version.contains('Android 10') ||
                Platform.version.contains('Android 11') ||
                Platform.version.contains('Android 12') ||
                Platform.version.contains('Android 13') ||
                Platform.version.contains('Android 14')) {
              // Android 10及以上使用应用专属目录
              final musicDir = Directory('${externalDir.path}/Music');
              print('Android 10+ 音乐目录: ${musicDir.path}');
              return musicDir;
            } else {
              // Android 9及以下尝试访问公共音乐目录
              final musicDir = Directory('/storage/emulated/0/Music');
              print('Android 9- 音乐目录: ${musicDir.path}');
              return musicDir;
            }
          }
        } catch (e) {
          print('获取外部存储目录时出错: $e');
          // 如果无法获取外部存储目录，则使用文档目录
          final docDir = await getApplicationDocumentsDirectory();
          final musicDir = Directory('${docDir.path}/Music');
          print('文档目录音乐文件夹: ${musicDir.path}');
          return musicDir;
        }
      }

      // 对于 iOS 平台，使用文档目录
      if (Platform.isIOS) {
        final docDir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${docDir.path}/Music');
        print('iOS 音乐目录: ${musicDir.path}');
        return musicDir;
      }

      // 对于桌面平台（Linux、Windows、macOS），使用用户主目录下的音乐文件夹
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final homeDir = _getHomeDirectory();
        if (homeDir != null) {
          // 不同平台的音乐目录路径不同
          String musicPath;
          if (Platform.isLinux) {
            musicPath = '$homeDir/Music'; // Linux 通常使用 Music 目录
          } else if (Platform.isWindows) {
            musicPath = '$homeDir/Music'; // Windows 通常使用 Music 目录
          } else {
            musicPath = '$homeDir/Music'; // macOS 通常使用 Music 目录
          }
          final musicDir = Directory(musicPath);
          print('桌面平台音乐目录: ${musicDir.path}');
          return musicDir;
        }
      }

      // 默认使用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docDir.path}/Music');
      print('默认音乐目录: ${musicDir.path}');
      return musicDir;
    } catch (e) {
      print('获取音乐目录时出错: $e');
      // 如果无法获取外部存储目录，则使用文档目录
      final docDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docDir.path}/Music');
      print('备选音乐目录: ${musicDir.path}');
      return musicDir;
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
    print('开始扫描目录: ${directory.path}');
    final songs = <Song>[];

    try {
      // 检查目录是否存在
      if (!await directory.exists()) {
        print('目录不存在，尝试创建: ${directory.path}');
        // 如果目录不存在则创建
        await directory.create(recursive: true);
      }

      print('开始列出目录中的文件: ${directory.path}');
      // 列出目录中的所有文件
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final file = entity;
          final fileName = file.uri.pathSegments.last;
          print('发现文件: ${file.path}');

          // 检查文件扩展名是否为支持的音频格式
          for (final format in supportedFormats) {
            if (fileName.toLowerCase().endsWith(format)) {
              print('匹配音频文件: ${file.path}');
              // 读取音频文件的元数据
              Tag? tags;
              try {
                tags = await AudioTags.read(file.path);
              } catch (e) {
                print('读取音频标签时出错: $e');
                // 如果标签读取失败，尝试从文件名提取信息
                tags = null;
              }

              // 使用just_audio库获取音频文件的实际时长
              Duration duration = const Duration(
                milliseconds: 210000,
              ); // 默认3分30秒
              try {
                final player = AudioPlayer();
                await player.setFilePath(file.path);
                duration =
                    player.duration ??
                    const Duration(milliseconds: 210000); // 默认3分30秒
                await player.dispose();
              } catch (e) {
                print('获取音频文件时长时出错: $e');
              }

              // 创建歌曲对象
              final song = Song(
                id: file.path.hashCode.toString(),
                title: tags?.title ?? _extractTitle(fileName),
                artist: tags?.trackArtist ?? '未知艺术家',
                album: tags?.album ?? '未知专辑',
                filePath: file.path,
                duration: duration,
                coverArtPath: tags?.pictures.isNotEmpty == true
                    ? null
                    : null, // 简化处理，实际应用中可能需要保存封面数据
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

    print('扫描完成，找到 ${songs.length} 首歌曲');
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
