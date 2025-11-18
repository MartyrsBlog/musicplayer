import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/services/music_download_service.dart';

void main() {
  group('MusicDownloadService Tests', () {
    test('SongSearchResult toString should return formatted string', () {
      final song = SongSearchResult(
        id: 'test123',
        singer: 'Test Artist',
        name: 'Test Song',
      );
      
      expect(song.toString(), 'Test Artist - Test Song');
    });

    test('DownloadInfo fromJson should handle empty data', () {
      final json = <String, dynamic>{};
      final info = DownloadInfo.fromJson(json);
      
      expect(info.title, '');
      expect(info.url, '');
      expect(info.lkid, '');
    });

    test('DownloadInfo fromJson should handle valid data', () {
      final json = {
        'title': 'Test Title',
        'url': 'http://example.com/test.mp3',
        'lkid': 'test123',
      };
      final info = DownloadInfo.fromJson(json);
      
      expect(info.title, 'Test Title');
      expect(info.url, 'http://example.com/test.mp3');
      expect(info.lkid, 'test123');
    });

    test('DownloadInfo fromJson should handle int values', () {
      final json = {
        'title': 'Test Title',
        'url': 'http://example.com/test.mp3',
        'lkid': 12345, // int instead of string
      };
      final info = DownloadInfo.fromJson(json);
      
      expect(info.title, 'Test Title');
      expect(info.url, 'http://example.com/test.mp3');
      expect(info.lkid, '12345'); // Should be converted to string
    });
  });
}