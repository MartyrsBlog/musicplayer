import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class PlayerProvider with ChangeNotifier {
  // 音频播放器实例
  late final AudioPlayer _audioPlayer;
  
  // 播放列表
  List<Song> _playlist = [];
  
  // 当前播放索引
  int _currentSongIndex = -1;
  
  // 是否正在播放
  bool _isPlaying = false;
  
  // 是否为夜间模式
  bool _isDarkMode = false;
  
  // 是否已初始化
  bool _isInitialized = false;
  
  // 构造函数
  PlayerProvider() {
    _initializePlayer();
  }
  
  // 初始化音频播放器
  Future<void> _initializePlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      // 监听播放状态变化
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        notifyListeners();
      }, onError: (Object error) {
        // 处理流错误
        if (kDebugMode) {
          print('Player state stream error: $error');
        }
      });
      
      // 监听播放完成事件
      _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          playNext();
        }
      }, onError: (Object error) {
        // 处理流错误
        if (kDebugMode) {
          print('Processing state stream error: $error');
        }
      });
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Failed to initialize audio player: $e');
      }
    }
  }
  
  // 获取音频播放器实例
  AudioPlayer get audioPlayer {
    if (!_isInitialized) {
      throw Exception('Audio player is not initialized');
    }
    return _audioPlayer;
  }
  
  // 获取播放列表
  List<Song> get playlist => _playlist;
  
  // 获取当前歌曲
  Song? get currentSong => 
      _currentSongIndex >= 0 && _currentSongIndex < _playlist.length 
          ? _playlist[_currentSongIndex] 
          : null;
  
  // 获取当前歌曲索引
  int get currentSongIndex => _currentSongIndex;
  
  // 获取播放状态
  bool get isPlaying => _isPlaying;
  
  // 获取夜间模式状态
  bool get isDarkMode => _isDarkMode;
  
  // 设置播放列表
  void setPlaylist(List<Song> songs) {
    _playlist = songs;
    notifyListeners();
  }
  
  // 播放指定索引的歌曲
  Future<void> playSong(int index) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Audio player is not initialized');
      }
      return;
    }
    
    if (index >= 0 && index < _playlist.length) {
      _currentSongIndex = index;
      final song = _playlist[index];
      
      try {
        // 使用Uri.file来正确处理包含中文字符的文件路径
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.file(song.filePath)),
        );
        await _audioPlayer.play();
      } catch (e) {
        // 处理播放错误
        if (kDebugMode) {
          print('Error playing song: $e');
        }
      }
    }
  }
  
  // 播放
  Future<void> play() async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Audio player is not initialized');
      }
      return;
    }
    
    if (_currentSongIndex == -1 && _playlist.isNotEmpty) {
      await playSong(0);
    } else {
      await _audioPlayer.play();
    }
  }
  
  // 暂停
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _audioPlayer.pause();
  }
  
  // 停止
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _audioPlayer.stop();
    _currentSongIndex = -1;
    notifyListeners();
  }
  
  // 播放下一首
  void playNext() {
    if (!_isInitialized) return;
    if (_playlist.isEmpty) return;
    
    final nextIndex = (_currentSongIndex + 1) % _playlist.length;
    playSong(nextIndex);
  }
  
  // 播放上一首
  void playPrevious() {
    if (!_isInitialized) return;
    if (_playlist.isEmpty) return;
    
    final prevIndex = (_currentSongIndex - 1 + _playlist.length) % _playlist.length;
    playSong(prevIndex);
  }
  
  // 切换播放/暂停状态
  void togglePlayPause() {
    if (!_isInitialized) return;
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }
  
  // 切换夜间模式
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
  
  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    await _audioPlayer.seek(position);
  }
  
  // 释放资源
  void dispose() {
    if (_isInitialized) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }
}