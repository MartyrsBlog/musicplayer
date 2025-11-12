import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/audio_manager.dart';
import 'music_library_screen.dart';
import 'music_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 修改默认索引为1（音乐标签页）
  late AudioManager _audioManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    _loadSongsAndRestoreState();
  }

  // 加载本地音乐文件并恢复播放状态
  void _loadSongsAndRestoreState() async {
    try {
      final songs = await _audioManager.scanLocalMusic();
      if (mounted) {
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        playerProvider.setPlaylist(songs);

        // 恢复播放状态
        await playerProvider.restorePlaybackState(songs);

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载音乐失败: $e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadSongsAndRestoreState,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐播放器'),
        actions: [
          IconButton(
            icon: Icon(
              playerProvider.isDarkMode
                  ? Icons.brightness_7
                  : Icons.brightness_4,
            ),
            onPressed: () {
              playerProvider.toggleDarkMode();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: '音乐库',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            label: '音乐',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const MusicLibraryScreen();
      case 1:
        return const MusicScreen();
      case 2:
        return const ProfileScreen();
      default:
        return const MusicLibraryScreen();
    }
  }

  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }
}
