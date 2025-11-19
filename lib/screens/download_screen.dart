import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../services/music_download_service.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SongSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isDownloading = false;
  String _downloadStatus = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 检查Android存储权限
  Future<bool> _checkAndroidPermissions() async {
    try {
      // Android 13+ (API 33+) 需要媒体权限
      final audioPermission = await Permission.audio.request();
      if (audioPermission.isGranted) {
        return true;
      }
      
      // 尝试存储权限
      final storagePermission = await Permission.storage.request();
      if (storagePermission.isGranted) {
        return true;
      }
      
      // 最后尝试管理外部存储权限
      final managePermission = await Permission.manageExternalStorage.request();
      return managePermission.isGranted;
    } catch (e) {
      print('权限检查失败: $e');
      return false;
    }
  }

  Future<void> _searchMusic() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await MusicDownloadService.searchMusic(_searchController.text);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
  }

  Future<void> _downloadSong(SongSearchResult song, {bool downloadLyricsOnly = false}) async {
    // 检查Android权限
    if (Theme.of(context).platform == TargetPlatform.android) {
      final hasPermission = await _checkAndroidPermissions();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要存储权限才能下载音乐'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isDownloading = true;
      _downloadStatus = '正在下载 ${song.name}...';
    });

    try {
      final downloadDir = await MusicDownloadService.getDownloadDirectory();
      bool success = false;

      if (downloadLyricsOnly) {
        final info = await MusicDownloadService.getDownloadInfo(song.id);
        if (info != null) {
          success = await MusicDownloadService.downloadLyrics(info.lkid, info.title, downloadDir);
        }
      } else {
        success = await MusicDownloadService.downloadMusic(song.id, downloadDir);
      }

      setState(() {
        _isDownloading = false;
        _downloadStatus = success ? '下载完成' : '下载失败';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '下载完成' : '下载失败'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadStatus = '下载出错';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载出错: $e')),
        );
      }
    }
  }

  

  void _showDownloadOptions(SongSearchResult song) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${song.singer} - ${song.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('下载歌曲'),
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lyrics),
                title: const Text('下载歌词'),
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadSong(song, downloadLyricsOnly: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('下载歌曲和歌词'),
                onTap: () {
                  Navigator.of(context).pop();
                  _downloadSong(song);
                },
              ),
              
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 设置为白色背景
      body: SafeArea(
        child: Column(
        children: [
          // 搜索区域 - 使用Expanded包装
          Expanded(
            flex: 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, right: 16.0, bottom: 16.0), // 添加顶部padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 搜索框
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '搜索音乐',
                      hintText: '输入歌手名或歌曲名',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF60A5FA)), // 天蓝色搜索图标
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)), // 灰色清除图标
                        onPressed: () => _searchController.clear(),
                      ),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF60A5FA)), // 天蓝色聚焦边框
                      ),
                      isDense: true, // 使输入框更紧凑
                    ),
                    onSubmitted: (_) => _searchMusic(),
                  ),
                  const SizedBox(height: 12),
                  
                  // 搜索按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA), // 天蓝色背景
                        foregroundColor: Colors.white, // 白色文字
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSearching ? null : _searchMusic,
                      child: _isSearching
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
                  
                  // 下载状态
                  if (_isDownloading) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF424242),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _downloadStatus,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // 搜索结果 - 使用Expanded确保占用剩余空间
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _isSearching ? '搜索中...' : '暂无搜索结果',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final song = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
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
                            song.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(song.singer),
                          trailing: const Icon(Icons.download),
                          onTap: () => _showDownloadOptions(song),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}