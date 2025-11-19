import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/audio_manager.dart';

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
    super.dispose();
  }

  Future<void> _pickCoverArt() async {
    // 这里需要导入file_picker包
    // 暂时使用占位符逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('封面选择功能将在后续版本中实现')),
    );
  }

  Future<void> _saveTags() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
      
      // 更新歌曲信息
      playerProvider.updateSongInfo(
        widget.song.id,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        coverArtPath: _coverArtFile?.path,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('标签保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
                    GestureDetector(
                      onTap: _pickCoverArt,
                      child: Container(
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('点击添加封面', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                      ),
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