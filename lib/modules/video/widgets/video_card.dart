import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';

/// The video-mode card: the shared archive-card shell (TvRoomCard look) plus
/// the newBV touches — the watched-progress bar on the cover edge and the
/// long-press add-to-watch-later shortcut.
class VideoCard extends ConsumerWidget {
  const VideoCard({super.key, required this.archive, required this.onTap, this.badge = ''});

  final MusicArchive archive;
  final VoidCallback onTap;

  /// An override label (ranking position, region name); empty falls back to
  /// the archive's region name.
  final String badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      videoProgressControllerProvider.select((s) => s.entries[archive.bvid]?.percent ?? 0.0),
    );

    return MusicVideoCard(
      archive: archive,
      badge: badge,
      progress: progress,
      onTap: onTap,
      onLongPress: archive.aid > 0
          ? () async {
              try {
                await BilibiliUgcApi.instance.addToView(archive.aid);
                ToastUtil.show(i18n('video_action_toviewed'));
              } catch (_) {
                ToastUtil.show(i18n('video_action_need_login'));
              }
            }
          : null,
    );
  }
}
