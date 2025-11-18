import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:audiotags/audiotags.dart';
import 'package:permission_handler/permission_handler.dart';

class MusicDownloadService {
  static const String _baseUrl = 'http://www.22a5.com';
  static const String _playUrl = 'http://www.22a5.com/js/play.php';
  static const String _lyricsUrl = 'https://js.eev3.com/lrc.php';

  static final Map<String, String> _headers = {
    'Referer': 'http://www.22a5.com/',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  };

  static Future<List<SongSearchResult>> searchMusic(String keyword) async {
    try {
      print('搜索音乐: $keyword');
      final encodedKeyword = Uri.encodeComponent(keyword.trim());
      final searchUrl = '$_baseUrl/so/$encodedKeyword.html';
      print('搜索URL: $searchUrl');
      
      final response = await http
          .get(
            Uri.parse(searchUrl),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 30));

      print('搜索响应状态码: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('搜索响应内容长度: ${response.body.length}');
        final document = html.parse(response.body);
        final searchList = document.querySelector('div.play_list');

        if (searchList != null) {
          final ul = searchList.querySelector('ul');
          if (ul != null) {
            final items = ul.querySelectorAll('li');
            List<SongSearchResult> results = [];

            print('找到 ${items.length} 个搜索结果');

            for (var item in items.take(10)) {
              // 只取前10首
              final link = item.querySelector('a[target="_mp3"]');
              if (link != null && link.text.isNotEmpty) {
                final href = link.attributes['href'];
                if (href != null && href.length > 10) {
                  final songId = href.substring(5, href.length - 5);
                  final titleParts = link.text.split('《');

                  if (titleParts.length >= 2) {
                    final singer = titleParts[0].trim();
                    final songName = titleParts[1].replaceAll('》', '').trim();

                    results.add(
                      SongSearchResult(
                        id: songId,
                        singer: singer,
                        name: songName,
                      ),
                    );
                    print('解析歌曲: $singer - $songName (ID: $songId)');
                  }
                }
              }
            }
            print('成功解析 ${results.length} 首歌曲');
            return results;
          } else {
            print('未找到ul元素');
          }
        } else {
          print('未找到div.play_list元素');
        }
      } else {
        print('搜索失败，状态码: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索失败: $e');
      print('错误堆栈: ${StackTrace.current}');
    }
    return [];
  }

  static Future<DownloadInfo?> getDownloadInfo(String id) async {
    try {
      print('获取下载信息，ID: $id');
      print('请求URL: $_playUrl');
      
      final response = await http
          .post(
            Uri.parse(_playUrl),
            headers: _headers,
            body: {'id': id, 'type': 'music'},
          )
          .timeout(const Duration(seconds: 30));

      print('响应状态码: ${response.statusCode}');
      print('响应内容长度: ${response.body.length}');
      
      if (response.statusCode == 200) {
        print('响应内容: ${response.body}');
        final jsonData = jsonDecode(response.body);
        final downloadInfo = DownloadInfo.fromJson(jsonData);
        print('下载信息解析成功: ${downloadInfo.title}');
        return downloadInfo;
      } else {
        print('HTTP请求失败，状态码: ${response.statusCode}');
        print('响应内容: ${response.body}');
      }
    } catch (e) {
      print('获取下载信息失败: $e');
      print('错误堆栈: ${StackTrace.current}');
    }
    return null;
  }

  static Future<bool> downloadLyrics(
    String lkid,
    String title,
    Directory saveDir,
  ) async {
    try {
      if (lkid.isEmpty) return false;

      final lyricFilename = _cleanFilename(title.split('[Mp3')[0]) + '.lrc';
      final lyricPath = path.join(saveDir.path, lyricFilename);

      final response = await http
          .get(Uri.parse('$_lyricsUrl?cid=$lkid'), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final lyricData = jsonDecode(response.body);
        final lyrics = lyricData['lrc'] ?? '';

        final file = File(lyricPath);
        await file.writeAsString(lyrics, encoding: utf8);

        print('歌词下载成功: $lyricFilename');
        return true;
      }
    } catch (e) {
      print('歌词下载失败: $e');
    }
    return false;
  }

  /// 提取歌曲下载流程
  /// 1. 搜索音乐获取歌曲ID
  /// 2. 根据ID获取下载信息
  /// 3. 下载音乐文件到临时位置
  /// 4. 验证文件完整性
  /// 5. 重命名文件为最终名称
  /// 6. 下载并保存歌词文件
  static Future<bool> downloadMusic(String id, Directory saveDir) async {
    try {
      print('开始下载音乐，ID: $id');
      print('保存目录: ${saveDir.path}');
      
      // Android权限检查
      if (Platform.isAndroid) {
        final hasPermission = await _requestStoragePermissions();
        if (!hasPermission) {
          print('Android存储权限不足，下载可能失败');
        }
      }
      
      // 步骤1: 获取下载信息
      final info = await getDownloadInfo(id);
      if (info == null) {
        print('无法获取下载信息');
        return false;
      }

      print('歌曲信息: ${info.title}');

      // 步骤2: 创建临时文件名
      final tempFilename =
          _cleanFilename(info.title.split('[Mp3')[0]) + '.temp';
      final tempFilePath = path.join(saveDir.path, tempFilename);
      final tempFile = File(tempFilePath);

      print('临时文件路径: $tempFilePath');

      // 步骤3: 下载音乐文件到临时位置
      final request = http.Request('GET', Uri.parse(info.url));
      request.headers.addAll({
        'Range': 'bytes=0-',
        'User-Agent': _headers['User-Agent']!,
      });

      print('开始下载音频文件...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (streamedResponse.statusCode == 206 ||
          streamedResponse.statusCode == 200) {
        print('音频文件下载开始，状态码: ${streamedResponse.statusCode}');
        
        // 步骤4: 写入临时文件
        final sink = tempFile.openWrite();
        int downloadedBytes = 0;
        
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
        }
        await sink.close();

        print('音频文件下载完成，大小: $downloadedBytes 字节');

        // 检查临时文件是否存在
        if (!await tempFile.exists()) {
          print('临时文件不存在');
          return false;
        }

        // 步骤5: 检测文件实际格式并重命名
        print('检测音频文件格式...');
        final actualExtension = await detectAudioFormat(tempFile);
        print('检测到的格式: $actualExtension');
        
        final finalFilename =
            _cleanFilename(info.title.split('[Mp3')[0]) + actualExtension;
        final finalFilePath = path.join(saveDir.path, finalFilename);
        final finalFile = File(finalFilePath);

        print('最终文件路径: $finalFilePath');

        // 步骤6: 检查最终文件是否已存在
        if (await finalFile.exists()) {
          print('文件已存在，检查完整性...');
          if (await _validateAudioFile(finalFile)) {
            print('文件已存在且完整: $finalFilename');
            await tempFile.delete(); // 删除临时文件
            
            // 步骤9: 下载歌词文件
            if (info.lkid.isNotEmpty) {
              print('下载歌词文件...');
              await downloadLyrics(info.lkid, info.title, saveDir);
            }
            
            return true;
          } else {
            print('现有文件损坏，替换: $finalFilename');
            await finalFile.delete();
          }
        }

        // 步骤7: 移动临时文件到最终位置
        print('移动文件到最终位置...');
        if (await tempFile.exists()) {
          await tempFile.rename(finalFilePath);
          print('文件移动完成');
        } else {
          print('错误：临时文件不存在，无法移动');
          return false;
        }

        // 步骤8: 验证最终文件
        print('验证最终文件是否存在...');
        if (await finalFile.exists()) {
          final fileSize = await finalFile.length();
          print('最终文件存在，大小: $fileSize 字节');
          
          if (await _validateAudioFile(finalFile)) {
            print('音频文件验证通过: $finalFilename');

            // 步骤9: 下载歌词文件
            if (info.lkid.isNotEmpty) {
              print('下载歌词文件...');
              await downloadLyrics(info.lkid, info.title, saveDir);
            }

            print('音乐下载成功: $finalFilename');
            
            // 最终确认：列出目录中的文件
            try {
              final files = await saveDir.list().toList();
              print('下载目录中的文件:');
              for (final file in files) {
                if (file is File) {
                  final size = await file.length();
                  print('  ${file.path} ($size 字节)');
                }
              }
            } catch (e) {
              print('列出目录文件失败: $e');
            }
            
            return true;
          } else {
            print('下载的文件损坏，删除: $finalFilename');
            await finalFile.delete();
            return false;
          }
        } else {
          print('错误：最终文件不存在');
          return false;
        }
      } else {
        print('HTTP请求失败，状态码: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('下载出错: $e');
      print('错误堆栈: ${StackTrace.current}');
    }
    return false;
  }

  static Future<bool> downloadSongOnly(String id, Directory saveDir) async {
    try {
      final info = await getDownloadInfo(id);
      if (info == null) return false;

      // 先下载到临时文件
      final tempFilename =
          _cleanFilename(info.title.split('[Mp3')[0]) + '.temp';
      final tempFilePath = path.join(saveDir.path, tempFilename);
      final tempFile = File(tempFilePath);

      // 下载音乐文件到临时位置
      final request = http.Request('GET', Uri.parse(info.url));
      request.headers.addAll({
        'Range': 'bytes=0-',
        'User-Agent': _headers['User-Agent']!,
      });

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (streamedResponse.statusCode == 206 ||
          streamedResponse.statusCode == 200) {
        final sink = tempFile.openWrite();
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
        }
        await sink.close();

        // 检测文件实际格式并重命名
        final actualExtension = await detectAudioFormat(tempFile);
        final finalFilename =
            _cleanFilename(info.title.split('[Mp3')[0]) + actualExtension;
        final finalFilePath = path.join(saveDir.path, finalFilename);
        final finalFile = File(finalFilePath);

        // 检查最终文件是否已存在
        if (await finalFile.exists()) {
          if (await _validateAudioFile(finalFile)) {
            print('文件已存在且完整: $finalFilename');
            await tempFile.delete(); // 删除临时文件
            return true;
          } else {
            print('现有文件损坏，替换: $finalFilename');
            await finalFile.delete();
          }
        }

        // 移动临时文件到最终位置
        await tempFile.rename(finalFilePath);

        // 验证最终文件
        if (await _validateAudioFile(finalFile)) {
          print('音乐下载成功: $finalFilename');
          return true;
        } else {
          print('下载的文件损坏，删除: $finalFilename');
          await finalFile.delete();
          return false;
        }
      }
    } catch (e) {
      print('下载出错: $e');
    }
    return false;
  }

  static Future<bool> downloadSongWithEmbeddedLyrics(
    String id,
    Directory saveDir,
  ) async {
    try {
      print('开始下载嵌入歌词的歌曲，ID: $id');
      print('保存目录: ${saveDir.path}');
      
      // Android权限检查
      if (Platform.isAndroid) {
        final hasPermission = await _requestStoragePermissions();
        if (!hasPermission) {
          print('Android存储权限不足，下载可能失败');
        }
      }
      
      final info = await getDownloadInfo(id);
      if (info == null) {
        print('无法获取下载信息');
        return false;
      }

      print('歌曲信息: ${info.title}');
      print('下载URL: ${info.url}');
      print('歌词ID: ${info.lkid}');

      // 先下载到临时文件
      final tempFilename =
          _cleanFilename(info.title.split('[Mp3')[0]) + '.temp';
      final tempFilePath = path.join(saveDir.path, tempFilename);
      final tempFile = File(tempFilePath);

      print('临时文件路径: $tempFilePath');

      // 下载音乐文件到临时位置
      final request = http.Request('GET', Uri.parse(info.url));
      request.headers.addAll({
        'Range': 'bytes=0-',
        'User-Agent': _headers['User-Agent']!,
      });

      print('开始下载音频文件...');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      if (streamedResponse.statusCode == 206 ||
          streamedResponse.statusCode == 200) {
        print('音频文件下载开始，状态码: ${streamedResponse.statusCode}');
        
        final sink = tempFile.openWrite();
        int downloadedBytes = 0;
        
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
        }
        await sink.close();

        print('音频文件下载完成，大小: $downloadedBytes 字节');

        // 检查临时文件是否存在
        if (!await tempFile.exists()) {
          print('临时文件不存在');
          return false;
        }

        // 下载歌词
        String? lyrics;
        if (info.lkid.isNotEmpty) {
          print('开始下载歌词...');
          lyrics = await _downloadLyricsContent(info.lkid);
          if (lyrics != null && lyrics.isNotEmpty) {
            print('歌词下载成功，长度: ${lyrics.length} 字符');
          } else {
            print('歌词下载失败或为空');
          }
        } else {
          print('没有歌词ID');
        }

        // 检测文件实际格式并重命名
        print('检测音频文件格式...');
        final actualExtension = await detectAudioFormat(tempFile);
        print('检测到的格式: $actualExtension');
        
        final finalFilename =
            _cleanFilename(info.title.split('[Mp3')[0]) + actualExtension;
        final finalFilePath = path.join(saveDir.path, finalFilename);
        final finalFile = File(finalFilePath);

        print('最终文件路径: $finalFilePath');

        // 检查最终文件是否已存在
        if (await finalFile.exists()) {
          print('文件已存在，检查完整性...');
          if (await _validateAudioFile(finalFile)) {
            print('文件已存在且完整: $finalFilename');
            await tempFile.delete(); // 删除临时文件
            
            // 即使文件已存在，也要创建歌词文件（如果有歌词）
            if (lyrics != null && lyrics.isNotEmpty) {
              await _embedLyricsToFile(finalFile, lyrics, actualExtension);
            }
            
            return true;
          } else {
            print('现有文件损坏，替换: $finalFilename');
            await finalFile.delete();
          }
        }

        // 步骤7: 移动临时文件到最终位置
        print('移动文件到最终位置...');
        if (await tempFile.exists()) {
          await tempFile.rename(finalFilePath);
          print('文件移动完成');
        } else {
          print('错误：临时文件不存在，无法移动');
          return false;
        }

        // 步骤8: 验证最终文件
        print('验证最终文件是否存在...');
        if (await finalFile.exists()) {
          final fileSize = await finalFile.length();
          print('最终文件存在，大小: $fileSize 字节');
          
          if (await _validateAudioFile(finalFile)) {
            print('音频文件验证通过: $finalFilename');
            
            // 嵌入歌词到音频文件
          if (lyrics != null && lyrics.isNotEmpty) {
            print('嵌入歌词到音频文件...');
            final lyricSuccess = await _embedLyricsToFile(
              finalFile,
              lyrics,
              actualExtension,
            );
            if (lyricSuccess) {
              print('歌词成功嵌入音频文件');
            } else {
              print('歌词嵌入失败，但音频文件已保存');
            }
          }

            print('嵌入歌词的歌曲下载成功: $finalFilename');
            
            // 最终确认：列出目录中的文件
            try {
              final files = await saveDir.list().toList();
              print('下载目录中的文件:');
              for (final file in files) {
                if (file is File) {
                  final size = await file.length();
                  print('  ${file.path} ($size 字节)');
                }
              }
            } catch (e) {
              print('列出目录文件失败: $e');
            }
            
            return true;
          } else {
            print('下载的文件损坏，删除: $finalFilename');
            await finalFile.delete();
            return false;
          }
        } else {
          print('错误：最终文件不存在');
          return false;
        }
      } else {
        print('HTTP请求失败，状态码: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('下载出错: $e');
      print('错误堆栈: ${StackTrace.current}');
    }
    return false;
  }

  static Future<String?> _downloadLyricsContent(String lkid) async {
    try {
      if (lkid.isEmpty) return null;

      final response = await http
          .get(Uri.parse('$_lyricsUrl?cid=$lkid'), headers: _headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final lyricData = jsonDecode(response.body);
        return lyricData['lrc'] ?? '';
      }
    } catch (e) {
      print('下载歌词内容失败: $e');
    }
    return null;
  }

  static Future<bool> _embedLyricsToFile(
    File audioFile,
    String lyrics,
    String extension,
  ) async {
    try {
      print('开始将歌词嵌入音频文件: ${audioFile.path}');
      
      // 检查音频文件是否存在
      if (!await audioFile.exists()) {
        print('错误：音频文件不存在');
        return false;
      }

      // 根据文件扩展名确定支持的格式
      final supportedFormats = ['.mp3', '.m4a', '.flac'];
      if (!supportedFormats.contains(extension.toLowerCase())) {
        print('警告：文件格式 $extension 可能不支持歌词嵌入，尝试继续...');
      }

      // 尝试使用audiotags库嵌入歌词
      try {
        print('尝试使用audiotags库嵌入歌词...');
        
        // 读取现有的音频标签
        Tag? tag;
        try {
          tag = await AudioTags.read(audioFile.path);
          print('成功读取音频标签');
        } catch (e) {
          print('读取音频标签失败，将创建新标签: $e');
          tag = null;
        }

        // 创建或更新标签
        final newTag = Tag(
          title: tag?.title ?? path.basenameWithoutExtension(audioFile.path),
          album: tag?.album ?? '未知专辑',
          year: tag?.year,
          genre: tag?.genre,
          lyrics: lyrics, // 将歌词嵌入到标签中
          pictures: tag?.pictures ?? [],
        );

        print('准备写入歌词到音频标签，歌词长度: ${lyrics.length} 字符');

        // 写入标签到音频文件
        await AudioTags.write(audioFile.path, newTag);
        print('歌词成功嵌入到音频文件');
        
        // 验证歌词是否成功嵌入
        print('验证歌词嵌入结果...');
        final verifyTag = await AudioTags.read(audioFile.path);
        if (verifyTag?.lyrics != null && verifyTag!.lyrics!.isNotEmpty) {
          print('歌词嵌入验证成功，嵌入长度: ${verifyTag.lyrics!.length} 字符');
          return true;
        } else {
          print('警告：歌词嵌入验证失败');
          return false;
        }
      } catch (e) {
        print('audiotags库嵌入失败: $e');
        print('使用备用方案创建歌词文件...');
        
        // 如果audiotags失败，创建备用歌词文件
        return await _createBackupLyricsFile(audioFile, lyrics, extension);
      }
    } catch (e) {
      print('嵌入歌词时出错: $e');
      return false;
    }
  }

  /// 创建备用歌词文件（如果嵌入失败）
  static Future<bool> _createBackupLyricsFile(
    File audioFile,
    String lyrics,
    String extension,
  ) async {
    try {
      final audioPath = audioFile.path;
      final lyricsPath = audioPath.replaceAll(extension, '.lrc');
      final lyricsFile = File(lyricsPath);

      print('创建备用歌词文件: ${lyricsFile.path}');

      await lyricsFile.writeAsString(lyrics, encoding: utf8);
      
      if (await lyricsFile.exists() && await lyricsFile.length() > 0) {
        print('备用歌词文件创建成功');
        return true;
      } else {
        print('备用歌词文件创建失败');
        return false;
      }
    } catch (e) {
      print('创建备用歌词文件时出错: $e');
      return false;
    }
  }

  static Future<String> detectAudioFormat(File file) async {
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length < 4) return '.mp3'; // 默认

      // 检查MP4/M4A格式 (ftyp box)
      if (bytes.length >= 8) {
        // MP4文件通常以"ftyp"开头，偏移4字节
        if (bytes.length >= 8 &&
            bytes[4] == 0x66 &&
            bytes[5] == 0x74 &&
            bytes[6] == 0x79 &&
            bytes[7] == 0x70) {
          // "ftyp"

          // 检查是否为M4A
          if (bytes.length >= 12) {
            final brand = String.fromCharCodes(bytes.sublist(8, 12));
            if (brand == 'M4A ') return '.m4a';
            if (brand == 'mp41' || brand == 'mp42') return '.m4a';
          }
          return '.m4a';
        }
      }

      // 检查MP3格式
      if (bytes.length >= 3) {
        // ID3标签
        if (bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
          return '.mp3';
        }
        // MPEG帧同步
        if ((bytes[0] & 0xFF) == 0xFF && ((bytes[1] & 0xE0) == 0xE0)) {
          return '.mp3';
        }
      }

      // 检查FLAC格式
      if (bytes.length >= 4) {
        if (bytes[0] == 0x66 &&
            bytes[1] == 0x4C &&
            bytes[2] == 0x61 &&
            bytes[3] == 0x43) {
          // "fLaC"
          return '.flac';
        }
      }

      // 检查WAV格式
      if (bytes.length >= 12) {
        if (bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 && // "RIFF"
            bytes[8] == 0x57 &&
            bytes[9] == 0x41 &&
            bytes[10] == 0x56 &&
            bytes[11] == 0x45) {
          // "WAVE"
          return '.wav';
        }
      }

      // 默认返回mp3
      return '.mp3';
    } catch (e) {
      print('检测音频格式时出错: $e');
      return '.mp3';
    }
  }

  static Future<bool> _validateAudioFile(File file) async {
    try {
      final fileSize = await file.length();
      if (fileSize < 1024) {
        // 音频文件应该至少有1KB
        return false;
      }

      final format = await detectAudioFormat(file);

      switch (format) {
        case '.mp3':
          return await _validateMp3File(file);
        case '.m4a':
          return await _validateM4aFile(file);
        case '.flac':
          return await _validateFlacFile(file);
        case '.wav':
          return await _validateWavFile(file);
        default:
          return true; // 未知格式，假设有效
      }
    } catch (e) {
      print('验证音频文件时出错: $e');
      return false;
    }
  }

  static Future<bool> _validateMp3File(File file) async {
    try {
      final bytes = await file.openRead(0, 3).first;
      if (bytes.length >= 3) {
        // 检查ID3标签或MPEG帧同步
        final hasId3 =
            bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33; // "ID3"
        final hasMpegSync =
            (bytes[0] & 0xFF) == 0xFF &&
            ((bytes[1] & 0xE0) == 0xE0); // MPEG sync

        return hasId3 || hasMpegSync;
      }
      return false;
    } catch (e) {
      print('验证MP3文件时出错: $e');
      return false;
    }
  }

  static Future<bool> _validateM4aFile(File file) async {
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length >= 8) {
        // 检查MP4文件签名
        return bytes[4] == 0x66 &&
            bytes[5] == 0x74 &&
            bytes[6] == 0x79 &&
            bytes[7] == 0x70; // "ftyp"
      }
      return false;
    } catch (e) {
      print('验证M4A文件时出错: $e');
      return false;
    }
  }

  static Future<bool> _validateFlacFile(File file) async {
    try {
      final bytes = await file.openRead(0, 4).first;
      if (bytes.length >= 4) {
        // 检查FLAC文件签名
        return bytes[0] == 0x66 &&
            bytes[1] == 0x4C &&
            bytes[2] == 0x61 &&
            bytes[3] == 0x43; // "fLaC"
      }
      return false;
    } catch (e) {
      print('验证FLAC文件时出错: $e');
      return false;
    }
  }

  static Future<bool> _validateWavFile(File file) async {
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length >= 12) {
        // 检查WAV文件签名
        return bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 && // "RIFF"
            bytes[8] == 0x57 &&
            bytes[9] == 0x41 &&
            bytes[10] == 0x56 &&
            bytes[11] == 0x45; // "WAVE"
      }
      return false;
    } catch (e) {
      print('验证WAV文件时出错: $e');
      return false;
    }
  }

  static String _cleanFilename(String filename) {
    // 移除文件名中的非法字符
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 检查并请求必要的存储权限
  static Future<bool> _requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      print('检查Android存储权限...');
      
      // Android 13+ (API 33+) 需要媒体权限
      if (Platform.version.contains('33') || Platform.version.contains('34') || Platform.version.contains('35')) {
        final mediaPermission = await Permission.audio.request();
        if (mediaPermission.isGranted) {
          print('音频媒体权限已授予');
        } else {
          print('音频媒体权限被拒绝');
          return false;
        }
      } else {
        // Android 12及以下版本
        final storagePermission = await Permission.storage.request();
        if (storagePermission.isGranted) {
          print('存储权限已授予');
        } else {
          print('存储权限被拒绝，尝试管理外部存储权限');
          final managePermission = await Permission.manageExternalStorage.request();
          if (managePermission.isGranted) {
            print('管理外部存储权限已授予');
          } else {
            print('管理外部存储权限被拒绝');
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      print('权限检查失败: $e');
      return false;
    }
  }

  static Future<Directory> getDownloadDirectory() async {
    Directory? musicDir;
    
    print('获取下载目录...');
    
    // 首先检查权限
    final hasPermission = await _requestStoragePermissions();
    if (!hasPermission) {
      print('缺少必要权限，使用应用内部存储');
    }
    
    if (Platform.isAndroid) {
      // Android: 根据系统版本选择合适的存储方案
      try {
        // 优先尝试使用Downloads目录（Android 10+ 分区存储兼容）
        final downloadsDir = Directory('/storage/emulated/0/Download/Music');
        if (await downloadsDir.exists()) {
          musicDir = Directory(path.join(downloadsDir.path, 'MusicPlayer'));
          print('使用系统Downloads目录: ${musicDir.path}');
        } else {
          // 尝试创建Downloads目录下的Music文件夹
          try {
            await downloadsDir.create(recursive: true);
            musicDir = Directory(path.join(downloadsDir.path, 'MusicPlayer'));
            await musicDir.create(recursive: true);
            print('创建并使用Downloads目录: ${musicDir.path}');
          } catch (e) {
            print('无法访问Downloads目录: $e');
            
            // 备用方案：使用应用外部存储目录
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              musicDir = Directory(path.join(externalDir.path, 'Music', 'Downloads'));
              print('使用应用外部存储: ${musicDir.path}');
            }
          }
        }
      } catch (e) {
        print('Android存储访问失败: $e');
        
        // 最终备用方案：使用应用内部存储
        final directory = await getApplicationDocumentsDirectory();
        musicDir = Directory(path.join(directory.path, 'Downloads'));
        print('使用应用内部存储: ${musicDir.path}');
      }
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      musicDir = Directory(path.join(directory.path, 'Downloads'));
      print('iOS下载目录: ${musicDir.path}');
    } else {
      // 桌面平台 (Linux, Windows, macOS)
      if (Platform.isLinux) {
        // Linux: 尝试使用用户主目录下的Music文件夹
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          musicDir = Directory(path.join(homeDir, 'Music', 'Downloads'));
          print('Linux音乐目录路径: ${musicDir.path}');
        }
      }
      
      // 如果没有找到合适的目录，使用应用文档目录
      if (musicDir == null) {
        final directory = await getApplicationDocumentsDirectory();
        musicDir = Directory(path.join(directory.path, 'Downloads'));
        print('使用应用文档目录: ${musicDir.path}');
      }
    }

    // 确保目录存在
    if (musicDir == null) {
      print('错误：无法确定下载目录');
      // 返回临时目录作为最后备用
      final tempDir = Directory.systemTemp;
      musicDir = Directory(path.join(tempDir.path, 'music_downloads'));
      await musicDir.create(recursive: true);
      return musicDir;
    }

    print('检查目录是否存在: ${musicDir.path}');
    if (!await musicDir.exists()) {
      try {
        print('目录不存在，创建目录...');
        await musicDir.create(recursive: true);
        print('创建下载目录成功: ${musicDir.path}');
        
        // 再次确认目录创建成功
        if (await musicDir.exists()) {
          print('目录创建确认成功');
        } else {
          print('警告：目录创建后仍然不存在');
        }
      } catch (e) {
        print('创建下载目录失败: $e');
        // 如果创建失败，返回临时目录
        final tempDir = Directory.systemTemp;
        musicDir = Directory(path.join(tempDir.path, 'music_downloads'));
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
      }
    } else {
      print('目录已存在: ${musicDir.path}');
    }

    // 检查目录权限
    try {
      final testFile = File(path.join(musicDir.path, '.test'));
      await testFile.writeAsString('test');
      await testFile.delete();
      print('目录写入权限正常');
    } catch (e) {
      print('目录写入权限检查失败: $e');
    }

    return musicDir;
  }
}

class SongSearchResult {
  final String id;
  final String singer;
  final String name;

  SongSearchResult({
    required this.id,
    required this.singer,
    required this.name,
  });

  @override
  String toString() => '$singer - $name';
}

class DownloadInfo {
  final String title;
  final String url;
  final String lkid;

  DownloadInfo({required this.title, required this.url, required this.lkid});

  factory DownloadInfo.fromJson(Map<String, dynamic> json) {
    return DownloadInfo(
      title: json['title']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      lkid: json['lkid']?.toString() ?? '',
    );
  }
}
