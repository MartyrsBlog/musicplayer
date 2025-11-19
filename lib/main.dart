import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:metadata_god/metadata_god.dart';
import 'providers/player_provider.dart';
import 'screens/main_screen.dart';
import 'services/music_download_service.dart';

void main() async {
  // 初始化just_audio_media_kit以支持Linux平台
  JustAudioMediaKit.ensureInitialized();
  
  // 初始化metadata_god
  await MetadataGod.initialize();
  
  // 清理过期的临时文件
  await MusicDownloadService.cleanupOldTempCovers();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => PlayerProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF60A5FA),      // 天蓝色主色调
          secondary: Color(0xFF93C5FD),    // 浅蓝色辅助色
          surface: Color(0xFFFFFFFF),      // 背景色
          background: Color(0xFFFFFFFF),   // 白色背景色
          onPrimary: Colors.white,          // 主色调上的文字
          onSecondary: Color(0xFF1F2937),  // 辅助色上的文字
          onSurface: Color(0xFF1F2937),    // 表面文字（深灰色）
          onBackground: Color(0xFF1F2937), // 背景文字（深灰色）
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF1F2937)),
          displayMedium: TextStyle(color: Color(0xFF1F2937)),
          displaySmall: TextStyle(color: Color(0xFF1F2937)),
          headlineLarge: TextStyle(color: Color(0xFF1F2937)),
          headlineMedium: TextStyle(color: Color(0xFF1F2937)),
          headlineSmall: TextStyle(color: Color(0xFF1F2937)),
          titleLarge: TextStyle(color: Color(0xFF1F2937)),
          titleMedium: TextStyle(color: Color(0xFF1F2937)),
          titleSmall: TextStyle(color: Color(0xFF1F2937)),
          bodyLarge: TextStyle(color: Color(0xFF4B5563)),    // 普通文字灰色
          bodyMedium: TextStyle(color: Color(0xFF4B5563)),   // 普通文字灰色
          bodySmall: TextStyle(color: Color(0xFF4B5563)),    // 普通文字灰色
          labelLarge: TextStyle(color: Color(0xFF4B5563)),   // 标签文字灰色
          labelMedium: TextStyle(color: Color(0xFFB0B0B0)),  // 标签文字白灰色
          labelSmall: TextStyle(color: Color(0xFFB0B0B0)),   // 标签文字白灰色
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFB0B0B0),
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
        ),
      ),
      home: const MainScreen(),
    );
  }
}