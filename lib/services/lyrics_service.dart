import 'dart:io';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:audiotags/audiotags.dart';
import '../models/song.dart';

class LyricsService {
  /// 读取歌曲的歌词
  static Future<LyricsReaderModel?> loadLyrics(Song song) async {
    try {
      // 1. 尝试读取音频文件内置的歌词标签
      final embeddedLyrics = await _loadEmbeddedLyrics(song);
      if (embeddedLyrics != null) {
        return LyricsModelBuilder.create()
            .bindLyricToMain(embeddedLyrics)
            .getModel();
      }

      // 2. 尝试读取外挂歌词文件
      final externalLyrics = await _loadExternalLyrics(song);
      if (externalLyrics != null) {
        return LyricsModelBuilder.create()
            .bindLyricToMain(externalLyrics)
            .getModel();
      }

      // 3. 如果都没有找到歌词，返回null
      return null;
    } catch (e) {
      print('加载歌词时出错: $e');
      return null;
    }
  }

  /// 读取音频文件内置的歌词标签
  static Future<String?> _loadEmbeddedLyrics(Song song) async {
    try {
      // 使用audiotags读取音频文件的元数据
      final tag = await AudioTags.read(song.filePath);
      if (tag != null && tag.lyrics != null && tag.lyrics!.isNotEmpty) {
        return tag.lyrics;
      }
      
      return null;
    } catch (e) {
      print('读取内置歌词时出错: $e');
      return null;
    }
  }

  /// 读取外挂歌词文件
  static Future<String?> _loadExternalLyrics(Song song) async {
    try {
      // 获取音频文件的路径和文件名
      final audioFile = File(song.filePath);
      final fileNameWithoutExtension = _getFileNameWithoutExtension(audioFile);
      
      // 构造同名的.lrc文件路径
      final lrcFilePath = '${audioFile.parent.path}/$fileNameWithoutExtension.lrc';
      final lrcFile = File(lrcFilePath);
      
      // 检查.lrc文件是否存在
      if (await lrcFile.exists()) {
        // 读取歌词文件内容
        final lyricsContent = await lrcFile.readAsString();
        return lyricsContent;
      }
      
      return null;
    } catch (e) {
      print('读取外挂歌词时出错: $e');
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