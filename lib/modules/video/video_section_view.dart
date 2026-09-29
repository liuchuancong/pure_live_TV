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
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';

/// Content of one video section. Login is enforced by the home shell's
/// [BilibiliLoginGate], not here.
///
/// The keep-alive switch (the live home's refresh setting) drives the same
/// cache the music section runs: on, every section's page is built at most
/// once per run and the group renders an [IndexedStack] over them — switching
/// rail destinations re-shows the cached page with its scroll position and
/// fetched data instead of refetching; off, sections swap in place and a
/// switch rebuilds the page.
class VideoSectionView extends ConsumerStatefulWidget {
  const VideoSectionView({super.key, required this.section});

  final VideoSection section;

  @override
  ConsumerState<VideoSectionView> createState() => _VideoSectionViewState();
}

class _VideoSectionViewState extends ConsumerState<VideoSectionView> {
  /// The once-per-run children, keyed by section. Lived in the widget tree via
  /// the IndexedStack below, a page keeps its scroll position and its fetched
  /// data across rail switches.
  final Map<VideoSection, Widget> _children = {};

  /// The video module owns the PGC endpoints; the shared VOD engine asks this
  /// hook for episode urls. Idempotent.
  void _ensurePgcResolver() {
    MusicPlayerController.modulePlayUrlResolver ??= (track) async {
      if (track.part.epId <= 0) return null;
      return BilibiliPgcApi.instance.getPlayUrls(epId: track.part.epId, cid: track.part.cid);
    };
  }

  Widget _buildSection(VideoSection section) => switch (section) {
    VideoSection.home => const VideoHomePage(key: ValueKey('video_home')),
    VideoSection.region => const VideoRegionPage(key: ValueKey('video_region')),
    VideoSection.pgc => const VideoPgcPage(key: ValueKey('video_pgc')),
    VideoSection.search => const VideoSearchSection(key: ValueKey('video_search')),
    VideoSection.personal => const VideoPersonalSection(key: ValueKey('video_personal')),
  };

  Widget _childFor(VideoSection section) => _children.putIfAbsent(section, () => _buildSection(section));

  @override
  Widget build(BuildContext context) {
    _ensurePgcResolver();
    final keepAlive = ref.watch(refreshConfigControllerProvider.select((s) => s.homeKeepAlive));

    if (!keepAlive) {
      return _buildSection(widget.section);
    }

    // The video rail carries no tab bar, so the stack covers every section
    // and the rail's destination picks the visible one. expand, not Expanded:
    // this view is the login gate's direct child, not a Flex member.
    return SizedBox.expand(
      child: IndexedStack(
        index: widget.section.index,
        children: [for (final s in VideoSection.values) _childFor(s)],
      ),
    );
  }
}
