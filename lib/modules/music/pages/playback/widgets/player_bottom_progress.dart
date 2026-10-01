import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// The flush-bottom progress hairline, live-play style: the playback position
/// on the bottom edge in every view. The settings switch
/// (`musicPlayerProgressBar`) turns it off; the position stream re-evaluates
/// it every tick, so the toggle lands within a second.
class MusicBottomProgressLine extends ConsumerWidget {
  const MusicBottomProgressLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (HivePrefUtil.getString('musicPlayerProgressBar') == 'false') {
      return const SizedBox.shrink();
    }
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    return StreamBuilder<PlayerTransportState>(
      stream: controller.playbackStream,
      builder: (context, snapshot) {
        final playback = snapshot.data;
        final duration = playback?.duration ?? Duration.zero;
        final position = playback?.position ?? Duration.zero;
        final progress = duration > Duration.zero
            ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;
        return LinearProgressIndicator(
          value: progress,
          minHeight: 6.ts(context),
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          color: context.tvTheme.focusColor,
        );
      },
    );
  }
}
