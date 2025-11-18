import 'dart:io';

class FileFormatFixer {
  /// 检测音频文件格式
  static Future<String> detectAudioFormat(File file) async {
    try {
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length < 4) return '.mp3'; // 默认
      
      // 检查MP4/M4A格式 (ftyp box)
      if (bytes.length >= 8) {
        // MP4文件通常以"ftyp"开头，偏移4字节
        if (bytes.length >= 8 && 
            bytes[4] == 0x66 && bytes[5] == 0x74 && 
            bytes[6] == 0x79 && bytes[7] == 0x70) { // "ftyp"
          
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
        if (bytes[0] == 0x66 && bytes[1] == 0x4C && 
            bytes[2] == 0x61 && bytes[3] == 0x43) { // "fLaC"
          return '.flac';
        }
      }
      
      // 检查WAV格式
      if (bytes.length >= 12) {
        if (bytes[0] == 0x52 && bytes[1] == 0x49 && 
            bytes[2] == 0x46 && bytes[3] == 0x46 && // "RIFF"
            bytes[8] == 0x57 && bytes[9] == 0x41 && 
            bytes[10] == 0x56 && bytes[11] == 0x45) { // "WAVE"
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
            final actualFormat = await detectAudioFormat(entity);
            
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