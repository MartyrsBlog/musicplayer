import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../models/song.dart';
import 'settings_screen.dart';
import '../services/music_download_service.dart';
import 'download_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Playlist> _playlists = [];
  late ScrollController _scrollController;
  bool _isScrolled = false;
  late AnimationController _animationController;
  late Animation<double> _avatarAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _avatarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializePlaylists();
    
    // 监听滚动事件
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听Provider变化，实时更新歌单
    _initializePlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _initializePlaylists() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final favoriteSongIds = playerProvider.favoriteSongs;
    
    // 获取所有歌曲并筛选喜欢的歌曲
    final allSongs = playerProvider.musicLibrary;
    final favoriteSongs = allSongs.where((song) => favoriteSongIds.contains(song.id)).toList();
    
    // 获取用户创建的歌单
    final userPlaylists = playerProvider.userPlaylists.map((playlist) {
      final playlistSongs = allSongs.where((song) => 
        playlist['songs'].contains(song.id)
      ).toList();
      
      return Playlist(
        id: playlist['id'],
        name: playlist['name'],
        icon: Icons.playlist_play,
        color: Colors.blue,
        songs: playlistSongs,
      );
    }).toList();
    
    setState(() {
      _playlists = [
        Playlist(
          id: 'favorites',
          name: '我的喜欢',
          icon: Icons.favorite,
          color: Colors.red,
          songs: favoriteSongs,
        ),
        ...userPlaylists,
      ];
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final scrollOffset = _scrollController.offset;
      final shouldScroll = scrollOffset > 200; // 当滚动超过200像素时触发
      
      if (shouldScroll != _isScrolled) {
        setState(() {
          _isScrolled = shouldScroll;
        });
        
        if (_isScrolled) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    }
  }

  void _addNewPlaylist() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        String playlistName = '';
        return AlertDialog(
          title: const Text('创建新歌单'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: '歌单名称',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              playlistName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (playlistName.isNotEmpty) {
                  playerProvider.createPlaylist(playlistName);
                  Navigator.pop(context);
                  _initializePlaylists(); // 重新加载歌单列表
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('歌单创建成功')),
                  );
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  void _showPlaylistOptions(Playlist playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(playlist.icon, color: playlist.color),
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length} 首歌曲'),
              ),
              const Divider(),
              if (playlist.id != 'favorites')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑歌单'),
                  onTap: () {
                    Navigator.pop(context);
                    _editPlaylist(playlist);
                  },
                ),
              if (playlist.id != 'favorites')
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('删除歌单'),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePlaylist(playlist);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _editPlaylist(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = playlist.name;
        return AlertDialog(
          title: const Text('编辑歌单'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: '歌单名称',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: playlist.name),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    final index = _playlists.indexOf(playlist);
                    _playlists[index] = playlist.copyWith(name: newName);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _deletePlaylist(Playlist playlist) {
    if (playlist.id == 'favorites') return; // 不能删除"我的喜欢"
    
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除歌单'),
          content: Text('确定要删除歌单"${playlist.name}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                playerProvider.deletePlaylist(playlist.id);
                Navigator.pop(context);
                _initializePlaylists(); // 重新加载歌单列表
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('歌单已删除')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _playSong(Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.setPlaylist(_playlists.firstWhere(
      (playlist) => playlist.songs.contains(song),
      orElse: () => Playlist(id: 'temp', name: 'temp', icon: Icons.music_note, color: Colors.blue, songs: [song])
    ).songs);
    
    // 找到歌曲在播放列表中的索引
    final playlist = _playlists.firstWhere(
      (playlist) => playlist.songs.contains(song),
      orElse: () => Playlist(id: 'temp', name: 'temp', icon: Icons.music_note, color: Colors.blue, songs: [song])
    );
    final songIndex = playlist.songs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      playerProvider.playSong(songIndex);
    }
    
    // 直接播放，不进入独立界面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在播放: ${song.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 可折叠的AppBar
          SliverAppBar(
            expandedHeight: 350,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: AnimatedBuilder(
              animation: _avatarAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _avatarAnimation.value,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: playerProvider.userAvatarPath.isNotEmpty
                        ? ClipOval(
                            child: Image.file(
                              File(playerProvider.userAvatarPath),
                              fit: BoxFit.cover,
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                );
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                margin: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 8,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: playerProvider.userAvatarPath.isNotEmpty
                              ? ClipOval(
                                  child: Image.file(
                                    File(playerProvider.userAvatarPath),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          playerProvider.userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '享受音乐的美好时光',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          playerProvider.isDarkMode ? '夜间模式已开启' : '夜间模式已关闭',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // 右上角设置入口 - 始终显示
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                tooltip: '设置',
              ),
            ],
          ),
          
          // 标签栏
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.playlist_play),
                    text: '歌单',
                  ),
                  Tab(
                    icon: Icon(Icons.download),
                    text: '下载',
                  ),
                ],
              ),
            ),
            pinned: true,
          ),
          
          // 页面内容
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 歌单页面
                _buildPlaylistPage(),
                // 下载页面
                _buildDownloadPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistPage() {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final isCardView = playerProvider.playlistViewMode;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 歌单列表头部
          Row(
            children: [
              const Text(
                '我的歌单',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 切换显示模式按钮
              IconButton(
                onPressed: () {
                  playerProvider.togglePlaylistViewMode();
                },
                icon: Icon(isCardView ? Icons.view_list : Icons.grid_view),
                tooltip: isCardView ? '切换到列表视图' : '切换到卡片视图',
              ),
              IconButton(
                onPressed: _addNewPlaylist,
                icon: const Icon(Icons.add),
                tooltip: '创建新歌单',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 歌单显示区域
          Expanded(
            child: isCardView ? _buildCardView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  // 卡片视图
  Widget _buildCardView() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailScreen(
                  playlist: playlist,
                  onPlaylistUpdate: (updatedPlaylist) {
                    setState(() {
                      final playlistIndex = _playlists.indexOf(playlist);
                      _playlists[playlistIndex] = updatedPlaylist;
                    });
                  },
                ),
              ),
            );
          },
          onLongPress: () => _showPlaylistOptions(playlist),
          child: Card(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    playlist.icon,
                    size: 48,
                    color: playlist.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songs.length} 首歌曲',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 列表视图
  Widget _buildListView() {
    return ListView.builder(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: playlist.color,
              child: Icon(
                playlist.icon,
                color: Colors.white,
              ),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${playlist.songs.length} 首歌曲'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistDetailScreen(
                    playlist: playlist,
                    onPlaylistUpdate: (updatedPlaylist) {
                      setState(() {
                        final playlistIndex = _playlists.indexOf(playlist);
                        _playlists[playlistIndex] = updatedPlaylist;
                      });
                    },
                  ),
                ),
              );
            },
            onLongPress: () => _showPlaylistOptions(playlist),
          ),
        );
      },
    );
  }

  Widget _buildDownloadPage() {
    return const DownloadScreen();
  }
}

// 歌单详情页面
class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final Function(Playlist) onPlaylistUpdate;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.onPlaylistUpdate,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late Playlist _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  void _playSong(Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.setPlaylist(_playlist.songs);
    
    // 找到歌曲在播放列表中的索引
    final songIndex = _playlist.songs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      playerProvider.playSong(songIndex);
    }
    
    // 显示简短的播放提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在播放: ${song.title}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_playlist.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _playlist.songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无歌曲',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从播放界面添加歌曲到歌单',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _playlist.songs.length,
              itemBuilder: (context, index) {
                final song = _playlist.songs[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.coverArtPath != null
                          ? Image.file(
                              File(song.coverArtPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Theme.of(context).primaryColor,
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Theme.of(context).primaryColor,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(song.artist),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => _playSong(song),
                );
              },
            ),
    );
  }
}

// SliverAppBarDelegate 用于固定TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// 歌单数据模型
class Playlist {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.songs,
  });

  Playlist copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      songs: songs ?? this.songs,
    );
  }
}