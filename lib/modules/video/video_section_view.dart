import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/api/bilibili_pgc_api.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/video/pages/discover/video_pgc_page.dart';
import 'package:pure_live/modules/video/pages/discover/video_region_page.dart';
import 'package:pure_live/modules/video/pages/discover/video_search_page.dart';
import 'package:pure_live/modules/video/pages/home/video_home_page.dart';
import 'package:pure_live/modules/video/pages/personal/video_personal_section.dart';
import 'package:pure_live/modules/video/video_section.dart';

/// Content of one video section. Login is enforced by the home shell's
/// [BilibiliLoginGate], not here.
class VideoSectionView extends ConsumerWidget {
  const VideoSectionView({super.key, required this.section});

  final VideoSection section;

  /// The video module owns the PGC endpoints; the shared VOD engine asks this
  /// hook for episode urls. Idempotent.
  void _ensurePgcResolver() {
    MusicPlayerController.modulePlayUrlResolver ??= (track) async {
      if (track.part.epId <= 0) return null;
      return BilibiliPgcApi.instance.getPlayUrls(epId: track.part.epId, cid: track.part.cid);
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _ensurePgcResolver();

    return switch (section) {
      VideoSection.home => const VideoHomePage(key: ValueKey('video_home')),
      VideoSection.region => const VideoRegionPage(key: ValueKey('video_region')),
      VideoSection.pgc => const VideoPgcPage(key: ValueKey('video_pgc')),
      VideoSection.search => const VideoSearchSection(key: ValueKey('video_search')),
      VideoSection.personal => const VideoPersonalSection(key: ValueKey('video_personal')),
    };
  }
}
