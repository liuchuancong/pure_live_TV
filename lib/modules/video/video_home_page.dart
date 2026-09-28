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
enum VideoSection { home, ranking, region, pgc, search, personal }

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

    return switch (section) {
      VideoSection.home => const _VideoHomePage(key: ValueKey('video_home')),
      VideoSection.ranking => const _RankingTab(key: ValueKey('video_ranking')),
      VideoSection.region => const VideoRegionPage(key: ValueKey('video_region')),
      VideoSection.pgc => const VideoPgcPage(key: ValueKey('video_pgc')),
      VideoSection.search => const VideoSearchSection(key: ValueKey('video_search')),
      VideoSection.personal => const VideoPersonalSection(key: ValueKey('video_personal')),
    };
  }
}

/// newBV's home grid density: a fixed 4 columns with its own spacing and a
/// cell aspect sized to the card — the 1.6:1 cover plus a two-line title and
/// the UP line come to about 1.15 total, and a little slack keeps a one-line
/// title from overflowing the cell.
const defaultVideoGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 4,
  mainAxisSpacing: 12.0,
  crossAxisSpacing: 24.0,
  childAspectRatio: 1.15,
);

/// Video home, newBV's HomeContent: a top tab bar over 动态/推荐/热门 — the
/// three feeds the reference puts on its home screen. The tab order follows
/// the reference (动态 first) and each tab keeps its own paged grid.
class _VideoHomePage extends ConsumerStatefulWidget {
  const _VideoHomePage({super.key});

  @override
  ConsumerState<_VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends ConsumerState<_VideoHomePage> {
  int _tab = 1; // 推荐: the default landing tab.

  static const _tabs = ['video_dynamics', 'video_tab_recommend', 'video_tab_popular'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TvTabBar(
          tabs: [for (final label in _tabs) TvTabItemData(title: i18n(label))],
          currentIndex: _tab,
          onTabChange: (index) => setState(() => _tab = index),
        ),
        Expanded(
          child: switch (_tab) {
            0 => const UgcDynamicsPage(key: ValueKey('video_home_dynamics')),
            1 => const _FeedTab(key: ValueKey('video_home_feed')),
            _ => const _PopularTab(key: ValueKey('video_home_popular')),
          },
        ),
      ],
    );
  }
}

/// Base for the paged grid tabs: the param cache is the point. Every param
/// carries a fetch closure, and a fresh instance per build would re-key
/// `pagingCoreProvider(param)` and reset the list.
abstract class _PagedGridTab extends ConsumerStatefulWidget {
  const _PagedGridTab({super.key});

  /// The feed tabs share newBV's density; the ranking tab overrides it.
  SliverGridDelegateWithFixedCrossAxisCount get gridDelegate => defaultVideoGridDelegate;

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
  const _FeedTab({super.key});

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
  const _PopularTab({super.key});

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
  const _RankingTab({super.key});

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
