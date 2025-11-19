import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:metadata_god/metadata_god.dart';
import 'providers/player_provider.dart';
import 'screens/main_screen.dart';

void main() async {
  // 初始化just_audio_media_kit以支持Linux平台
  JustAudioMediaKit.ensureInitialized();
  
  // 初始化metadata_god
  await MetadataGod.initialize();
  
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: Provider.of<PlayerProvider>(context).isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const MainScreen(),
    );
  }
}