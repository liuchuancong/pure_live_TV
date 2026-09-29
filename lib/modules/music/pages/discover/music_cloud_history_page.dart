import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/tv_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/media/models/models.dart';


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

  /// Long press on a history row: removes the record from the bilibili
  /// watch history and drops it from this list.
  Future<void> _showRowMenu(BuildContext context, WidgetRef ref, HistoryItem item) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: item.archive.title,
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n('music_history_delete'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.ts(context)),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                _deleteRow(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRow(HistoryItem item) async {
    try {
      await BilibiliUgcApi.instance.deleteHistory(aid: item.archive.aid, cid: item.cid);
      setState(() => _items.removeWhere((it) => it.archive.bvid == item.archive.bvid));
      ToastUtil.show(i18n('music_history_deleted'));
    } catch (_) {
      ToastUtil.show(i18n('music_history_delete_failed'));
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
          padding: EdgeInsets.fromLTRB(24.ts(context), 16.ts(context), 24.ts(context), 8.ts(context)),
          child: Row(
            children: [
              Text(
                '${i18n('music_cloud_history')}（${_items.length}）',
                style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
              ),
              const Spacer(),
              TvButton(
                title: i18n('music_now_playing'),
                icon: Icon(Icons.music_note_rounded, size: 24.ts(context)),
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
        padding: EdgeInsets.fromLTRB(24.ts(context), 8.ts(context), 24.ts(context), 24.ts(context)),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Padding(
              padding: EdgeInsets.all(16.ts(context)),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 56.ts(context),
                        height: 56.ts(context),
                        child: CircularProgressIndicator(strokeWidth: 5.sp, color: accent),
                      )
                    : Text(i18n('all_results_loaded'), style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor)),
              ),
            );
          }
          final item = _items[index];
          return _HistoryRow(
            item: item,
            onLongPress: () => _showRowMenu(context, ref, item),
          );
        },
      ),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, required this.onLongPress});

  final HistoryItem item;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final progress = item.duration > 0 ? (item.progress / item.duration).clamp(0.0, 1.0) : 0.0;

    return TvFocusable(
      onTap: () => VideoDetailRoute(item.archive).push(context),
      onLongPress: onLongPress,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.only(bottom: 10.ts(context)),
        // Content-sized: a fixed 118.sp overflowed once the three text lines
        // scaled past it at the largest font setting.
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
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                  ),
                  SizedBox(height: 4.ts(context)),
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
                padding: EdgeInsets.only(right: 8.ts(context)),
                child: Text(
                  i18n('music_history_finished'),
                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: tvTheme.secondaryTextColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
