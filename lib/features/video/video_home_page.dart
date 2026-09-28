import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/features/music/widgets/music_video_card.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_api.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_models.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// The video mode home: bilibili UGC browsing in the same bar-over-grid shape
/// as the live pages, so the remote behaves identically.
///
/// The grids show the same archives the music mode shows — a video here plays
/// with the picture on, through the shared VOD engine.
class VideoHomePage extends ConsumerStatefulWidget {
  const VideoHomePage({super.key});

  @override
  ConsumerState<VideoHomePage> createState() => _VideoHomePageState();
}

class _VideoHomePageState extends ConsumerState<VideoHomePage> {
  int _tabIndex = 0;

  static const _tabKeys = ['video_tab_recommend', 'video_tab_popular', 'video_tab_ranking', 'video_tab_search'];

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: themeState.denseRoomLayout,
      mainAxisSpacing: themeState.mainAxisSpacing.w,
      crossAxisSpacing: themeState.crossAxisSpacing.w,
      childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
    );

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvTabBar(
            tabs: [for (final key in _tabKeys) TvTabItemData(title: i18n(key))],
            currentIndex: _tabIndex,
            onTabChange: (index) => setState(() => _tabIndex = index),
          ),
          SizedBox(height: 16.sp),
          Expanded(
            child: TvTabView(
              memoryKey: 'video_tab_view_$_tabIndex',
              verticalEdge: DpadEdgeBehavior.leave,
              horizontalEdge: DpadEdgeBehavior.leave,
              child: switch (_tabIndex) {
                0 => _FeedTab(gridDelegate: gridDelegate),
                1 => _PopularTab(gridDelegate: gridDelegate),
                2 => _RankingTab(gridDelegate: gridDelegate),
                _ => const _VideoSearchTab(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Base for the paged grid tabs: the param cache is the point. Every param
/// carries a fetch closure, and a fresh instance per build would re-key
/// `pagingCoreProvider(param)` and reset the list.
abstract class _PagedGridTab extends ConsumerStatefulWidget {
  const _PagedGridTab({required this.gridDelegate});

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
      itemBuilder: (context, archive, index) =>
          MusicVideoCard(archive: archive, onTap: () => VideoDetailRoute(archive).push(context)),
    );
  }
}

class _FeedTab extends _PagedGridTab {
  const _FeedTab({required super.gridDelegate});

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
  const _PopularTab({required super.gridDelegate});

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
  const _RankingTab({required super.gridDelegate});

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

/// Search over the whole video site, same endpoint as the music search.
class _VideoSearchTab extends ConsumerStatefulWidget {
  const _VideoSearchTab();

  @override
  ConsumerState<_VideoSearchTab> createState() => _VideoSearchTabState();
}

class _VideoSearchTabState extends ConsumerState<_VideoSearchTab> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, PagingParam<MusicArchive>> _params = {};
  String _submittedKeyword = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    setState(() => _submittedKeyword = trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final themeState = ref.watch(themeSettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 560.sp,
              child: TvInputField(
                controller: _controller,
                hint: i18n('video_search_hint'),
                height: 64.sp,
                maxLines: 1,
                onSubmitted: _submit,
              ),
            ),
            SizedBox(width: 16.sp),
            TvButton(
              title: i18n('search_live'),
              icon: Icon(Icons.search_rounded, size: 28.sp),
              size: TvButtonSize.mini,
              onTap: () => _submit(_controller.text),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Expanded(
          child: _submittedKeyword.isEmpty
              ? Center(
                  child: Text(
                    i18n('music_search_empty_hint'),
                    style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final keyword = _submittedKeyword;
                    final param = _params.putIfAbsent(
                      keyword,
                      () => PagingParam<MusicArchive>(
                        mode: PagingMode.serverRemote,
                        pageSize: 20,
                        keepAlive: true,
                        fetchRemote: (page, size) =>
                            BilibiliMusicApi.instance.searchVideos(keyword, page: page, pageSize: size),
                      ),
                    );
                    return BasePagedTvView<MusicArchive>(
                      key: ValueKey('video_search_$keyword'),
                      param: param,
                      getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: themeState.denseRoomLayout,
                        mainAxisSpacing: themeState.mainAxisSpacing.w,
                        crossAxisSpacing: themeState.crossAxisSpacing.w,
                        childAspectRatio:
                            ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
                      ),
                      itemBuilder: (context, archive, index) => MusicVideoCard(
                        archive: archive,
                        onTap: () => VideoDetailRoute(archive).push(context),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
