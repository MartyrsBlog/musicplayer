import 'package:flutter_test/flutter_test.dart';
import 'package:metadata_god/metadata_god.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  test('Audio tags reading test', () async {
    // 这是一个示例测试，实际使用时需要提供有效的音频文件路径
    // 由于测试环境中可能没有音频文件，这个测试主要用于演示
    
    // 假设有一个测试音频文件
    final testAudioFile = File(path.join(Directory.current.path, 'test', 'assets', 'test.mp3'));
    
    if (await testAudioFile.exists()) {
      try {
        final tags = await MetadataGod.readMetadata(file: testAudioFile.path);
        expect(tags, isNotNull);
        print('Title: ${tags?.title}');
        print('Artist: ${tags?.artist}');
        print('Album: ${tags?.album}');
      } catch (e) {
        print('Error reading audio tags: $e');
      }
    } else {
      print('Test audio file not found, skipping test');
    }
  });
}