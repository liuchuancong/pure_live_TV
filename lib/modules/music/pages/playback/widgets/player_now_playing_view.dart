import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// The audio-only view: the cover in the middle to begin with, then — once the
/// track has timed lyrics — the same cover on the left with the lines beside it.
///
/// The switch is the "lyrics arrived" animation: a fade with a slight slide, so
/// the cover travels out of the centre instead of the page jumping between two
/// unrelated layouts.
class MusicNowPlayingView extends ConsumerStatefulWidget {
  const MusicNowPlayingView({super.key,required this.track, required this.resolving, this.lyricRevision = 0});

  final MusicTrack track;
  final bool resolving;

  /// Bumped when the viewer picks a lyric by hand; the view then reloads, and
  /// the fetch finds the manual choice first.
  final int lyricRevision;

  @override
  ConsumerState<MusicNowPlayingView> createState() => MusicNowPlayingViewState();
}

class MusicNowPlayingViewState extends ConsumerState<MusicNowPlayingView> {
  LyricController? _lyric;
  Timer? _syncTimer;
  bool _loading = true;
  bool _empty = false;
  String _loadedKey = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(MusicNowPlayingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id || oldWidget.lyricRevision != widget.lyricRevision) _setup();
  }

  void _setup() {
    final key = widget.track.id;
    _loadedKey = key;
    _syncTimer?.cancel();
    _lyric?.dispose();
    final controller = LyricController();
    _lyric = controller;
    controller.setOnTapLineCallback((position) {
      ref.read(musicPlayerControllerProvider.notifier).seekTo(position);
    });
    _loading = true;
    _empty = false;

    // Position sync by polling: the handle appears some time after the page
    // (the track resolves first), so a one-shot stream subscription would miss
    // it; the poll re-reads whatever handle is live.
    _syncTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final handle = ref.read(musicPlayerControllerProvider.notifier).handle;
      if (!mounted || handle == null || _lyric == null) return;
      _lyric!.setProgress(handle.position);
    });

    MusicLyricService.instance
        .fetchLyric(
          widget.track.title,
          hint: widget.track.archive.title,
          aid: widget.track.archive.aid,
          bvid: widget.track.archive.bvid,
          cid: widget.track.part.cid,
        )
        .then((lrc) {
      if (!mounted || _loadedKey != key) return;
      setState(() {
        _loading = false;
        _empty = lrc == null;
      });
      if (lrc != null) controller.loadLyric(lrc);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _lyric?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool withLyrics = !_loading && !_empty && _lyric != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: withLyrics
          ? _LyricsLayout(key: const ValueKey('lyrics'), track: widget.track, lyric: _lyric!)
          : _PosterLayout(
              key: const ValueKey('poster'),
              track: widget.track,
              resolving: widget.resolving,
              // Only once the lookup has actually answered: a spinner over the
              // cover for a lyric request nobody asked for reads as the track
              // being stuck.
              status: _loading ? '' : (_empty ? i18n('music_no_lyric') : ''),
            ),
    );
  }
}

/// disagrees the moment the source skips a number. Same rule as the video
/// detail page's part tiles — leading digits count only when a separator
/// follows, so "24K Magic" keeps its digits.
final RegExp _leadingOrdinal = RegExp(r'^\d{1,4}\s*[.、，,\-–—_:：)·．]\s*');
String stripTrackOrdinal(String raw) => raw.replaceFirst(_leadingOrdinal, '');

/// The cover in the middle of the screen with the name under it.
class _PosterLayout extends StatelessWidget {
  const _PosterLayout({super.key, required this.track, required this.resolving, required this.status});

  final MusicTrack track;
  final bool resolving;
  final String status;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28.sp),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 420.sp,
                  height: 420.sp,
                  fit: BoxFit.cover,
                  memCacheWidth: 840,
                  errorWidget: (_, _, _) => Container(
                    width: 420.sp,
                    height: 420.sp,
                    color: tvTheme.focusColor.withValues(alpha: 0.2),
                    child: Icon(Icons.music_note_rounded, size: 140.sp, color: tvTheme.focusColor),
                  ),
                ),
              ),
              if (resolving)
                SizedBox(
                  width: 76.sp,
                  height: 76.sp,
                  child: CircularProgressIndicator(strokeWidth: 5.sp, color: tvTheme.focusColor),
                ),
            ],
          ),
          SizedBox(height: 36.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 120.sp),
            child: Text(
              stripTrackOrdinal(track.title),
              style: AppTextStyles.t34.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 12.sp),
          Text(track.archive.upName, style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
          if (status.isNotEmpty) ...[
            SizedBox(height: 14.sp),
            Text(status, style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white38)),
          ],
        ],
      ),
    );
  }
}

/// The synced lyric view: the cover and the track on the left, the lines beside
/// them. Tapping a line seeks to it.
class _LyricsLayout extends StatelessWidget {
  const _LyricsLayout({super.key, required this.track, required this.lyric});

  final MusicTrack track;
  final LyricController lyric;

  /// One style for every panel instance: bigger than the package default so it
  /// reads at TV distance.
  static final LyricStyle style = LyricStyles.default1.copyWith(
    textStyle: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500, color: Colors.white60, height: 1.6),
    activeStyle: AppTextStyles.t26.copyWith(fontWeight: FontWeight.w700, color: Colors.white, height: 1.6),
    translationStyle: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white38),
    lineGap: 18,
  );

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 64.sp, vertical: 96.sp),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.sp),
                  child: CachedNetworkImage(
                    imageUrl: track.archive.cover,
                    width: 300.sp,
                    height: 300.sp,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    errorWidget: (_, _, _) => Container(
                      width: 300.sp,
                      height: 300.sp,
                      color: tvTheme.focusColor.withValues(alpha: 0.2),
                      child: Icon(Icons.music_note_rounded, size: 96.sp, color: tvTheme.focusColor),
                    ),
                  ),
                ),
                SizedBox(height: 28.sp),
                Text(
                  stripTrackOrdinal(track.title),
                  style: AppTextStyles.t26.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.sp),
                Text(track.archive.upName, style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(width: 48.sp),
          Expanded(flex: 6, child: LyricView(controller: lyric, style: style)),
        ],
      ),
    );
  }
}
