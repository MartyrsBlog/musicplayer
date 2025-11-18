import 'dart:io';
import 'package:musicplayer/services/music_download_service.dart';

class FileFormatFixer {
  /// 修复音乐目录中格式错误的文件
  static Future<void> fixMusicDirectory(String musicPath) async {
    print('开始修复音乐目录: $musicPath');
    
    final directory = Directory(musicPath);
    if (!await directory.exists()) {
      print('目录不存在: $musicPath');
      return;
    }
    
    int fixedCount = 0;
    
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        final fileName = entity.path.toLowerCase();
        
        // 只处理.mp3文件
        if (fileName.endsWith('.mp3')) {
          try {
            // 检测实际格式
            final actualFormat = await MusicDownloadService.detectAudioFormat(entity);
            
            // 如果实际格式不是MP3，则重命名
            if (actualFormat != '.mp3') {
              final newPath = entity.path.replaceAll('.mp3', actualFormat);
              final newFile = File(newPath);
              
              // 检查目标文件是否已存在
              if (await newFile.exists()) {
                print('目标文件已存在，跳过: $newPath');
              } else {
                await entity.rename(newPath);
                print('重命名: ${entity.path} -> $newPath');
                fixedCount++;
              }
            }
          } catch (e) {
            print('处理文件时出错 ${entity.path}: $e');
          }
        }
      }
    }
    
    print('修复完成，共修复了 $fixedCount 个文件');
  }
}

void main() async {
  // 获取用户主目录下的Music文件夹
  String musicPath;
  if (Platform.isLinux || Platform.isMacOS) {
    musicPath = '${Platform.environment['HOME']}/Music';
  } else if (Platform.isWindows) {
    musicPath = '${Platform.environment['USERPROFILE']}/Music';
  } else {
    print('不支持的平台');
    return;
  }
  
  await FileFormatFixer.fixMusicDirectory(musicPath);
}