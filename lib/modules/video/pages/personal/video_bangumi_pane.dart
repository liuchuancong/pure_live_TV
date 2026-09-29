import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_pgc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class VideoBangumiPane extends ConsumerStatefulWidget {
  const VideoBangumiPane({super.key});

  @override
  ConsumerState<VideoBangumiPane> createState() => VideoBangumiPaneState();
}

class VideoBangumiPaneState extends ConsumerState<VideoBangumiPane> {
  final ScrollController _scroll = ScrollController();
  final List<PgcItem> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
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
      final items = await BilibiliPgcApi.instance.getFollowedSeasons(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _page += 1;
        _hasMore = items.length >= 20;
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
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_bangumi_empty'), subtitle: '');
    }
    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(24.sp),
        gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return Center(
              child: _loading
                  ? SizedBox(
                      width: 32.sp,
                      height: 32.sp,
                      child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                    )
                  : const SizedBox.shrink(),
            );
          }
          final item = _items[index];
          return _BangumiCard(item: item, onUnfollow: () => _unfollow(item));
        },
      ),
    );
  }

  /// 取消追番 against the account, with a confirm — a relationship change,
  /// not a list edit. The card drops on success.
  Future<void> _unfollow(PgcItem item) async {
    final confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('video_bangumi_unfollow'),
      message: i18n('video_bangumi_unfollow_confirm', args: {'title': item.title}),
      confirmText: i18n('ui_confirm'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BilibiliPgcApi.instance.unfollowSeason(seasonId: item.seasonId);
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.seasonId == item.seasonId));
      ToastUtil.show(i18n('video_bangumi_unfollowed'));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    }
  }
}

class _BangumiCard extends StatelessWidget {
  const _BangumiCard({required this.item, required this.onUnfollow});

  final PgcItem item;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: () => VideoSeasonRoute(item).push(context),
      onLongPress: onUnfollow,
      builder: (context, focused, child) => AnimatedContainer(
        duration: TvFocusStyle.focusDuration(focused),
        curve: TvFocusStyle.curve,
        decoration: BoxDecoration(
          color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.sp),
                child: CachedNetworkImage(
                  imageUrl: item.cover,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 480,
                  errorWidget: (_, _, _) => ColoredBox(color: tvTheme.cardColor),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.sp),
              child: TvMarqueeText(
                  text: item.title,
                  isFocused: focused,
                  style: AppTextStyles.t14.copyWith(
                    fontWeight: FontWeight.w700,
                    color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
