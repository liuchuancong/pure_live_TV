import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';

/// The bilibili cloud watch history (bmsc's cloud history screen), cursor
/// paged. Rows show the watched progress bar; tapping opens the archive.
class MusicCloudHistoryPage extends ConsumerStatefulWidget {
  const MusicCloudHistoryPage({super.key});

  @override
  ConsumerState<MusicCloudHistoryPage> createState() => _MusicCloudHistoryPageState();
}

class _MusicCloudHistoryPageState extends ConsumerState<MusicCloudHistoryPage> {
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
        _items.addAll(rows);
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
    if (_items.isEmpty && _loading) {
      return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    }
    if (_items.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('music_history_empty'), subtitle: '');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
          child: Row(
            children: [
              Text(
                '${i18n('music_cloud_history')}（${_items.length}）',
                style: AppTextStyles.t20W600.copyWith(color: accent),
              ),
              const Spacer(),
              TvButton(
                title: i18n('music_now_playing'),
                icon: Icon(Icons.music_note_rounded, size: 24.sp),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: () => const MusicPlayerRoute().push(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: DpadRegion(
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(24.sp, 8.sp, 24.sp, 24.sp),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: EdgeInsets.all(16.sp),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 56.sp,
                        height: 56.sp,
                        child: CircularProgressIndicator(strokeWidth: 5.sp, color: accent),
                      )
                    : Text(i18n('all_results_loaded'), style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor)),
              ),
            );
          }
          final item = _items[index];
          return _HistoryRow(item: item);
        },
      ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final progress = item.duration > 0 ? (item.progress / item.duration).clamp(0.0, 1.0) : 0.0;

    return TvFocusable(
      onTap: () => VideoDetailRoute(item.archive).push(context),
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.only(bottom: 10.sp),
        // Content-sized: a fixed 118.sp overflowed once the three text lines
        // scaled past it at the largest font setting.
        padding: EdgeInsets.all(10.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.sp),
                  child: CachedNetworkImage(
                    imageUrl: item.archive.cover,
                    width: 180.sp,
                    height: 98.sp,
                    fit: BoxFit.cover,
                    memCacheWidth: 480,
                    errorWidget: (_, _, _) => Container(width: 180.sp, color: Colors.black26),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.sp,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ],
            ),
            SizedBox(width: 14.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.archive.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    '${item.archive.upName} · ${i18n('music_history_progress')}${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                  Text(
                    MusicVideoCard.formatDuration(item.duration),
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
            if (item.finished)
              Padding(
                padding: EdgeInsets.only(right: 8.sp),
                child: Text(
                  i18n('music_history_finished'),
                  style: AppTextStyles.t14W600.copyWith(color: tvTheme.secondaryTextColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
