import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:metadata_god/metadata_god.dart';
import '../models/song.dart';

class LyricsService {
  /// 读取歌曲的歌词
  static Future<LyricsReaderModel?> loadLyrics(Song song) async {
    try {
      print('开始加载歌词，歌曲文件: ${song.filePath}');
      print('歌曲标题: ${song.title}');
      
      // 1. 尝试读取音频文件内置的歌词标签
      print('尝试读取内置歌词...');
      final embeddedLyrics = await _loadEmbeddedLyrics(song);
      if (embeddedLyrics != null) {
        print('找到内置歌词，长度: ${embeddedLyrics.length}');
        return LyricsModelBuilder.create()
            .bindLyricToMain(embeddedLyrics)
            .getModel();
      }

      // 2. 尝试读取外挂歌词文件
      print('尝试读取外挂歌词文件...');
      final externalLyrics = await _loadExternalLyrics(song);
      if (externalLyrics != null) {
        print('找到外挂歌词，长度: ${externalLyrics.length}');
        final lyricsModel = LyricsModelBuilder.create()
            .bindLyricToMain(externalLyrics)
            .getModel();
        print('歌词模型创建成功，歌词行数: ${lyricsModel.lyrics.length}');
        return lyricsModel;
      }

      // 3. 如果都没有找到歌词，返回null
      print('未找到任何歌词文件');
      return null;
    } catch (e) {
      print('加载歌词时出错: $e');
      print('错误堆栈: ${StackTrace.current}');
      return null;
    }
  }

  /// 读取音频文件内置的歌词标签
  static Future<String?> _loadEmbeddedLyrics(Song song) async {
    try {
      // metadata_god不支持歌词字段，暂时跳过内置歌词读取
      // 未来可以考虑使用其他库来读取歌词
      print('metadata_god不支持内置歌词读取，跳过');
      
      return null;
    } catch (e) {
      print('读取内置歌词时出错: $e');
      // 如果音频文件损坏或无法读取，直接返回null，让系统尝试读取外挂歌词文件
      return null;
    }
  }

  /// 读取外挂歌词文件
  static Future<String?> _loadExternalLyrics(Song song) async {
    try {
      // 获取音频文件的路径和文件名
      final audioFile = File(song.filePath);
      final fileNameWithoutExtension = _getFileNameWithoutExtension(audioFile);
      
      // 1. 首先在歌曲文件同目录下查找同名.lrc文件
      final sameDirLrcPath = path.join(audioFile.parent.path, '$fileNameWithoutExtension.lrc');
      final sameDirLrcFile = File(sameDirLrcPath);
      
      print('正在查找同目录外挂歌词文件: $sameDirLrcPath');
      
      if (await sameDirLrcFile.exists()) {
        print('找到同目录外挂歌词文件，正在读取...');
        final lyricsContent = await sameDirLrcFile.readAsString();
        print('同目录外挂歌词读取成功，长度: ${lyricsContent.length}');
        return lyricsContent;
      }
      
      // 2. 如果同目录没有找到，在上级目录的Lyrics文件夹中查找
      final parentDir = audioFile.parent;
      final grandParentDir = parentDir.parent;
      final lyricsDirPath = path.join(grandParentDir.path, 'Lyrics');
      final lyricsDir = Directory(lyricsDirPath);
      
      print('正在查找上上级目录的Lyrics文件夹: $lyricsDirPath');
      
      if (await lyricsDir.exists()) {
        final lyricsLrcPath = path.join(lyricsDir.path, '$fileNameWithoutExtension.lrc');
        final lyricsLrcFile = File(lyricsLrcPath);
        
        print('正在查找Lyrics文件夹中的歌词文件: $lyricsLrcPath');
        
        if (await lyricsLrcFile.exists()) {
          print('找到Lyrics文件夹中的歌词文件，正在读取...');
          final lyricsContent = await lyricsLrcFile.readAsString();
          print('Lyrics文件夹中的歌词读取成功，长度: ${lyricsContent.length}');
          return lyricsContent;
        } else {
          print('Lyrics文件夹中没有找到同名歌词文件: $lyricsLrcPath');
        }
      } else {
        print('上级目录的Lyrics文件夹不存在: $lyricsDirPath');
      }
      
      // 3. 如果都没找到，返回null
      print('未找到任何外挂歌词文件');
      return null;
    } catch (e) {
      print('读取外挂歌词时出错: $e');
      print('音频文件路径: ${song.filePath}');
      return null;
    }
  }

  /// 获取不带扩展名的文件名
  static String _getFileNameWithoutExtension(File file) {
    final fileName = file.uri.pathSegments.last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex > 0) {
      return fileName.substring(0, dotIndex);
    }
    return fileName;
  }
}