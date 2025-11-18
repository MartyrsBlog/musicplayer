import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final playlist = playerProvider.playlist;
    final currentSongIndex = playerProvider.currentSongIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放列表'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              _showClearPlaylistDialog(context, playerProvider);
            },
          ),
        ],
      ),
      body: playlist.isEmpty
          ? const Center(
              child: Text(
                '播放列表为空',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                final song = playlist[index];
                final isCurrentSong = index == currentSongIndex;

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          _removeSongFromPlaylist(context, playerProvider, index);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    playerProvider.playSong(index);
                  },
                  onLongPress: () {
                    _showSongOptionsDialog(context, playerProvider, index);
                  },
                );
              },
            ),
    );
  }

  // 显示清除播放列表确认对话框
  void _showClearPlaylistDialog(BuildContext context, PlayerProvider playerProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除播放列表'),
          content: const Text('确定要清除整个播放列表吗？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                playerProvider.clearPlaylist();
                Navigator.pop(context);
                Navigator.pop(context); // 关闭播放列表界面
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 从播放列表中移除歌曲
  void _removeSongFromPlaylist(BuildContext context, PlayerProvider playerProvider, int index) {
    playerProvider.removeSongFromPlaylist(index);
  }

  // 显示歌曲选项对话框
  void _showSongOptionsDialog(BuildContext context, PlayerProvider playerProvider, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('歌曲选项'),
          content: const Text('选择操作'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                playerProvider.removeSongFromPlaylist(index);
                Navigator.pop(context);
              },
              child: const Text('从播放列表中移除'),
            ),
          ],
        );
      },
    );
  }
}