import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../models/song.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // 当前歌词行
  int _currentLyricLine = 0;

  @override
  void initState() {
    super.initState();
    // 监听播放进度以同步歌词
    _listenToPositionChanges();
  }

  // 监听播放位置变化以同步歌词
  void _listenToPositionChanges() {
    try {
      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
      
      playerProvider.audioPlayer.positionStream.listen((position) {
        // 这里应该更新歌词位置，但因为我们没有实际的歌词文件，所以暂时留空
        // 在实际应用中，这里会根据播放位置更新当前歌词行
      }, onError: (Object error) {
        // 处理流错误
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('播放位置监听出错')),
          );
        }
      });
    } catch (e) {
      // 处理获取播放器实例时的错误
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法初始化播放器监听')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: const Text('正在播放'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentSong == null
          ? const Center(child: Text('没有正在播放的歌曲'))
          : Column(
              children: [
                // 专辑封面
                _buildAlbumArt(currentSong),
                
                // 歌曲信息
                _buildSongInfo(currentSong),
                
                // 歌词显示
                _buildLyricsSection(),
                
                // 进度条
                _buildProgressBar(playerProvider),
                
                // 控制按钮
                _buildControlButtons(playerProvider),
              ],
            ),
    );
  }

  // 构建专辑封面
  Widget _buildAlbumArt(Song song) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: song.coverArtPath != null
              ? Image.file(
                  File(song.coverArtPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.album, size: 100);
                  },
                )
              : const Icon(Icons.album, size: 100),
        ),
      ),
    );
  }

  // 构建歌曲信息
  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            song.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${song.artist} - ${song.album}',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 构建歌词部分
  Widget _buildLyricsSection() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 这里是歌词显示区域
                // 在实际应用中，这里会显示解析后的歌词内容
                const Text(
                  '暂无歌词',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                // 示例歌词行（实际应用中会从歌词文件解析）
                const Text(
                  '这是示例行1',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  '这是示例行2',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                const Text(
                  '这是示例行3',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建进度条
  Widget _buildProgressBar(PlayerProvider playerProvider) {
    try {
      return StreamBuilder<Duration?>(
        stream: playerProvider.audioPlayer.durationStream,
        builder: (context, snapshot) {
          final duration = snapshot.data ?? Duration.zero;
          return StreamBuilder<Duration?>(
            stream: playerProvider.audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Column(
                children: [
                  Slider(
                    value: duration.inMilliseconds == 0
                        ? 0
                        : (position.inMilliseconds /
                                duration.inMilliseconds)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                    onChanged: (value) {
                      final newPosition = duration * value;
                      playerProvider.seek(newPosition);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position)),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      // 处理流构建错误
      return Column(
        children: [
          const Slider(value: 0, onChanged: null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('0:00'),
                Text('0:00'),
              ],
            ),
          ),
        ],
      );
    }
  }

  // 构建控制按钮
  Widget _buildControlButtons(PlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 上一首按钮
          IconButton(
            iconSize: 40,
            onPressed: playerProvider.playPrevious,
            icon: const Icon(Icons.skip_previous),
          ),
          
          // 播放/暂停按钮
          IconButton(
            iconSize: 60,
            onPressed: playerProvider.togglePlayPause,
            icon: Icon(
              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          
          // 下一首按钮
          IconButton(
            iconSize: 40,
            onPressed: playerProvider.playNext,
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    );
  }

  // 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }
}