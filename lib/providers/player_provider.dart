import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/lyrics_service.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerProvider with ChangeNotifier {
  // 音频播放器实例
  late final AudioPlayer _audioPlayer;

  // 播放列表
  List<Song> _playlist = [];

  // 音乐库列表（所有音乐）
  List<Song> _musicLibrary = [];

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

  // 用户信息
  String _userName = '用户';
  String _userAvatarPath = '';

  // 歌单显示模式：true为卡片，false为列表
  bool _playlistViewMode = true;

  // SharedPreferences实例
  late SharedPreferences _prefs;

  // 喜欢的歌曲集合
  Set<String> _favoriteSongs = {};

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
    await _loadFavoriteSongs();
    await _loadUserInfo();
    await _loadPlaylistViewMode();
    await _loadUserPlaylists();
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

  // 获取音乐库列表
  List<Song> get musicLibrary => _musicLibrary;

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

  // 检查歌曲是否喜欢
  bool isFavorite(String songId) => _favoriteSongs.contains(songId);
  
  Set<String> get favoriteSongs => _favoriteSongs;

  // 获取用户信息
  String get userName => _userName;
  String get userAvatarPath => _userAvatarPath;

  // 获取歌单显示模式
  bool get playlistViewMode => _playlistViewMode;

  // 歌单管理
  List<Map<String, dynamic>> _userPlaylists = [];

  // 获取用户歌单
  List<Map<String, dynamic>> get userPlaylists => _userPlaylists;

  // 设置播放列表
  void setPlaylist(List<Song> songs) {
    _playlist = songs;
    notifyListeners();
  }

  // 设置音乐库列表
  void setMusicLibrary(List<Song> songs) {
    _musicLibrary = songs;
    // 如果播放列表为空或与音乐库不同，初始化为音乐库
    if (_playlist.isEmpty || _playlist.length != _musicLibrary.length) {
      _playlist = List.from(songs);
    }
    notifyListeners();
  }

  // 更新歌曲信息
  void updateSongInfo(String songId, {String? title, String? artist, String? album, String? coverArtPath}) {
    // 更新音乐库中的歌曲
    final musicIndex = _musicLibrary.indexWhere((song) => song.id == songId);
    if (musicIndex != -1) {
      _musicLibrary[musicIndex] = _musicLibrary[musicIndex].copyWith(
        title: title,
        artist: artist,
        album: album,
        coverArtPath: coverArtPath,
      );
    }
    
    // 更新播放列表中的歌曲
    final playlistIndex = _playlist.indexWhere((song) => song.id == songId);
    if (playlistIndex != -1) {
      _playlist[playlistIndex] = _playlist[playlistIndex].copyWith(
        title: title,
        artist: artist,
        album: album,
        coverArtPath: coverArtPath,
      );
    }
    
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
    _saveSettings();
    notifyListeners();
  }

  // 保存设置到SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  // 设置用户信息
  void setUserInfo({String? userName, String? avatarPath}) {
    if (userName != null) _userName = userName;
    if (avatarPath != null) _userAvatarPath = avatarPath;
    _saveUserInfo();
    notifyListeners();
  }

  // 切换歌单显示模式
  void togglePlaylistViewMode() {
    _playlistViewMode = !_playlistViewMode;
    _savePlaylistViewMode();
    notifyListeners();
  }

  // 切换歌曲喜欢状态
  void toggleFavorite(String songId) {
    if (_favoriteSongs.contains(songId)) {
      _favoriteSongs.remove(songId);
    } else {
      _favoriteSongs.add(songId);
    }
    _saveFavoriteSongs();
    notifyListeners();
  }

  // 保存喜欢的歌曲到SharedPreferences
  Future<void> _saveFavoriteSongs() async {
    try {
      await _prefs.setStringList('favorite_songs', _favoriteSongs.toList());
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save favorite songs: $e');
      }
    }
  }

  // 从SharedPreferences加载喜欢的歌曲
  Future<void> _loadFavoriteSongs() async {
    try {
      final favoriteSongs = _prefs.getStringList('favorite_songs') ?? [];
      _favoriteSongs = favoriteSongs.toSet();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load favorite songs: $e');
      }
    }
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    if (!_isInitialized) return;
    await _audioPlayer.seek(position);
    _playbackPosition = position.inMilliseconds;
    // 保存播放状态
    _savePlaybackState();
  }

  // 保存用户信息到SharedPreferences
  Future<void> _saveUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_avatar_path', _userAvatarPath);
    } catch (e) {
      print('Failed to save user info: $e');
    }
  }

  // 从SharedPreferences加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name') ?? '用户';
      _userAvatarPath = prefs.getString('user_avatar_path') ?? '';
    } catch (e) {
      print('Failed to load user info: $e');
    }
  }

  // 保存歌单显示模式到SharedPreferences
  Future<void> _savePlaylistViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('playlist_view_mode', _playlistViewMode);
    } catch (e) {
      print('Failed to save playlist view mode: $e');
    }
  }

  // 从SharedPreferences加载歌单显示模式
  Future<void> _loadPlaylistViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _playlistViewMode = prefs.getBool('playlist_view_mode') ?? true; // 默认为卡片模式
    } catch (e) {
      print('Failed to load playlist view mode: $e');
    }
  }

  // 创建歌单
  void createPlaylist(String name) {
    final playlist = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'songs': <String>[],
      'created_at': DateTime.now().toIso8601String(),
    };
    _userPlaylists.add(playlist);
    _saveUserPlaylists();
    notifyListeners();
  }

  // 添加歌曲到用户歌单
  void addSongToUserPlaylist(String playlistId, String songId) {
    final playlistIndex = _userPlaylists.indexWhere((p) => p['id'] == playlistId);
    if (playlistIndex != -1) {
      final songs = List<String>.from(_userPlaylists[playlistIndex]['songs']);
      if (!songs.contains(songId)) {
        songs.add(songId);
        _userPlaylists[playlistIndex]['songs'] = songs;
        _saveUserPlaylists();
        notifyListeners();
      }
    }
  }

  // 从用户歌单移除歌曲
  void removeSongFromUserPlaylist(String playlistId, String songId) {
    final playlistIndex = _userPlaylists.indexWhere((p) => p['id'] == playlistId);
    if (playlistIndex != -1) {
      final songs = List<String>.from(_userPlaylists[playlistIndex]['songs']);
      songs.remove(songId);
      _userPlaylists[playlistIndex]['songs'] = songs;
      _saveUserPlaylists();
      notifyListeners();
    }
  }

  // 删除歌单
  void deletePlaylist(String playlistId) {
    _userPlaylists.removeWhere((p) => p['id'] == playlistId);
    _saveUserPlaylists();
    notifyListeners();
  }

  // 保存用户歌单到SharedPreferences
  Future<void> _saveUserPlaylists() async {
    try {
      final playlistsJson = _userPlaylists.map((p) => {
        'id': p['id'],
        'name': p['name'],
        'songs': p['songs'],
        'created_at': p['created_at'],
      }).toList();
      
      final playlistsString = playlistsJson.map((p) => p.toString()).join('|');
      await _prefs.setString('user_playlists', playlistsString);
    } catch (e) {
      print('Failed to save user playlists: $e');
    }
  }

  // 从SharedPreferences加载用户歌单
  Future<void> _loadUserPlaylists() async {
    try {
      final playlistsString = _prefs.getString('user_playlists') ?? '';
      if (playlistsString.isNotEmpty) {
        final playlistsParts = playlistsString.split('|');
        _userPlaylists = playlistsParts.map((part) {
          // 简单解析，实际应用中建议使用JSON
          final id = part.substring(part.indexOf('id: ') + 4, part.indexOf(','));
          final nameStart = part.indexOf('name: ') + 6;
          final nameEnd = part.indexOf(', songs:');
          final name = part.substring(nameStart, nameEnd);
          
          return {
            'id': id,
            'name': name,
            'songs': <String>[],
            'created_at': DateTime.now().toIso8601String(),
          };
        }).toList();
      }
    } catch (e) {
      print('Failed to load user playlists: $e');
      _userPlaylists = [];
    }
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
