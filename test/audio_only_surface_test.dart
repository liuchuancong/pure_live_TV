import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/features/live_play/widgets/video_player/audio_only_surface.dart';

/// Mounts the audio-only panel the way the play page does.
///
/// The panel replaces the video surface whenever the audio-only setting is on,
/// so it has to render on its own: it is the only thing on screen when the
/// engine cannot switch its video track off (ExoPlayer), and a throw here is a
/// black player with no way back.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  testWidgets('shows the room title, the streamer and the audio-only badge', (tester) async {
    // No avatar url: the network image is not what this test is about, and
    // CachedNetworkImage would go to the disk cache.
    await pump(
      tester,
      const AudioOnlySurface(room: LiveRoom(roomId: '1', platform: 'bilibili', title: '晚间电台', nick: '主播甲')),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);
    expect(find.text('晚间电台'), findsOneWidget);
    expect(find.text('主播甲'), findsOneWidget);
    expect(find.byIcon(Remix.headphone_line), findsOneWidget);
  });

  testWidgets('renders before the room detail has arrived', (tester) async {
    await pump(tester, const AudioOnlySurface(room: null));
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Remix.headphone_line), findsOneWidget);
  });

  testWidgets('survives a room whose title is blank', (tester) async {
    await pump(tester, const AudioOnlySurface(room: LiveRoom(roomId: '2', platform: 'douyu', title: '   ')));
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Remix.headphone_line), findsOneWidget);
  });
}
