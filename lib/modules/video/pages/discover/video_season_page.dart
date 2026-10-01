import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// One season's page, newBV's PGC detail: cover, rating, 更新至 line,
/// synopsis, the 追番 toggle, series switcher chips, the 正片 episode grid and
/// one grid per bonus section (番外/PV), plus the "上次看到" resume entry from
/// the season's user_status.progress. Playing an episode builds a queue of
/// [MusicTrack]s whose parts carry `epId`, so the shared VOD engine resolves
/// them through the injected PGC resolver — video stays on the common
/// playback path.
class VideoSeasonPage extends ConsumerStatefulWidget {
  const VideoSeasonPage({super.key, required this.item});

  /// A feed card (season id only) or a full season detail.
  final PgcItem item;

  @override
  ConsumerState<VideoSeasonPage> createState() => _VideoSeasonPageState();
}

class _VideoSeasonPageState extends ConsumerState<VideoSeasonPage> {
  late int _seasonId = widget.item.seasonId;
  PgcSeason? _season;
  String? _error;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final season = await BilibiliPgcApi.instance.getSeasonDetail(seasonId: _seasonId);
      if (!mounted) return;
      setState(() => _season = season);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  void _switchSeason(int seasonId) {
    if (seasonId == _seasonId || seasonId <= 0) return;
    setState(() {
      _seasonId = seasonId;
      _season = null;
      _error = null;
    });
    _load();
  }

  /// Wires the PGC resolver once — the video module owns the PGC endpoints,
  /// the shared engine just asks for urls.
  void _ensureResolver() {
    MusicPlayerController.modulePlayUrlResolver ??= (track) async {
      if (track.part.epId <= 0) return null;
      return BilibiliPgcApi.instance.getPlayUrls(epId: track.part.epId, cid: track.part.cid);
    };
  }

  void _playFrom(List<PgcEpisode> episodes, int index) {
    final season = _season;
    if (season == null || episodes.isEmpty) return;
    _ensureResolver();
    final archive = MusicArchive(
      aid: 0,
      bvid: 'pgc${season.seasonId}',
      title: season.title,
      cover: season.cover,
      upName: season.badge,
    );
    final tracks = [
      for (final (i, episode) in episodes.indexed)
        MusicTrack(
          archive: archive,
          part: MusicPart(
            cid: episode.cid,
            page: i + 1,
            title: episode.longTitle.isEmpty ? '${i18n('video_pgc_episode')} ${episode.title}' : episode.longTitle,
            duration: episode.durationMs ~/ 1000,
            epId: episode.epId,
          ),
        ),
    ];
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: index, audioOnly: false);
    const VideoPlayerRoute().push(context);
  }

  /// Index into the main episode list where the user last stopped, or -1.
  int get _resumeIndex {
    final season = _season;
    if (season == null || season.lastEpId <= 0) return -1;
    return season.episodes.indexWhere((episode) => episode.epId == season.lastEpId);
  }

  /// newBV's 追番 toggle: web follow/add|del, flipped locally on success so
  /// the button answers without a full detail reload.
  Future<void> _toggleFollow() async {
    final season = _season;
    if (season == null || _followBusy) return;
    if (!BilibiliPgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    setState(() => _followBusy = true);
    final adding = season.follow != 1;
    try {
      if (adding) {
        await BilibiliPgcApi.instance.followSeason(seasonId: season.seasonId);
      } else {
        await BilibiliPgcApi.instance.unfollowSeason(seasonId: season.seasonId);
      }
      if (!mounted) return;
      setState(() => _season = season.copyWith(follow: adding ? 1 : 0));
      ToastUtil.show(i18n(adding ? 'video_pgc_followed' : 'video_pgc_unfollowed'));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    } finally {
      _followBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final season = _season;

    return TvPageScaffold(
      title: season?.title ?? widget.item.title,
      child: _error != null && season == null
          ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error)
          : season == null
          ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
          : Padding(
              padding: EdgeInsets.all(24.ts(context)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 340.ts(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.ts(context)),
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: CachedNetworkImage(imageUrl: season.cover, fit: BoxFit.cover, memCacheWidth: 720),
                          ),
                        ),
                        SizedBox(height: 16.ts(context)),
                        Row(
                          children: [
                            if (season.rating > 0) ...[
                              Icon(Icons.star_rounded, size: 24.ts(context), color: Colors.amber),
                              SizedBox(width: 6.ts(context)),
                              Text(
                                season.rating.toStringAsFixed(1),
                                style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w700, color: Colors.amber),
                              ),
                              SizedBox(width: 16.ts(context)),
                            ],
                            Text(
                              '${season.episodes.length} ${i18n('video_pgc_episodes_unit')}',
                              style: AppTextStyles.t16.copyWith(
                                fontWeight: FontWeight.w500,
                                color: tvTheme.secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        if (season.newEpDesc.isNotEmpty) ...[
                          SizedBox(height: 10.ts(context)),
                          Text(
                            season.newEpDesc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: accent),
                          ),
                        ],
                        if (season.styles.isNotEmpty) ...[
                          SizedBox(height: 10.ts(context)),
                          Wrap(
                            spacing: 8.ts(context),
                            runSpacing: 8.ts(context),
                            children: [
                              for (final style in season.styles.take(6))
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12.ts(context), vertical: 4.ts(context)),
                                  decoration: BoxDecoration(
                                    color: tvTheme.cardColor,
                                    borderRadius: BorderRadius.circular(14.ts(context)),
                                  ),
                                  child: Text(
                                    style,
                                    style: AppTextStyles.t14.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: tvTheme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12.ts(context)),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              season.evaluate,
                              style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor, height: 1.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 32.ts(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                          child: Wrap(
                            spacing: 12.ts(context),
                            runSpacing: 8.ts(context),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${i18n('video_pgc_episodes_title')}（${season.episodes.length}）',
                                style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                              ),
                              if (_resumeIndex >= 0)
                                TvButton(
                                  key: const ValueKey('pgc_resume'),
                                  title: i18n('video_pgc_resume', args: {'index': season.lastEpIndex}),
                                  icon: Icon(Icons.history_rounded, size: 24.ts(context)),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: () => _playFrom(season.episodes, _resumeIndex),
                                ),
                              TvButton(
                                key: const ValueKey('pgc_follow'),
                                title: i18n(season.follow == 1 ? 'video_pgc_follow_done' : 'video_pgc_follow'),
                                icon: Icon(
                                  season.follow == 1 ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                                  size: 24.ts(context),
                                ),
                                size: TvButtonSize.mini,
                                isSecondary: season.follow != 1,
                                onTap: _toggleFollow,
                              ),
                              TvButton(
                                key: const ValueKey('pgc_play_all'),
                                title: i18n('music_play_all'),
                                icon: Icon(Icons.play_circle_fill_rounded, size: 28.ts(context)),
                                size: TvButtonSize.mini,
                                onTap: () => _playFrom(season.episodes, 0),
                              ),
                            ],
                          ),
                        ),
                        if (season.altSeasons.length > 1)
                          Padding(
                            padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                            child: Wrap(
                              spacing: 10.ts(context),
                              runSpacing: 8.ts(context),
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  i18n('video_pgc_series'),
                                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: accent),
                                ),
                                for (final other in season.altSeasons)
                                  TvButton(
                                    key: ValueKey('pgc_season_${other.seasonId}'),
                                    title: other.title.isEmpty ? 'SS${other.seasonId}' : other.title,
                                    size: TvButtonSize.mini,
                                    isSecondary: other.seasonId != season.seasonId,
                                    onTap: () => _switchSeason(other.seasonId),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: DpadRegion(
                            horizontalEdge: DpadEdgeBehavior.leave,
                            child: ListView(
                              padding: EdgeInsets.only(bottom: 16.sp),
                              children: [
                                _EpisodeBlock(
                                  episodes: season.episodes,
                                  lastEpId: season.lastEpId,
                                  onPlay: (index) => _playFrom(season.episodes, index),
                                ),
                                for (final section in season.sections)
                                  _EpisodeBlock(
                                    header: '${section.title}（${section.episodes.length}）',
                                    episodes: section.episodes,
                                    lastEpId: season.lastEpId,
                                    onPlay: (index) => _playFrom(section.episodes, index),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// One titled episode grid inside the season page's scrolling pane — the 正片
/// block and each bonus section renders through it.
class _EpisodeBlock extends StatelessWidget {
  const _EpisodeBlock({
    required this.episodes,
    required this.lastEpId,
    required this.onPlay,
    this.header,
  });

  final List<PgcEpisode> episodes;
  final int lastEpId;
  final void Function(int index) onPlay;
  final String? header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: EdgeInsets.fromLTRB(8.sp, 4.ts(context), 8.sp, 10.ts(context)),
            child: Text(
              header!,
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: context.tvTheme.focusColor),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: 12.sp),
          gridDelegate: TvAdaptiveGrid.media(
            context,
            crossAxisCount: 4,
            mainAxisSpacing: 12.w,
            crossAxisSpacing: 12.w,
            childAspectRatio: 2.6,
          ),
          itemCount: episodes.length,
          itemBuilder: (context, index) =>
              _EpisodeTile(episode: episodes[index], isLastSeen: lastEpId > 0 && episodes[index].epId == lastEpId, onTap: () => onPlay(index)),
        ),
      ],
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onTap, this.isLastSeen = false});

  final PgcEpisode episode;
  final VoidCallback onTap;
  final bool isLastSeen;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(12.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.longTitle.isEmpty ? '${i18n('video_pgc_episode')} ${episode.title}' : episode.longTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t16.copyWith(
                fontWeight: FontWeight.w500,
                color: tvTheme.primaryTextColor,
                height: 1.3,
              ),
            ),
            if (episode.badge.isNotEmpty || isLastSeen) ...[
              SizedBox(height: 6.ts(context)),
              Text(
                isLastSeen && episode.badge.isEmpty ? i18n('video_pgc_last_seen') : episode.badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
