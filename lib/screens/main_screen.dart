import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import 'player_screen.dart';
import 'settings_screen.dart';
import '../services/audio_manager.dart';
import '../models/song.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late AudioManager _audioManager;

  @override
  void initState() {
    super.initState();
    _audioManager = AudioManager();
    _loadSongs();
  }

  // 加载本地音乐文件
  void _loadSongs() async {
    try {
      final songs = await _audioManager.scanLocalMusic();
      if (mounted) {
        Provider.of<PlayerProvider>(context, listen: false).setPlaylist(songs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载音乐失败: $e'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadSongs,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐播放器'),
        actions: [
          IconButton(
            icon: Icon(
              playerProvider.isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: '音乐库',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: playerProvider.currentSong != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayerScreen(),
                  ),
                );
              },
              child: const Icon(Icons.play_arrow),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const MusicLibraryScreen();
      case 1:
        return const SettingsScreen();
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

class MusicLibraryScreen extends StatelessWidget {
  const MusicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final songs = playerProvider.playlist;

    return RefreshIndicator(
      onRefresh: () async {
        final audioManager = AudioManager();
        try {
          final songs = await audioManager.scanLocalMusic();
          playerProvider.setPlaylist(songs);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('扫描音乐失败: $e')),
            );
          }
        }
      },
      child: songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.music_note, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    '暂无音乐文件',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // 在桌面平台提供不同的提示信息
                  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                    const Text(
                      '请确保您的主目录下有 Music 文件夹并包含音乐文件',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                    const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // 手动触发扫描
                      final audioManager = AudioManager();
                      audioManager.scanLocalMusic().then((songs) {
                        playerProvider.setPlaylist(songs);
                      }).catchError((error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('扫描音乐失败: $error')),
                          );
                        }
                      });
                    },
                    child: const Text('扫描音乐'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isCurrentSong = playerProvider.currentSongIndex == index;

                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCurrentSong ? Icons.play_arrow : Icons.music_note,
                      color: Colors.grey[800],
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text('${song.artist} - ${song.album}'),
                  trailing: Text(
                    '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  ),
                  onTap: () {
                    playerProvider.playSong(index);
                    // 跳转到播放界面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PlayerScreen(),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}