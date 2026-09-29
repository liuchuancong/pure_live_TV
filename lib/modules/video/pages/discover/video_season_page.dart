import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';


/// One season's page, newBV's PGC detail: cover, rating, synopsis and the
/// episode list. Playing an episode builds a queue of [MusicTrack]s whose
/// parts carry `epId`, so the shared VOD engine resolves them through the
/// injected PGC resolver — video stays on the common playback path.
class VideoSeasonPage extends ConsumerStatefulWidget {
  const VideoSeasonPage({super.key, required this.item});

  /// A feed card (season id only) or a full season detail.
  final PgcItem item;

  @override
  ConsumerState<VideoSeasonPage> createState() => _VideoSeasonPageState();
}

class _VideoSeasonPageState extends ConsumerState<VideoSeasonPage> {
  PgcSeason? _season;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final season = await BilibiliPgcApi.instance.getSeasonDetail(seasonId: widget.item.seasonId);
      if (!mounted) return;
      setState(() => _season = season);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  /// Wires the PGC resolver once — the video module owns the PGC endpoints,
  /// the shared engine just asks for urls.
  void _ensureResolver() {
    MusicPlayerController.modulePlayUrlResolver ??= (track) async {
      if (track.part.epId <= 0) return null;
      return BilibiliPgcApi.instance.getPlayUrls(epId: track.part.epId, cid: track.part.cid);
    };
  }

  void _play(int index) {
    final season = _season;
    if (season == null || season.episodes.isEmpty) return;
    _ensureResolver();
    final archive = MusicArchive(
      aid: 0,
      bvid: 'pgc${season.seasonId}',
      title: season.title,
      cover: season.cover,
      upName: season.badge,
    );
    final tracks = [
      for (final episode in season.episodes)
        MusicTrack(
          archive: archive,
          part: MusicPart(
            cid: episode.cid,
            page: season.episodes.indexOf(episode) + 1,
            title: episode.longTitle.isEmpty ? '${i18n('video_pgc_episode')} ${episode.title}' : episode.longTitle,
            duration: episode.durationMs ~/ 1000,
            epId: episode.epId,
          ),
        ),
    ];
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: index, audioOnly: false);
    const VideoPlayerRoute().push(context);
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
                  padding: EdgeInsets.all(24.sp),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 340.sp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.sp),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: CachedNetworkImage(
                                  imageUrl: season.cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 720,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            Row(
                              children: [
                                if (season.rating > 0) ...[
                                  Icon(Icons.star_rounded, size: 24.sp, color: Colors.amber),
                                  SizedBox(width: 6.sp),
                                  Text(
                                    season.rating.toStringAsFixed(1),
                                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w700, color: Colors.amber),
                                  ),
                                  SizedBox(width: 16.sp),
                                ],
                                Text(
                                  '${season.episodes.length} ${i18n('video_pgc_episodes_unit')}',
                                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                ),
                              ],
                            ),
                            if (season.styles.isNotEmpty) ...[
                              SizedBox(height: 10.sp),
                              Wrap(
                                spacing: 8.sp,
                                runSpacing: 8.sp,
                                children: [
                                  for (final style in season.styles.take(6))
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
                                      decoration: BoxDecoration(
                                        color: tvTheme.cardColor,
                                        borderRadius: BorderRadius.circular(14.sp),
                                      ),
                                      child: Text(
                                        style,
                                        style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            SizedBox(height: 12.sp),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  season.evaluate,
                                  style: AppTextStyles.t14.copyWith(
                                    color: tvTheme.secondaryTextColor,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 32.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                              child: Row(
                                children: [
                                  Text(
                                    '${i18n('video_pgc_episodes_title')}（${season.episodes.length}）',
                                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                                  ),
                                  const Spacer(),
                                  TvButton(
                                    title: i18n('music_play_all'),
                                    icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                                    size: TvButtonSize.mini,
                                    onTap: () => _play(0),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: DpadRegion(
                                horizontalEdge: DpadEdgeBehavior.leave,
                                child: GridView.builder(
                                  padding: EdgeInsets.only(bottom: 16.sp),
                                  gridDelegate: TvAdaptiveGrid.media(
                                    context,
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 12.w,
                                    crossAxisSpacing: 12.w,
                                    childAspectRatio: 2.6,
                                  ),
                                  itemCount: season.episodes.length,
                                  itemBuilder: (context, index) => _EpisodeTile(
                                    episode: season.episodes[index],
                                    onTap: () => _play(index),
                                  ),
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

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onTap});

  final PgcEpisode episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 14.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.longTitle.isEmpty ? '${i18n('video_pgc_episode')} ${episode.title}' : episode.longTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor, height: 1.3),
            ),
            if (episode.badge.isNotEmpty) ...[
              SizedBox(height: 6.sp),
              Text(episode.badge, style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: accent)),
            ],
          ],
        ),
      ),
    );
  }
}
