import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_pgc_api.dart';

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

  /// newBV's FollowingSeasonScreen filter: kind (anime/movie) x status
  /// (all/to-watch/watching/watched).
  int _type = 1;
  int _followStatus = 0;

  static const Map<int, String> _statusKeys = {
    0: 'video_follow_status_all',
    1: 'video_follow_status_want',
    2: 'video_follow_status_watching',
    3: 'video_follow_status_watched',
  };

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

  Future<void> _openFilter() async {
    final picked = await TvDialogUtils.show<({int type, int status})>(
      context: context,
      builder: (_) => _BangumiFilterDialog(type: _type, status: _followStatus),
    );
    if (picked == null || !mounted) return;
    if (picked.type == _type && picked.status == _followStatus) return;
    setState(() {
      _type = picked.type;
      _followStatus = picked.status;
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    _load();
  }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final items = await BilibiliPgcApi.instance.getFollowedSeasons(
        type: _type,
        followStatus: _followStatus,
        page: _page + 1,
      );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.ts(context), 8.ts(context), 24.ts(context), 0),
          child: Row(
            children: [
              TvButton(
                key: const ValueKey('bangumi_filter'),
                title: i18n('video_search_filter'),
                icon: Icon(Icons.filter_list_rounded, size: 22.ts(context)),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: _openFilter,
              ),
              SizedBox(width: 16.ts(context)),
              Text(
                '${i18n(_type == 1 ? 'video_follow_type_bangumi' : 'video_follow_type_cinema')}'
                ' · ${i18n(_statusKeys[_followStatus]!)}',
                style: AppTextStyles.t16.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: _items.isEmpty && _loading
              ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
              : _items.isEmpty
              ? AppStatusView(type: AppStatusType.empty, title: i18n('video_bangumi_empty'), subtitle: '')
              : DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.all(24.ts(context)),
                    gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                    itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return Center(
                          child: _loading
                              ? SizedBox(
                                  width: 32.ts(context),
                                  height: 32.ts(context),
                                  child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                                )
                              : const SizedBox.shrink(),
                        );
                      }
                      final item = _items[index];
                      return _BangumiCard(item: item, onUnfollow: () => _unfollow(item));
                    },
                  ),
                ),
        ),
      ],
    );
  }

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

/// The follow filter sheet: kind (anime/movie) x status (all/to-watch/
/// watching/watched), newBV's FollowingSeasonScreen dialog; confirm hands
/// the pair back.
class _BangumiFilterDialog extends StatefulWidget {
  const _BangumiFilterDialog({required this.type, required this.status});

  final int type;
  final int status;

  @override
  State<_BangumiFilterDialog> createState() => _BangumiFilterDialogState();
}

class _BangumiFilterDialogState extends State<_BangumiFilterDialog> {
  late int _type = widget.type;
  late int _status = widget.status;

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: i18n('video_search_filter'),
      width: 860.ts(context),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () => Navigator.of(context).pop((type: _type, status: _status)),
      onCancel: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n('video_follow_group_type'),
            style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 12.ts(context)),
          Wrap(
            spacing: 10.ts(context),
            runSpacing: 10.ts(context),
            children: [
              _chip(label: i18n('video_follow_type_bangumi'), active: _type == 1, onTap: () => setState(() => _type = 1)),
              _chip(label: i18n('video_follow_type_cinema'), active: _type == 2, onTap: () => setState(() => _type = 2)),
            ],
          ),
          SizedBox(height: 24.ts(context)),
          Text(
            i18n('video_follow_group_status'),
            style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 12.ts(context)),
          Wrap(
            spacing: 10.ts(context),
            runSpacing: 10.ts(context),
            children: [
              for (final (value, key) in const [(0, 'video_follow_status_all'), (1, 'video_follow_status_want'), (2, 'video_follow_status_watching'), (3, 'video_follow_status_watched')])
                _chip(label: i18n(key), active: _status == value, onTap: () => setState(() => _status = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool active, required VoidCallback onTap}) {
    final accent = context.tvTheme.focusColor;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 20.ts(context), vertical: 12.ts(context)),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30.ts(context)),
          border: Border.all(color: focused || active ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Text(
          label,
          style: AppTextStyles.t16.copyWith(
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? accent : Colors.white,
          ),
        ),
      ),
    );
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
          borderRadius: BorderRadius.circular(24.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.ts(context)),
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
              padding: EdgeInsets.all(8.ts(context)),
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
