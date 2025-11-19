import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../models/song.dart';
import 'settings_screen.dart';
import 'download_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePlaylists();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializePlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializePlaylists() {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final favoriteSongIds = playerProvider.favoriteSongs;
    
    final allSongs = playerProvider.musicLibrary;
    final favoriteSongs = allSongs.where((song) => favoriteSongIds.contains(song.id)).toList();
    
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
                  _initializePlaylists();
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
      backgroundColor: Colors.white,
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
    if (playlist.id == 'favorites') return;
    
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
                _initializePlaylists();
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
    
    final playlist = _playlists.firstWhere(
      (playlist) => playlist.songs.contains(song),
      orElse: () => Playlist(id: 'temp', name: 'temp', icon: Icons.music_note, color: Colors.blue, songs: [song])
    );
    final songIndex = playlist.songs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      playerProvider.playSong(songIndex);
    }
    
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 用户信息区域
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF60A5FA), // 天蓝色
                    Color(0xFF93C5FD), // 浅蓝色
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 顶部工具栏
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '我的',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
                        tooltip: '设置',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 用户头像和名字
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: playerProvider.userAvatarPath.isNotEmpty
                            ? ClipOval(
                                child: Image.file(
                                  File(playerProvider.userAvatarPath),
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 80,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Color(0xFF60A5FA),
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Color(0xFF60A5FA),
                              ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerProvider.userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '享受音乐的美好时光',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // 标签栏
            Container(
              color: Colors.white,
              child: Theme(
                data: Theme.of(context).copyWith(
                  indicatorColor: Colors.transparent,
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF60A5FA),
                  unselectedLabelColor: const Color(0xFF9CA3AF),
                  indicator: const BoxDecoration(), // 完全移除指示器
                  indicatorWeight: 0,
                  tabs: const [
                    Tab(text: '歌单'),
                    Tab(text: '下载'),
                  ],
                ),
              ),
            ),
            
            // 内容区域
            Expanded(
              child: Column(
                children: [
                  // 白色分隔线，消除黑线
                  Container(
                    height: 1,
                    color: Colors.white,
                  ),
                  // TabBarView内容
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 歌单页面
                        _buildPlaylistPage(),
                        // 下载页面
                        const DownloadScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistPage() {
    final playerProvider = Provider.of<PlayerProvider>(context);
    final isCardView = playerProvider.playlistViewMode;

    return Container(
      color: Colors.white,
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
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              // 切换显示模式按钮
              IconButton(
                onPressed: () {
                  playerProvider.togglePlaylistViewMode();
                },
                icon: Icon(
                  isCardView ? Icons.view_list : Icons.grid_view,
                  color: const Color(0xFF60A5FA),
                ),
                tooltip: isCardView ? '切换到列表视图' : '切换到卡片视图',
              ),
              IconButton(
                onPressed: _addNewPlaylist,
                icon: const Icon(Icons.add, color: Color(0xFF60A5FA)),
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
            elevation: 2,
            color: Colors.white,
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
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songs.length} 首歌曲',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: playlist.color,
              child: Icon(playlist.icon, color: Colors.white),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            subtitle: Text('${playlist.songs.length} 首歌曲', style: const TextStyle(color: Color(0xFF6B7280))),
            trailing: const Icon(Icons.play_arrow, color: Color(0xFF60A5FA)),
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
    
    final songIndex = _playlist.songs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      playerProvider.playSong(songIndex);
    }
    
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_playlist.name),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: _playlist.songs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 64,
                    color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无歌曲',
                    style: const TextStyle(fontSize: 18, color: Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从播放界面添加歌曲到歌单',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                                  color: const Color(0xFF60A5FA),
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
                              color: const Color(0xFF60A5FA),
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
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                  ),
                  subtitle: Text(song.artist, style: const TextStyle(color: Color(0xFF6B7280))),
                  trailing: const Icon(Icons.play_arrow, color: Color(0xFF60A5FA)),
                  onTap: () => _playSong(song),
                );
              },
            ),
    );
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