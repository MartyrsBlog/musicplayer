import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'dart:io';

// 自定义歌词UI样式类
class CustomLyricUI extends LyricUI {
  final BuildContext context;

  CustomLyricUI(this.context);

  @override
  TextStyle getPlayingMainTextStyle() => TextStyle(
    color: Theme.of(context).colorScheme.primary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  TextStyle getOtherMainTextStyle() => TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    fontSize: 16,
  );

  @override
  TextStyle getPlayingExtTextStyle() =>
      TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16);

  @override
  TextStyle getOtherExtTextStyle() => TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    fontSize: 14,
  );

  @override
  double getLineSpace() => 20;

  @override
  double getInlineSpace() => 10;

  @override
  bool enableHighlight() => false; // 禁用逐字高亮，改为整行高亮

  @override
  HighlightDirection getHighlightDirection() => HighlightDirection.LTR;

  @override
  LyricAlign getLyricHorizontalAlign() => LyricAlign.CENTER;

  @override
  double getPlayingLineBias() => 0.5;

  @override
  LyricBaseLine getBiasBaseLine() => LyricBaseLine.CENTER;
}

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with TickerProviderStateMixin {
  // 控制显示专辑封面还是歌词界面的状态
  bool _showLyricsScreen = false;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 切换显示专辑封面和歌词界面
  void _toggleLyricsScreen() {
    setState(() {
      _showLyricsScreen = !_showLyricsScreen;
      if (_showLyricsScreen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final currentSong = playerProvider.currentSong;

    return Scaffold(
      body: currentSong == null
          ? const Center(child: Text('没有正在播放的歌曲'))
          : Stack(
              children: [
                // 主要内容（专辑封面界面）
                AnimatedOpacity(
                  opacity: _showLyricsScreen ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: _buildMainContent(currentSong, playerProvider),
                ),

                // 歌词界面（覆盖在主要内容之上）
                if (_showLyricsScreen)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildLyricsScreen(currentSong, playerProvider),
                  ),
              ],
            ),
    );
  }

  // 构建主要内容（专辑封面界面）
  Widget _buildMainContent(Song song, PlayerProvider playerProvider) {
    return Column(
      children: [
        // 专辑封面区域
        _buildAlbumArtArea(song),

        // 歌曲信息
        _buildSongInfo(song, context),

        // 进度条
        _buildProgressBar(playerProvider),

        // 控制按钮
        _buildControlButtons(playerProvider),
      ],
    );
  }

  // 构建专辑封面区域
  Widget _buildAlbumArtArea(Song song) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 专辑封面
                GestureDetector(
                  onTap: _toggleLyricsScreen,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                                return Icon(
                                  Icons.album,
                                  size: 100,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                );
                              },
                            )
                          : Icon(
                              Icons.album,
                              size: 100,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 切换到歌词界面的提示按钮
                ElevatedButton.icon(
                  onPressed: _toggleLyricsScreen,
                  icon: Icon(
                    Icons.lyrics,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text('查看歌词'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建歌词界面
  Widget _buildLyricsScreen(Song song, PlayerProvider playerProvider) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部工具栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: _toggleLyricsScreen,
                  ),

                  // 歌曲标题
                  Expanded(
                    child: Text(
                      song.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 占位符（保持布局平衡）
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 歌词显示区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildLyricsContent(playerProvider),
              ),
            ),

            // 底部控制区域
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 进度条
                  _buildProgressBar(playerProvider),

                  const SizedBox(height: 20),

                  // 控制按钮
                  _buildControlButtons(playerProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建歌词内容
  Widget _buildLyricsContent(PlayerProvider playerProvider) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final lyricsModel = provider.lyricsModel;

        // 创建自定义的歌词UI样式
        final lyricUI = CustomLyricUI(context);

        // 如果有歌词则显示歌词阅读器，否则显示默认文本
        if (lyricsModel != null) {
          return LyricsReader(
            model: lyricsModel,
            position: provider.lyricsPosition,
            lyricUi: lyricUI,
            playing: provider.isPlaying,
            size: Size(double.infinity, MediaQuery.of(context).size.height),
            emptyBuilder: () => Center(
              child: Text(
                '暂无歌词',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        } else {
          return Center(
            child: Text(
              '暂无歌词',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          );
        }
      },
    );
  }

  // 构建歌曲信息
  Widget _buildSongInfo(Song song, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Text(
            song.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${song.artist} - ${song.album}',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                        : (position.inMilliseconds / duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                    onChanged: (value) {
                      final newPosition = duration * value;
                      playerProvider.seek(newPosition);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
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
          Slider(
            value: 0,
            onChanged: null,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0:00',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  '0:00',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
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
          // 播放列表按钮
          IconButton(
            iconSize: 40,
            onPressed: () {
              // 显示播放列表BottomSheet
              _showPlaylistBottomSheet(context, playerProvider);
            },
            icon: Icon(
              Icons.playlist_play,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // 上一首按钮
          IconButton(
            iconSize: 40,
            onPressed: playerProvider.playPrevious,
            icon: Icon(
              Icons.skip_previous,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // 播放/暂停按钮
          IconButton(
            iconSize: 60,
            onPressed: playerProvider.togglePlayPause,
            icon: Icon(
              playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // 下一首按钮
          IconButton(
            iconSize: 40,
            onPressed: playerProvider.playNext,
            icon: Icon(
              Icons.skip_next,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // 更多选项按钮
          IconButton(
            iconSize: 40,
            onPressed: () {
              // 可以在这里添加更多选项
            },
            icon: Icon(
              Icons.more_horiz,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // 显示播放列表BottomSheet
  void _showPlaylistBottomSheet(
    BuildContext context,
    PlayerProvider playerProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return PlaylistBottomSheet(
              playerProvider: playerProvider,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  // 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// 带动画效果的播放/暂停按钮
class _PlayPauseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(35),
      ),
      child: IconButton(
        iconSize: 40,
        onPressed: playerProvider.togglePlayPause,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
            key: ValueKey(playerProvider.isPlaying),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

// 播放列表BottomSheet组件
class PlaylistBottomSheet extends StatelessWidget {
  final PlayerProvider playerProvider;
  final ScrollController? scrollController;

  const PlaylistBottomSheet({
    super.key,
    required this.playerProvider,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final playlist = playerProvider.playlist;
    final currentSongIndex = playerProvider.currentSongIndex;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '播放列表 (${playlist.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // 歌曲列表
          Expanded(
            child: playlist.isEmpty
                ? Center(
                    child: Text(
                      '播放列表为空',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isCurrentSong = index == currentSongIndex;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrentSong
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isCurrentSong ? Icons.play_arrow : Icons.music_note,
                            color: isCurrentSong
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            fontWeight: isCurrentSong
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentSong
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          // 只播放歌曲，不关闭播放列表
                          playerProvider.playSong(index);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
