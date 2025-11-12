import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/lyrics_service.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // 当前歌曲的歌词模型
  LyricsReaderModel? _lyricsModel;

  // 当前歌词位置（毫秒）
  int _lyricsPosition = 0;

  // 播放位置（毫秒）
  int _playbackPosition = 0;

  // SharedPreferences实例
  late SharedPreferences _prefs;

  // 构造函数
  PlayerProvider() {
    _initializePlayer();
    _initializePreferences();
  }

  // 初始化音频播放器
  Future<void> _initializePlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;

      // 监听播放状态变化
      _audioPlayer.playerStateStream.listen(
        (state) {
          _isPlaying = state.playing;
          notifyListeners();
        },
        onError: (Object error) {
          // 处理流错误
          if (kDebugMode) {
            print('Player state stream error: $error');
          }
        },
      );

      // 监听播放完成事件
      _audioPlayer.processingStateStream.listen(
        (state) {
          if (state == ProcessingState.completed) {
            playNext();
          }
        },
        onError: (Object error) {
          // 处理流错误
          if (kDebugMode) {
            print('Processing state stream error: $error');
          }
        },
      );

      // 监听播放位置变化以同步歌词
      _audioPlayer.positionStream.listen(
        (position) {
          _lyricsPosition = position.inMilliseconds;
          _playbackPosition = position.inMilliseconds;
          notifyListeners();
        },
        onError: (Object error) {
          // 处理流错误
          if (kDebugMode) {
            print('Position stream error: $error');
          }
        },
      );
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('Failed to initialize audio player: $e');
      }
    }
  }

  // 初始化SharedPreferences
  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 保存播放状态
  Future<void> _savePlaybackState() async {
    if (_currentSongIndex >= 0) {
      await _prefs.setInt('lastSongIndex', _currentSongIndex);
      await _prefs.setInt('lastPlaybackPosition', _playbackPosition);
    }
  }

  // 恢复播放状态
  Future<void> restorePlaybackState(List<Song> playlist) async {
    final lastSongIndex = _prefs.getInt('lastSongIndex');
    final lastPlaybackPosition = _prefs.getInt('lastPlaybackPosition');

    if (lastSongIndex != null &&
        lastPlaybackPosition != null &&
        lastSongIndex >= 0 &&
        lastSongIndex < playlist.length) {
      _playlist = playlist;
      _currentSongIndex = lastSongIndex;
      _playbackPosition = lastPlaybackPosition;

      // 加载歌曲但不自动播放
      await _loadSongWithoutPlaying(
        _currentSongIndex,
        Duration(milliseconds: _playbackPosition),
      );

      notifyListeners();
    }
  }

  // 加载歌曲但不自动播放
  Future<void> _loadSongWithoutPlaying(int index, Duration position) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Audio player is not initialized');
      }
      return;
    }

    if (index >= 0 && index < _playlist.length) {
      final song = _playlist[index];

      try {
        // 使用Uri.file来正确处理包含中文字符的文件路径
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.file(song.filePath)),
        );

        // 跳转到保存的位置
        await _audioPlayer.seek(position);

        // 加载歌词
        _lyricsModel = await LyricsService.loadLyrics(song);
      } catch (e) {
        // 处理播放错误
        if (kDebugMode) {
          print('Error loading song: $e');
        }
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

  // 获取歌词模型
  LyricsReaderModel? get lyricsModel => _lyricsModel;

  // 获取歌词位置
  int get lyricsPosition => _lyricsPosition;

  // 获取播放位置
  int get playbackPosition => _playbackPosition;

  // 设置播放列表
  void setPlaylist(List<Song> songs) {
    _playlist = songs;
    notifyListeners();
  }

  // 清空播放列表
  void clearPlaylist() {
    _playlist = [];
    _currentSongIndex = -1;
    _lyricsModel = null;
    notifyListeners();
  }

  // 从播放列表中移除歌曲
  void removeSongFromPlaylist(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);

      // 如果移除的是当前播放的歌曲或之前的歌曲，需要调整当前索引
      if (index < _currentSongIndex) {
        _currentSongIndex--;
      } else if (index == _currentSongIndex) {
        // 如果移除的是当前播放的歌曲，停止播放
        _currentSongIndex = -1;
        _lyricsModel = null;
      }

      notifyListeners();
    }
  }

  // 添加歌曲到播放列表
  void addSongToPlaylist(Song song) {
    _playlist.add(song);
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

        // 加载歌词
        _lyricsModel = await LyricsService.loadLyrics(song);

        await _audioPlayer.play();

        // 保存播放状态
        _savePlaybackState();
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
      // 保存播放状态
      _savePlaybackState();
    }
  }

  // 暂停
  Future<void> pause() async {
    if (!_isInitialized) return;
    await _audioPlayer.pause();
    // 保存播放状态
    _savePlaybackState();
  }

  // 停止
  Future<void> stop() async {
    if (!_isInitialized) return;
    await _audioPlayer.stop();
    _currentSongIndex = -1;
    _lyricsModel = null;
    notifyListeners();
    // 保存播放状态
    _savePlaybackState();
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

    final prevIndex =
        (_currentSongIndex - 1 + _playlist.length) % _playlist.length;
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
    _playbackPosition = position.inMilliseconds;
    // 保存播放状态
    _savePlaybackState();
  }

  // 释放资源
  @override
  void dispose() {
    if (_isInitialized) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }
}
