import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/vod/pages/ugc_dynamics_page.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';

/// three feeds the reference puts on its home screen. The tab order follows
class VideoHomePage extends ConsumerStatefulWidget {
  const VideoHomePage({super.key});

  @override
  ConsumerState<VideoHomePage> createState() => VideoHomePageState();
}

class VideoHomePageState extends ConsumerState<VideoHomePage> {
  int _tab = SettingsService.to.isInitialized ? SettingsService.to.videoState.homeTabIndex.clamp(0, 2) : 1;

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
/// `pagingCoreProvider(param)` and reset the list. The feed tabs share
/// newBV's density via [defaultVideoGridDelegate].
abstract class _PagedGridTab extends ConsumerStatefulWidget {
  const _PagedGridTab({super.key});

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
      gridDelegate: defaultVideoGridDelegate(context, ref),
      itemBuilder: (context, archive, index) =>
          VideoCard(archive: archive, onTap: () => openVideoArchive(context, ref, archive)),
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
