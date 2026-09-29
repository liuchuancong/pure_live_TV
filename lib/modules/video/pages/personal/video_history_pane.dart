import 'dart:async';
import 'package:pure_live/shared/theme/tv_text_scale.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
          final progress = item.duration > 0 ? (item.progress / item.duration).clamp(0.0, 1.0) : 0.0;
          return TvFocusable(
            onTap: () => openVideoArchive(context, ref, item.archive),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.ts(context)),
              // No fixed height: the 98.ts(context) cover + padding + border size the
              // row. A pinned 118.sp left 94.sp of content room for a 98.sp
              // cover — the 4px difference was the bottom overflow.
              padding: EdgeInsets.all(10.ts(context)),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.sp),
                        child: CachedNetworkImage(
                          imageUrl: item.archive.cover,
                          width: 180.ts(context),
                          height: 98.ts(context),
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          errorWidget: (_, _, _) => Container(width: 180.ts(context), color: Colors.black26),
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
                  SizedBox(width: 14.ts(context)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.archive.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t18.copyWith(
                            fontWeight: FontWeight.w600,
                            color: tvTheme.primaryTextColor,
                          ),
                        ),
                        SizedBox(height: 4.ts(context)),
                        Text(
                          '${item.archive.upName} · ${(progress * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                        ),
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
}

/// Watch later: the server list with one-key removal.
