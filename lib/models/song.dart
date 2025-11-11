class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String filePath;
  final Duration duration;
  final String? coverArtPath;
  final String? lyricsPath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.filePath,
    required this.duration,
    this.coverArtPath,
    this.lyricsPath,
  });

  // 从Map创建Song对象
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      filePath: json['filePath'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      coverArtPath: json['coverArtPath'] as String?,
      lyricsPath: json['lyricsPath'] as String?,
    );
  }

  // 将Song对象转换为Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'coverArtPath': coverArtPath,
      'lyricsPath': lyricsPath,
    };
  }

  // 复制对象并更新指定字段
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? filePath,
    Duration? duration,
    String? coverArtPath,
    String? lyricsPath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      lyricsPath: lyricsPath ?? this.lyricsPath,
    );
  }

  @override
  String toString() {
    return 'Song(id: $id, title: $title, artist: $artist, album: $album)';
  }
}