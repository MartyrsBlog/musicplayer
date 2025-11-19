import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';
import '../services/music_download_service.dart';

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

class MusicTagsScreen extends StatefulWidget {
  final Song song;

  const MusicTagsScreen({
    super.key,
    required this.song,
  });

  @override
  State<MusicTagsScreen> createState() => _MusicTagsScreenState();
}

class _MusicTagsScreenState extends State<MusicTagsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late File? _coverArtFile;
  bool _isSaving = false;
  String? _tempCoverPath; // 跟踪临时封面文件路径

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _albumController = TextEditingController(text: widget.song.album);
    _coverArtFile = widget.song.coverArtPath != null ? File(widget.song.coverArtPath!) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    
    // 清理临时文件
    if (_tempCoverPath != null) {
      MusicDownloadService.deleteTempFile(_tempCoverPath!);
    }
    
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final imagePath = result.files.first.path!;
        setState(() {
          _coverArtFile = File(imagePath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('封面已选择')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择封面失败: $e')),
      );
    }
  }

  void _showCoverOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('封面选项'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('从相册选取'),
                onTap: () {
                  Navigator.pop(context);
                  _pickCoverArt();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('网络搜索'),
                onTap: () {
                  Navigator.pop(context);
                  _showCoverSearchDialog();
                },
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

  // 显示封面搜索对话框
  void _showCoverSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CoverSearchDialog(
          initialSearchQuery: widget.song.title,
          onCoverSelected: (songId, songName) {
            Navigator.pop(context);
            _downloadAndSetCover(songId, songName);
          },
        );
      },
    );
  }

  // 下载并设置封面
  Future<void> _downloadAndSetCover(String songId, String songName) async {
    // 显示下载进度
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

    String? coverPath;
    
    try {
      // 获取下载信息
      final info = await MusicDownloadService.getDownloadInfo(songId);
      if (info == null || info.pic == null || info.pic!.isEmpty) {
        Navigator.pop(context); // 关闭进度对话框
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该歌曲没有可用的封面图')),
          );
        }
        return;
      }

      // 获取缓存目录中的临时封面路径
      coverPath = await MusicDownloadService.getTempCoverPath();

      // 下载封面图
      final success = await MusicDownloadService.downloadCoverArtDirect(
        info.pic!,
        songName,
        File(coverPath).parent,
        coverPath,
      );

      Navigator.pop(context); // 关闭进度对话框

      if (success && mounted) {
        setState(() {
          _coverArtFile = File(coverPath!);
          _tempCoverPath = coverPath!; // 保存临时文件路径以便后续清理
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('封面图下载成功，点击"保存"按钮即可嵌入到音频文件'),
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
      Navigator.pop(context); // 关闭进度对话框
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  Future<void> _saveTags() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final audioManager = AudioManager();
      
      // 保存到文件
      final success = await audioManager.updateSongTags(
        filePath: widget.song.filePath,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        coverArtPath: _coverArtFile?.path,
      );
      
      if (success) {
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        
        // 更新内存中的歌曲信息
        playerProvider.updateSongInfo(
          widget.song.id,
          title: _titleController.text.trim(),
          artist: _artistController.text.trim(),
          album: _albumController.text.trim(),
          coverArtPath: _coverArtFile?.path,
        );
        
        // 删除临时封面文件
        if (_tempCoverPath != null) {
          await MusicDownloadService.deleteTempFile(_tempCoverPath!);
          _tempCoverPath = null;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('标签保存成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('文件保存失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐标签'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveTags,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 封面区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '封面',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 封面图片
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _coverArtFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _coverArtFile!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.album, size: 80, color: Colors.grey),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.album, size: 80, color: Colors.grey),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // 写入选项按钮
                        IconButton(
                          onPressed: _showCoverOptions,
                          icon: const Icon(Icons.edit),
                          tooltip: '编辑封面',
                          iconSize: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 信息编辑区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '音乐信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 标题
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.music_note),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 艺术家
                    TextField(
                      controller: _artistController,
                      decoration: const InputDecoration(
                        labelText: '艺术家',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 专辑
                    TextField(
                      controller: _albumController,
                      decoration: const InputDecoration(
                        labelText: '专辑',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.album),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 文件路径（只读）
                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: '文件路径',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                      controller: TextEditingController(text: widget.song.filePath),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 时长（只读）
                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: '时长',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      controller: TextEditingController(
                        text: '${widget.song.duration.inMinutes}:${(widget.song.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}