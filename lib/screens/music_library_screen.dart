import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/audio_manager.dart';
import '../models/song.dart';
import 'music_tags_screen.dart';
import 'dart:io';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  bool _isScanning = false;

  Future<void> _refreshMusicLibrary() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final audioManager = AudioManager();
      final songs = await audioManager.scanLocalMusic();
      
      if (mounted) {
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        playerProvider.setMusicLibrary(songs);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描完成，找到 ${songs.length} 首歌曲')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描音乐失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final songs = playerProvider.musicLibrary;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: _isScanning 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _refreshMusicLibrary,
            tooltip: '刷新音乐库',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMusicLibrary,
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
                    onPressed: _isScanning ? null : _refreshMusicLibrary,
                    child: _isScanning 
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('扫描中...'),
                            ],
                          )
                        : const Text('扫描音乐'),
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
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${song.artist} - ${song.album}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'add_to_playlist') {
                        _showPlaylistSelection(context, playerProvider, song);
                      } else if (value == 'play') {
                        // 确保播放列表为音乐库
                        playerProvider.setPlaylist(playerProvider.musicLibrary);
                        playerProvider.playSong(index);
                      } else if (value == 'edit_tags') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MusicTagsScreen(song: song),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'play',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('播放歌曲'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'add_to_playlist',
                        child: Row(
                          children: [
                            Icon(Icons.playlist_add),
                            SizedBox(width: 8),
                            Text('添加进歌单'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'edit_tags',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('音乐标签'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // 只播放歌曲，不再跳转到独立的播放界面
                    // 确保播放列表为音乐库
                    playerProvider.setPlaylist(playerProvider.musicLibrary);
                    playerProvider.playSong(index);
                  },
                );
              },
            ),
      ),
    );
  }

  // 显示歌单选择对话框
  void _showPlaylistSelection(BuildContext context, PlayerProvider playerProvider, Song song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择歌单'),
          content: SizedBox(
            width: double.maxFinite,
            child: playerProvider.userPlaylists.isEmpty
                ? const Center(
                    child: Text('暂无歌单，请先创建歌单'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: playerProvider.userPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = playerProvider.userPlaylists[index];
                      return ListTile(
                        leading: const Icon(Icons.playlist_play),
                        title: Text(playlist['name']),
                        subtitle: Text('${playlist['songs'].length} 首歌曲'),
                        onTap: () {
                          playerProvider.addSongToUserPlaylist(playlist['id'], song.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已添加到 "${playlist['name']}"')),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCreatePlaylistDialog(context, playerProvider, song);
              },
              child: const Text('创建新歌单'),
            ),
          ],
        );
      },
    );
  }

  // 显示创建歌单对话框
  void _showCreatePlaylistDialog(BuildContext context, PlayerProvider playerProvider, Song song) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建新歌单'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '歌单名称',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  playerProvider.createPlaylist(name);
                  Navigator.pop(context);
                  // 创建后立即显示歌单选择
                  _showPlaylistSelection(context, playerProvider, song);
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }
}
