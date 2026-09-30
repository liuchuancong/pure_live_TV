import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';

class VideoHistoryPane extends ConsumerStatefulWidget {
  const VideoHistoryPane({super.key});

  @override
  ConsumerState<VideoHistoryPane> createState() => VideoHistoryPaneState();
}

class VideoHistoryPaneState extends ConsumerState<VideoHistoryPane> {
  final ScrollController _scroll = ScrollController();
  final List<HistoryItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _max = 0;
  int _viewAt = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 600 && !_loading && _hasMore) _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final (rows, nextMax, nextViewAt) = await BilibiliUgcApi.instance.getHistory(max: _max, viewAt: _viewAt);
      if (!mounted) return;
      setState(() {
        _items.addAll(rows.where((r) => r.epid == 0));
        _max = nextMax;
        _viewAt = nextViewAt;
        _hasMore = rows.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_error != null && _items.isEmpty) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_items.isEmpty && _loading) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_items.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('music_history_empty'), subtitle: '');
    }

    return DpadRegion(
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(24.ts(context)),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final hasProgress = item.progress > 0;
          final finished = item.finished;
          return TvFocusable(
            onTap: () => openVideoArchive(context, ref, item.archive),
            onLongPress: () => _delete(item),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.ts(context)),
              // No fixed height: the 98.ts(context) cover + padding + border size the
              // row. A pinned 118.ts(context) left 94.ts(context) of content room for a 98.ts(context)
              // cover — the 4px difference was the bottom overflow.
              padding: EdgeInsets.all(10.ts(context)),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.ts(context)),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.ts(context)),
                        child: CachedNetworkImage(
                          imageUrl: item.archive.cover,
                          width: 210.ts(context),
                          height: 122.ts(context),
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          errorWidget: (_, _, _) => Container(width: 210.ts(context), color: Colors.black26),
                        ),
                      ),
                      // The bar only exists when there is a position to show:
                      // a zero-width accent line under a fresh entry is noise.
                      if (hasProgress)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: item.duration > 0 ? (item.progress / item.duration).clamp(0.0, 1.0) : null,
                            minHeight: 4.ts(context),
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16.ts(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.archive.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t20.copyWith(
                            fontWeight: FontWeight.w700,
                            color: tvTheme.primaryTextColor,
                          ),
                        ),
                        SizedBox(height: 6.ts(context)),
                        Row(
                          children: [
                            if (item.page > 1) ...[
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.ts(context), vertical: 2.ts(context)),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6.ts(context)),
                                ),
                                child: Text(
                                  'P${item.page}',
                                  style: AppTextStyles.t15.copyWith(fontWeight: FontWeight.w600, color: accent),
                                ),
                              ),
                              SizedBox(width: 10.ts(context)),
                            ],
                            if (item.archive.upName.isNotEmpty)
                              Flexible(
                                child: Text(
                                  item.archive.upName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.t16.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: tvTheme.secondaryTextColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // The third line only when the row has something to
                        // say: when it was watched, and how far it got. A
                        // never-started entry with 0% and an empty clock was
                        // exactly the noise this pane is shedding.
                        if (item.viewAt > 0 || hasProgress) ...[
                          SizedBox(height: 6.ts(context)),
                          Row(
                            children: [
                              if (item.viewAt > 0) ...[
                                Icon(Icons.schedule_rounded, size: 20.ts(context), color: tvTheme.secondaryTextColor),
                                SizedBox(width: 4.ts(context)),
                                Text(
                                  _viewAtLabel(item.viewAt),
                                  style: AppTextStyles.t16.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: tvTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                              if (item.viewAt > 0 && hasProgress) SizedBox(width: 14.ts(context)),
                              if (hasProgress) ...[
                                Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 20.ts(context),
                                  color: tvTheme.secondaryTextColor,
                                ),
                                SizedBox(width: 4.ts(context)),
                                Flexible(
                                  child: Text(
                                    finished
                                        ? i18n('video_history_watched_done')
                                        : i18n(
                                            'video_history_progress',
                                            args: {'current': _clock(item.progress), 'total': _clock(item.duration)},
                                          ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.t16.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: finished ? accent : tvTheme.secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Long-press deletes the row from the bilibili watch history and drops it
  /// from the list.
  Future<void> _delete(HistoryItem item) async {
    try {
      await BilibiliUgcApi.instance.deleteHistory(aid: item.archive.aid, cid: item.cid);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.archive.bvid == item.archive.bvid && e.cid == item.cid));
      ToastUtil.show(i18n('video_history_deleted'));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    }
  }

  /// Watch timestamp, compact for a TV row: today shows the clock, this year
  /// the date and clock, older entries the full date.
  String _viewAtLabel(int viewAt) {
    // The API reports seconds.
    final time = DateTime.fromMillisecondsSinceEpoch(viewAt * 1000);
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final clock = '${two(time.hour)}:${two(time.minute)}';
    if (time.year == now.year && time.month == now.month && time.day == now.day) return clock;
    final date = '${two(time.month)}-${two(time.day)}';
    return time.year == now.year ? '$date $clock' : '${time.year}-$date $clock';
  }

  String _clock(int seconds) {
    String two(int v) => v.toString().padLeft(2, '0');
    final h = seconds ~/ 3600;
    final m = seconds.remainder(3600) ~/ 60;
    final s = seconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

/// Watch later: the server list with one-key removal.
