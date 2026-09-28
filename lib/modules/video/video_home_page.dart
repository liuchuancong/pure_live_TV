import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';

import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/media/pages/ugc_dynamics_page.dart';
import 'package:pure_live/modules/video/api/video_pgc_api.dart';
import 'package:pure_live/modules/video/pages/discover/video_pgc_page.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/video/pages/discover/video_region_page.dart';
import 'package:pure_live/modules/video/pages/discover/video_search_page.dart';
import 'package:pure_live/modules/video/pages/personal/video_personal_page.dart';


/// Video mode sections. The section rail lives in the home sidebar; this file
/// builds section content only, so the mode swaps the whole navigation.
enum VideoSection { recommend, popular, ranking, region, pgc, dynamics, search, personal }

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
      return VideoPgcApi.instance.getPlayUrls(epId: track.part.epId, cid: track.part.cid);
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _ensurePgcResolver();
    // newBV's home grid: a fixed 4 columns with its own spacing — the card
    // carries its own aspect (the 1.6:1 cover plus the info block), so the
    // shared room-card aspect no longer applies here.
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 12.0,
      crossAxisSpacing: 24.0,
    );

    return switch (section) {
      VideoSection.recommend => _FeedTab(key: const ValueKey('video_feed'), gridDelegate: gridDelegate),
      VideoSection.popular => _PopularTab(key: const ValueKey('video_popular'), gridDelegate: gridDelegate),
      VideoSection.ranking => _RankingTab(key: const ValueKey('video_ranking'), gridDelegate: gridDelegate),
      VideoSection.region => const VideoRegionPage(key: ValueKey('video_region')),
      VideoSection.pgc => const VideoPgcPage(key: ValueKey('video_pgc')),
      VideoSection.dynamics => const UgcDynamicsPage(key: ValueKey('video_dynamics')),
      VideoSection.search => const VideoSearchSection(key: ValueKey('video_search')),
      VideoSection.personal => const VideoPersonalSection(key: ValueKey('video_personal')),
    };
  }
}

/// Base for the paged grid tabs: the param cache is the point. Every param
/// carries a fetch closure, and a fresh instance per build would re-key
/// `pagingCoreProvider(param)` and reset the list.
abstract class _PagedGridTab extends ConsumerStatefulWidget {
  const _PagedGridTab({super.key, required this.gridDelegate});

  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate;

  /// Stable identity of this tab, the key the param cache hangs on.
  String get tabKey;

  PagingParam<MusicArchive> buildParam();
}

class _PagedGridTabState<W extends _PagedGridTab> extends ConsumerState<W> {
  final Map<String, PagingParam<MusicArchive>> _params = {};

  @override
  Widget build(BuildContext context) {
    final param = _params.putIfAbsent(widget.tabKey, widget.buildParam);
    return BasePagedTvView<MusicArchive>(
      key: ValueKey('video_grid_${widget.tabKey}'),
      param: param,
      getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
      gridDelegate: widget.gridDelegate,
      itemBuilder: (context, archive, index) => VideoCard(
        archive: archive,
        onTap: () => VideoDetailRoute(archive).push(context),
      ),
    );
  }
}

class _FeedTab extends _PagedGridTab {
  const _FeedTab({super.key, required super.gridDelegate});

  @override
  String get tabKey => 'feed';

  @override
  PagingParam<MusicArchive> buildParam() => PagingParam<MusicArchive>(
    mode: PagingMode.serverRemote,
    pageSize: 12,
    keepAlive: true,
    fetchRemote: (page, size) => BilibiliMusicApi.instance.getRecommendFeed(page: page, pageSize: size),
  );

  @override
  ConsumerState<_FeedTab> createState() => _PagedGridTabState<_FeedTab>();
}

class _PopularTab extends _PagedGridTab {
  const _PopularTab({super.key, required super.gridDelegate});

  @override
  String get tabKey => 'popular';

  @override
  PagingParam<MusicArchive> buildParam() => PagingParam<MusicArchive>(
    mode: PagingMode.serverRemote,
    pageSize: 12,
    keepAlive: true,
    fetchRemote: (page, size) => BilibiliMusicApi.instance.getPopularVideos(page: page, pageSize: size),
  );

  @override
  ConsumerState<_PopularTab> createState() => _PagedGridTabState<_PopularTab>();
}

class _RankingTab extends _PagedGridTab {
  const _RankingTab({super.key, required super.gridDelegate});

  @override
  String get tabKey => 'ranking';

  @override
  PagingParam<MusicArchive> buildParam() => PagingParam<MusicArchive>(
    mode: PagingMode.serverAll,
    pageSize: 12,
    keepAlive: true,
    fetchAll: () => BilibiliMusicApi.instance.getMusicRanking(),
  );

  @override
  ConsumerState<_RankingTab> createState() => _PagedGridTabState<_RankingTab>();
}
