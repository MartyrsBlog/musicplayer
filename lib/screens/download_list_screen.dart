import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/music_download_service.dart';
import 'music_screen.dart';
import 'download_screen.dart';

class DownloadListScreen extends StatefulWidget {
  const DownloadListScreen({super.key});

  @override
  State<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends State<DownloadListScreen> {
  List<Song> _downloadedSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedSongs();
  }

  void _loadDownloadedSongs() async {
    try {
      final downloadDir = await MusicDownloadService.getDownloadDirectory();
      final files = await downloadDir.list().toList();
      
      List<Song> songs = [];
      for (final file in files) {
        if (file is File && _isAudioFile(file.path)) {
          final song = _createSongFromFile(file);
          if (song != null) {
            songs.add(song);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _downloadedSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载下载列表失败: $e')),
        );
      }
    }
  }

  bool _isAudioFile(String filePath) {
    final audioExtensions = ['.mp3', '.flac', '.m4a', '.aac', '.wav', '.ogg'];
    return audioExtensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }

  Song? _createSongFromFile(File file) {
    try {
      final fileName = file.path.split('/').last;
      final nameWithoutExtension = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      
      // 简单的歌曲信息提取（实际应用中可以使用更复杂的元数据读取）
      return Song(
        id: file.path,
        title: nameWithoutExtension,
        artist: '未知艺术家',
        album: '未知专辑',
        filePath: file.path,
        duration: const Duration(seconds: 0), // 实际应用中应该读取真实时长
      );
    } catch (e) {
      print('创建歌曲对象失败: $e');
      return null;
    }
  }

  void _playSong(Song song) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.setPlaylist(_downloadedSongs);
    
    // 找到歌曲在播放列表中的索引
    final songIndex = _downloadedSongs.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      playerProvider.playSong(songIndex);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MusicScreen(),
      ),
    );
  }

  void _refreshDownloadList() {
    setState(() {
      _isLoading = true;
    });
    _loadDownloadedSongs();
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('下载新音乐'),
                subtitle: const Text('搜索并下载在线音乐'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadScreen(),
                    ),
                  ).then((_) => _refreshDownloadList());
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('打开下载文件夹'),
                subtitle: const Text('在文件管理器中查看下载文件'),
                onTap: () {
                  Navigator.pop(context);
                  _openDownloadFolder();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDownloadFolder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文件夹打开功能将在完整版本中实现')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('下载音乐'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _refreshDownloadList,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: _showDownloadOptions,
            icon: const Icon(Icons.more_vert),
            tooltip: '更多选项',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedSongs.isEmpty
              ? _buildEmptyState()
              : _buildSongList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无下载音乐',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角菜单开始下载音乐',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadScreen(),
                ),
              ).then((_) => _refreshDownloadList());
            },
            icon: const Icon(Icons.download),
            label: const Text('开始下载'),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    return Column(
      children: [
        // 统计信息
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            '共 ${_downloadedSongs.length} 首歌曲',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        
        // 歌曲列表
        Expanded(
          child: ListView.builder(
            itemCount: _downloadedSongs.length,
            itemBuilder: (context, index) {
              final song = _downloadedSongs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(song.artist),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _playSong(song),
                      icon: const Icon(Icons.play_arrow),
                      tooltip: '播放',
                    ),
                    IconButton(
                      onPressed: () {
                        _showSongOptions(song, index);
                      },
                      icon: const Icon(Icons.more_vert),
                      tooltip: '更多选项',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSongOptions(Song song, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('播放'),
                onTap: () {
                  Navigator.pop(context);
                  _playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('添加到我的喜欢'),
                onTap: () {
                  Navigator.pop(context);
                  _addToFavorites(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除文件'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSong(song, index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToFavorites(Song song) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已将"${song.title}"添加到我的喜欢')),
    );
  }

  void _deleteSong(Song song, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除歌曲'),
          content: Text('确定要删除"${song.title}"吗？此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final file = File(song.filePath);
                  if (await file.exists()) {
                    await file.delete();
                  }
                  
                  if (mounted) {
                    setState(() {
                      _downloadedSongs.removeAt(index);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('歌曲已删除')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('删除失败: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

