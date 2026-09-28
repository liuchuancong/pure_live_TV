import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/features/music/widgets/music_video_card.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_api.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_models.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// Video mode sections. The section rail lives in the home sidebar; this file
/// builds section content only, so the mode swaps the whole navigation.
enum VideoSection { feed, popular, ranking, search }

/// Content of one video section. Login is enforced by the home shell's
/// [BilibiliLoginGate], not here.
class VideoSectionView extends ConsumerWidget {
  const VideoSectionView({super.key, required this.section});

  final VideoSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: themeState.denseRoomLayout,
      mainAxisSpacing: themeState.mainAxisSpacing.w,
      crossAxisSpacing: themeState.crossAxisSpacing.w,
      childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
    );

    return switch (section) {
      VideoSection.feed => _FeedTab(key: const ValueKey('video_feed'), gridDelegate: gridDelegate),
      VideoSection.popular => _PopularTab(key: const ValueKey('video_popular'), gridDelegate: gridDelegate),
      VideoSection.ranking => _RankingTab(key: const ValueKey('video_ranking'), gridDelegate: gridDelegate),
      VideoSection.search => const _VideoSearchTab(key: ValueKey('video_search')),
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
      itemBuilder: (context, archive, index) =>
          MusicVideoCard(archive: archive, onTap: () => VideoDetailRoute(archive).push(context)),
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

/// Search over the whole video site, same endpoint as the music search.
class _VideoSearchTab extends ConsumerStatefulWidget {
  const _VideoSearchTab({super.key});

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
