import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/music_player_controller.dart';
import 'package:pure_live/modules/media/music_video_card.dart';
import 'package:pure_live/modules/media/bilibili_music_api.dart';
import 'package:pure_live/modules/media/bilibili_music_models.dart';

/// One archive's page in video mode: cover, title, stats, description, the
/// part (part) list and the related row — the same information newBV's detail
/// screen leads with, laid out for a 1080p TV grid.
class VideoDetailPage extends ConsumerStatefulWidget {
  const VideoDetailPage({super.key, required this.archive});

  final MusicArchive archive;

  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  MusicArchive? _detail;
  List<MusicArchive> _related = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await BilibiliMusicApi.instance.getArchiveDetail(widget.archive.bvid);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
    try {
      final related = await BilibiliMusicApi.instance.getRelatedVideos(aid: widget.archive.aid);
      if (!mounted) return;
      setState(() => _related = related);
    } catch (_) {
      // The related row is a bonus; its failure must not blank the page.
    }
  }

  void _play(List<MusicTrack> tracks, int startIndex) {
    // Video mode keeps the picture on.
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex, audioOnly: false);
    const VideoPlayerRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = _detail ?? widget.archive;
    final tracks = archive.tracks;

    return TvPageScaffold(
      title: i18n('video_detail_title'),
      child: _error != null
          ? Center(child: AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error))
          : _detail == null
              ? Center(child: AppStatusView(type: AppStatusType.loading, title: '', subtitle: ''))
              : Padding(
                  padding: EdgeInsets.all(24.sp),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: the archive itself.
                      SizedBox(
                        width: 420.sp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.sp),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: archive.cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 720,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            Text(
                              archive.title,
                              style: AppTextStyles.t22W700.copyWith(color: tvTheme.primaryTextColor, height: 1.35),
                            ),
                            SizedBox(height: 10.sp),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Expanded(
                                  child: Text(
                                    archive.upName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.sp),
                            Row(
                              children: [
                                Icon(Icons.play_circle_outline_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Text(
                                  readableCount(archive.playCount.toString()),
                                  style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                                ),
                                SizedBox(width: 16.sp),
                                Icon(Icons.format_quote_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Text(
                                  readableCount(archive.barrageCount.toString()),
                                  style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                                ),
                                if (archive.publishDate.isNotEmpty) ...[
                                  SizedBox(width: 16.sp),
                                  Text(
                                    archive.publishDate,
                                    style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                                  ),
                                ],
                              ],
                            ),
                            if (archive.description.isNotEmpty) ...[
                              SizedBox(height: 12.sp),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    archive.description,
                                    style: AppTextStyles.t16W500.copyWith(
                                      color: tvTheme.secondaryTextColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 32.sp),
                      // Right column: parts on top, related below.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                              child: Row(
                                children: [
                                  Text(
                                    '${i18n('music_tracks_title')}（${tracks.length}）',
                                    style: AppTextStyles.t20W600.copyWith(color: accent),
                                  ),
                                  const Spacer(),
                                  TvButton(
                                    title: i18n('music_play_all'),
                                    icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                                    size: TvButtonSize.mini,
                                    onTap: () => _play(tracks, 0),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: ListView.separated(
                                padding: EdgeInsets.only(bottom: 16.sp),
                                itemCount: tracks.length,
                                separatorBuilder: (_, _) => SizedBox(height: 8.sp),
                                itemBuilder: (context, index) => _PartTile(
                                  track: tracks[index],
                                  index: index,
                                  onTap: () => _play(tracks, index),
                                ),
                              ),
                            ),
                            if (_related.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.only(left: 8.sp, bottom: 10.sp),
                                child: Text(
                                  i18n('video_related_title'),
                                  style: AppTextStyles.t20W600.copyWith(color: accent),
                                ),
                              ),
                              Expanded(
                                child: DpadRegion(
                                  horizontalEdge: DpadEdgeBehavior.leave,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.only(bottom: 16.sp),
                                    itemCount: _related.length,
                                    separatorBuilder: (_, _) => SizedBox(width: 12.sp),
                                    itemBuilder: (context, index) {
                                      final related = _related[index];
                                      return SizedBox(
                                        width: 260.sp,
                                        child: MusicVideoCard(
                                          archive: related,
                                          onTap: () => VideoDetailRoute(related).push(context),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({required this.track, required this.index, required this.onTap});

  final MusicTrack track;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 76.sp,
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18W500.copyWith(color: tvTheme.primaryTextColor),
                ),
              ),
              SizedBox(width: 12.sp),
              Text(
                MusicVideoCard.formatDuration(track.part.duration > 0 ? track.part.duration : track.archive.duration),
                style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
