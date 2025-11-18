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
  int _currentIndex = 1; // 默认显示音乐页面
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
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // 如果点击的是音乐标签（索引1）
              if (index == 1) {
                // 检查当前页面是否是音乐标签栏
                if (_currentIndex == 1) {
                  // 如果已经在音乐页面，则播放/暂停音乐
                  playerProvider.togglePlayPause();
                  return; // 不切换页面
                } else {
                  // 如果不在音乐页面，则切换到音乐页面
                  setState(() {
                    _currentIndex = index;
                  });
                }
              } else {
                // 点击其他标签，正常切换页面
                setState(() {
                  _currentIndex = index;
                });
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: '音乐库',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: playerProvider.isPlaying 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                label: '', // 音乐标签不显示文字
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '我的',
              ),
            ],
          );
        },
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
        return const MusicScreen();
    }
  }
}