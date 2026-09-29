import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_pgc_api.dart';
import 'package:pure_live/modules/media/models/models.dart';

/// The PGC shelf, newBV's 影视: one tab per season type (番剧/国创/纪录片/
/// 电影/电视剧), each a paged cover grid with the rating badge.
class VideoPgcPage extends ConsumerStatefulWidget {
  const VideoPgcPage({super.key});

  @override
  ConsumerState<VideoPgcPage> createState() => _VideoPgcPageState();
}

class _VideoPgcPageState extends ConsumerState<VideoPgcPage> {
  static const List<(int, String)> _types = [
    (1, 'video_pgc_anime'),
    (2, 'video_pgc_guochuang'),
    (3, 'video_pgc_documentary'),
    (4, 'video_pgc_movie'),
    (5, 'video_pgc_tv'),
  ];

  int _selected = 0;
  final Map<int, List<PgcItem>> _pages = {};
  final Map<int, int> _pageOf = {};
  final Map<int, bool> _hasMoreOf = {};
  final Map<int, String?> _errors = {};
  bool _loading = false;

  int get _type => _types[_selected].$1;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_pages.containsKey(_type)) return;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page = (_pageOf[_type] ?? 0) + 1;
      final items = await BilibiliPgcApi.instance.getFeed(pgcType: _type, page: page);
      if (!mounted) return;
      setState(() {
        _pages[_type] = [...(_pages[_type] ?? const <PgcItem>[]), ...items];
        _pageOf[_type] = page;
        _hasMoreOf[_type] = items.isNotEmpty;
        _errors[_type] = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[_type] = e.toString();
        _loading = false;
      });
    }
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _loadFirst();
  }

  /// The bar's OK-twice refresh: back to page 1 for the current category.
  Future<void> _refresh() async {
    final type = _types[_selected].$1;
    _pages.remove(type);
    _pageOf.remove(type);
    _hasMoreOf.remove(type);
    _errors.remove(type);
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final items = _pages[_type];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The shared TV tab bar (same bar the areas page uses): one tab per
        // season type, the refresh line shows the category load.
        TvTabBar(
          tabs: [
            for (final (_, labelKey) in _types) TvTabItemData(title: i18n(labelKey)),
          ],
          currentIndex: _selected,
          refreshing: _loading,
          onTabChange: _select,
          onTabRefresh: (_) => _refresh(),
        ),
        Expanded(
          child: _errors[_type] != null && (items?.isEmpty ?? true)
              ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _errors[_type])
              : items == null
                  ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
                  : items.isEmpty
                      ? AppStatusView(type: AppStatusType.empty, title: i18n('video_pgc_empty'), subtitle: '')
                      : DpadRegion(
                          horizontalEdge: DpadEdgeBehavior.leave,
                          child: GridView.builder(
                            padding: EdgeInsets.all(24.sp),
                            gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                            itemCount: items.length + (_hasMoreOf[_type] == true || _loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= items.length) {
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
                              final nearEnd = index >= items.length - 5;
                              if (nearEnd && !_loading && _hasMoreOf[_type] == true) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) _loadMore();
                                });
                              }
                              return _PgcCard(item: items[index]);
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _PgcCard extends StatelessWidget {
  const _PgcCard({required this.item});

  final PgcItem item;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: () => VideoSeasonRoute(item).push(context),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24.sp),
                    child: CachedNetworkImage(
                      imageUrl: item.cover,
                      fit: BoxFit.cover,
                      memCacheWidth: 480,
                      errorWidget: (_, _, _) => ColoredBox(color: tvTheme.cardColor),
                    ),
                  ),
                  if (item.badge.isNotEmpty)
                    Positioned(
                      left: 12.sp,
                      top: 12.sp,
                      child: TvCoverChip(label: item.badge),
                    ),
                  if (item.rating > 0)
                    Positioned(
                      right: 8.sp,
                      bottom: 8.sp,
                      child: TvCoverChip(
                        icon: Icons.star_rounded,
                        label: item.rating.toStringAsFixed(1),
                        textColor: Colors.amberAccent,
                      ),
                    ),
                ],
              ),
            ),
            // The info block sizes itself; the cover above takes everything
            // that remains — the room card's rule, so the card's height is
            // the grid cell's, not taller.
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvMarqueeText(
                      text: item.title,
                      isFocused: focused,
                      style: AppTextStyles.t14.copyWith(
                        fontWeight: FontWeight.w700,
                        color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t14.copyWith(
                          color: focused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor,
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
