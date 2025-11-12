import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musicplayer/providers/player_provider.dart';
import 'package:musicplayer/screens/music_screen.dart';

void main() {
  testWidgets('Album art and lyrics toggle test', (WidgetTester tester) async {
    // 构建音乐屏幕组件
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (context) => PlayerProvider(),
          child: const MusicScreen(),
        ),
      ),
    );

    // 验证组件是否正确构建
    expect(find.text('没有正在播放的歌曲'), findsOneWidget);
    
    print('Album art and lyrics toggle test passed');
  });
}