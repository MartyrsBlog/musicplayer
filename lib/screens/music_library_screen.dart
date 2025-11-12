import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/audio_manager.dart';
import '../models/song.dart';
import 'dart:io';

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
                    // 只播放歌曲，不再跳转到独立的播放界面
                    playerProvider.playSong(index);
                  },
                  onLongPress: () {
                    // 长按显示选项菜单
                    _showSongOptions(context, playerProvider, song, index);
                  },
                );
              },
            ),
    );
  }

  // 显示歌曲选项菜单
  void _showSongOptions(BuildContext context, PlayerProvider playerProvider, Song song, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('播放歌曲'),
                onTap: () {
                  Navigator.pop(context);
                  playerProvider.playSong(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('添加到播放列表'),
                onTap: () {
                  Navigator.pop(context);
                  playerProvider.addSongToPlaylist(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加到播放列表')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
