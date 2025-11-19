import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/lyrics_service.dart';
import '../services/music_download_service.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'dart:io';

// 封面搜索结果类
class CoverSearchResult {
  final String id;
  final String name;
  final String singer;
  final String coverUrl;

  CoverSearchResult({
    required this.id,
    required this.name,
    required this.singer,
    required this.coverUrl,
  });
}

// 封面搜索对话框Widget
class _CoverSearchDialog extends StatefulWidget {
  final String? initialSearchQuery;
  final Function(String songId, String songName) onCoverSelected;

  const _CoverSearchDialog({
    this.initialSearchQuery,
    required this.onCoverSelected,
  });

  @override
  State<_CoverSearchDialog> createState() => _CoverSearchDialogState();
}

class _CoverSearchDialogState extends State<_CoverSearchDialog> {
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  List<CoverSearchResult> searchResults = [];
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    // 如果有初始搜索查询，自动填充并搜索
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      searchController.text = widget.initialSearchQuery!;
      // 延迟执行搜索，确保UI已经完全加载
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch();
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (searchController.text.trim().isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
      hasSearched = true;
    });

    try {
      final results = await MusicDownloadService.searchMusic(searchController.text.trim());
      final coverResults = <CoverSearchResult>[];
      
      print('开始获取 ${results.length} 首歌曲的封面信息，只取前4条');
      
      // 获取前4个搜索结果的封面信息
      for (final result in results.take(4)) {
        try {
          print('正在获取歌曲 ${result.name} 的下载信息...');
          final info = await MusicDownloadService.getDownloadInfo(result.id);
          if (info != null && info.pic != null && info.pic!.isNotEmpty) {
            print('找到封面: ${info.pic}');
            coverResults.add(CoverSearchResult(
              id: result.id,
              name: result.name,
              singer: result.singer,
              coverUrl: info.pic!,
            ));
          } else {
            print('歌曲 ${result.name} 没有封面信息');
          }
        } catch (e) {
          print('获取歌曲 ${result.name} 封面信息失败: $e');
        }
      }
      
      setState(() {
        searchResults = coverResults;
        isSearching = false;
      });
      
      print('搜索完成，找到 ${coverResults.length} 个封面');
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('搜索封面图'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // 搜索框
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '输入歌手名或歌曲名',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => searchController.clear(),
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            const SizedBox(height: 16),
            
            // 搜索按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSearching ? null : _performSearch,
                child: isSearching
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('搜索中...'),
                        ],
                      )
                    : const Text('搜索'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 搜索结果
            Expanded(
              child: !hasSearched
                  ? Center(
                      child: Text(
                        isSearching ? '正在搜索...' : '输入关键词开始搜索',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            '未找到相关封面',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final result = searchResults[index];
                            return Card(
                              elevation: 4,
                              child: InkWell(
                                onTap: () => widget.onCoverSelected(result.id, result.name),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 封面图片
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                          child: Image.network(
                                            result.coverUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Icon(Icons.album, size: 40, color: Colors.grey),
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 歌曲信息
                                    Expanded(
                                      flex: 1,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              result.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              result.singer,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

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

        // 控制按钮（喜欢、播放列表、更多选项）
        _buildSimpleControlButtons(playerProvider),

        const SizedBox(height: 20),

        // 进度条
        _buildProgressBar(playerProvider),
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

            // 底部控制区域 - 歌词界面不显示控制按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 进度条
                  _buildProgressBar(playerProvider),

                  const SizedBox(height: 20),
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
          return GestureDetector(
            onTap: () {
              // 点击歌词区域时显示简化的跳转选项
              _showLyricJumpDialog(context, playerProvider);
            },
            child: LyricsReader(
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

  // 显示歌词跳转对话框
  void _showLyricJumpDialog(BuildContext context, PlayerProvider playerProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('跳转到歌词位置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('点击下方按钮跳转到当前歌词位置'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // 跳转到当前歌词位置并开始播放
                      final currentPosition = playerProvider.lyricsPosition;
                      final position = Duration(milliseconds: currentPosition);
                      playerProvider.seek(position);
                      if (!playerProvider.isPlaying) {
                        playerProvider.togglePlayPause();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 40,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // 跳转到上一句歌词
                      _jumpToPreviousLyric(playerProvider);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 40,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // 跳转到下一句歌词
                      _jumpToNextLyric(playerProvider);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  // 跳转到上一句歌词
  void _jumpToPreviousLyric(PlayerProvider playerProvider) {
    final lyricsModel = playerProvider.lyricsModel;
    if (lyricsModel != null) {
      final lyrics = lyricsModel.lyrics;
      final currentPosition = playerProvider.lyricsPosition;
      
      // 找到当前歌词位置的前一句
      for (int i = lyrics.length - 1; i >= 0; i--) {
        final startTime = lyrics[i].startTime;
        if (startTime != null && startTime < currentPosition) {
          final position = Duration(milliseconds: startTime.toInt());
          playerProvider.seek(position);
          break;
        }
      }
    }
  }

  // 跳转到下一句歌词
  void _jumpToNextLyric(PlayerProvider playerProvider) {
    final lyricsModel = playerProvider.lyricsModel;
    if (lyricsModel != null) {
      final lyrics = lyricsModel.lyrics;
      final currentPosition = playerProvider.lyricsPosition;
      
      // 找到当前歌词位置的下一句
      for (int i = 0; i < lyrics.length; i++) {
        final startTime = lyrics[i].startTime;
        if (startTime != null && startTime > currentPosition) {
          final position = Duration(milliseconds: startTime.toInt());
          playerProvider.seek(position);
          break;
        }
      }
    }
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

  // 构建简单控制按钮
  Widget _buildSimpleControlButtons(PlayerProvider playerProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 喜欢按钮（左边）
          IconButton(
            iconSize: 40,
            onPressed: () {
              final currentSong = playerProvider.currentSong;
              if (currentSong != null) {
                final wasFavorite = playerProvider.isFavorite(currentSong.id);
                playerProvider.toggleFavorite(currentSong.id);
                
                // 显示提示信息
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      wasFavorite 
                          ? '已从"我的喜欢"中移除' 
                          : '已添加到"我的喜欢"',
                    ),
                    duration: const Duration(seconds: 2),
                    action: wasFavorite ? null : SnackBarAction(
                      label: '查看歌单',
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                );
              }
            },
            icon: Icon(
              Icons.favorite,
              color: () {
                final currentSong = playerProvider.currentSong;
                return currentSong != null && playerProvider.isFavorite(currentSong.id)
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurface;
              }(),
            ),
          ),

          // 播放列表按钮（中间）
          IconButton(
            iconSize: 40,
            onPressed: () {
              _showPlaylistBottomSheet(context, playerProvider);
            },
            icon: Icon(
              Icons.playlist_play,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // 更多选项按钮（右边）
          IconButton(
            iconSize: 40,
            onPressed: () {
              _showMoreOptions(context, playerProvider);
            },
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // 显示更多选项
  void _showMoreOptions(BuildContext context, PlayerProvider playerProvider) {
    final currentSong = playerProvider.currentSong;
    if (currentSong == null) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '更多选项',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 平衡布局
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 选项列表
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('添加进歌单'),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaylistSelection(context, playerProvider, currentSong);
                },
              ),
            ],
          ),
        );
      },
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

  // 搜索歌词
  void _searchLyrics(Song song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('搜索歌词 - ${song.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('正在搜索 ${song.title} 的歌词...'),
            ],
          ),
        );
      },
    );

    // 调用下载歌词功能
    _downloadLyricsForSong(song);
  }

  // 搜索封面图
  void _searchCoverArt(Song song) {
    // 复用音乐标签界面中的网络搜索功能
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CoverSearchDialog(
          initialSearchQuery: song.title,
          onCoverSelected: (songId, songName) {
            Navigator.pop(context);
            _downloadAndSetCoverForSong(songId, songName);
          },
        );
      },
    );
  }

  // 下载歌词功能
  void _downloadLyricsForSong(Song song) async {
    try {
      // 获取下载信息
      final info = await MusicDownloadService.getDownloadInfo('dummy_id');
      if (info == null) {
        // 如果无法通过ID获取，尝试通过歌曲标题搜索
        final searchResults = await MusicDownloadService.searchMusic(song.title);
        if (searchResults.isNotEmpty) {
          final firstResult = searchResults.first;
          final downloadInfo = await MusicDownloadService.getDownloadInfo(firstResult.id);
          if (downloadInfo != null && downloadInfo.lkid.isNotEmpty) {
            final lyricsDir = await MusicDownloadService.getLyricsDownloadDirectory();
            final success = await MusicDownloadService.downloadLyrics(
              downloadInfo.lkid,
              song.title,
              lyricsDir,
            );
            
            Navigator.pop(context); // 关闭加载对话框
            
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('歌词下载成功'),
                  backgroundColor: Colors.green,
                ),
              );
              // 重新加载歌词
              final lyricsModel = await LyricsService.loadLyrics(song);
              // 这里需要更新PlayerProvider中的歌词
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('歌词下载失败'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      Navigator.pop(context); // 关闭加载对话框
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('搜索歌词失败: $e')),
      );
    }
  }

  // 下载并设置封面功能
  void _downloadAndSetCoverForSong(String songId, String songName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在下载封面图...'),
          ],
        ),
      ),
    );

    try {
      final info = await MusicDownloadService.getDownloadInfo(songId);
      if (info == null || info.pic == null || info.pic!.isEmpty) {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该歌曲没有可用的封面图')),
          );
        }
        return;
      }

      final tempDir = Directory.systemTemp;
      final coverPath = '${tempDir.path}/temp_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final success = await MusicDownloadService.downloadCoverArtDirect(
        info.pic!,
        songName,
        tempDir,
        coverPath,
      );

      Navigator.pop(context);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('封面图下载成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('封面图下载失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

// 格式化时间显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: song.coverArtPath != null
                                ? Image.file(
                                    File(song.coverArtPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: isCurrentSong
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.surface,
                                        child: Icon(
                                          isCurrentSong ? Icons.play_arrow : Icons.music_note,
                                          color: isCurrentSong
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurface,
                                          size: 20,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: isCurrentSong
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.surface,
                                    child: Icon(
                                      isCurrentSong ? Icons.play_arrow : Icons.music_note,
                                      color: isCurrentSong
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                  ),
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
