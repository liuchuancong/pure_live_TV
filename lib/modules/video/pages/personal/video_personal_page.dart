import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';

/// The video personal center, newBV's personal sections over the logged-in
/// account: fav folders (server-side), cloud history, watch later. Nothing
/// here writes music's Hive keys — the module boundary holds.
class VideoPersonalSection extends ConsumerStatefulWidget {
  const VideoPersonalSection({super.key});

  @override
  ConsumerState<VideoPersonalSection> createState() => _VideoPersonalSectionState();
}

class _VideoPersonalSectionState extends ConsumerState<VideoPersonalSection> {
  int _tab = 0;

  static const _tabs = [
    ('video_personal_fav', Icons.favorite_border),
    ('video_personal_history', Icons.history_rounded),
    ('video_personal_toview', Icons.watch_later_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
          child: Row(
            children: [
              for (final (index, (label, icon)) in _tabs.indexed) ...[
                TvButton(
                  key: ValueKey('personal_tab_$index'),
                  title: i18n(label),
                  icon: Icon(icon, size: 24.sp),
                  size: TvButtonSize.mini,
                  isSecondary: _tab != index,
                  onTap: () => setState(() => _tab = index),
                ),
                SizedBox(width: 12.sp),
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => const _FavPane(),
            1 => const _HistoryPane(),
            _ => const _ToViewPane(),
          },
        ),
      ],
    );
  }
}

/// Fav folders: the account's folders as cards; opening one lists its
/// archives inline (kept in one pane to save the user a hop).
class _FavPane extends ConsumerStatefulWidget {
  const _FavPane();

  @override
  ConsumerState<_FavPane> createState() => _FavPaneState();
}

class _FavPaneState extends ConsumerState<_FavPane> {
  List<FavFolder>? _folders;
  String? _error;
  int? _openFolderId;
  List<FavResource>? _resources;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await BilibiliUgcApi.instance.getMyFavFolders();
      if (!mounted) return;
      setState(() => _folders = folders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openFolder(FavFolder folder) async {
    setState(() {
      _openFolderId = folder.id;
      _resources = null;
    });
    try {
      final resources = await BilibiliUgcApi.instance.getFavResources(folder.id, pageSize: 25);
      if (!mounted) return;
      setState(() => _resources = resources);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resources = []);
      ToastUtil.show(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (_error != null) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_folders == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');

    if (_openFolderId != null) {
      if (_resources == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 8.sp),
            child: TvButton(
              title: i18n('video_personal_back'),
              icon: Icon(Icons.arrow_back_rounded, size: 22.sp),
              size: TvButtonSize.mini,
              isSecondary: true,
              onTap: () => setState(() => _openFolderId = null),
            ),
          ),
          Expanded(
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: GridView.builder(
                padding: EdgeInsets.all(24.sp),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16.w,
                  crossAxisSpacing: 16.w,
                  childAspectRatio: 0.95,
                ),
                itemCount: _resources!.length,
                itemBuilder: (context, index) {
                  final archive = _resources![index].toArchive();
                  return VideoCard(archive: archive, onTap: () => VideoDetailRoute(archive).push(context));
                },
              ),
            ),
          ),
        ],
      );
    }

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: GridView.builder(
        padding: EdgeInsets.all(24.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16.w,
          crossAxisSpacing: 16.w,
          childAspectRatio: 1.3,
        ),
        itemCount: _folders!.length,
        itemBuilder: (context, index) {
          final folder = _folders![index];
          return TvFocusable(
            onTap: () => _openFolder(folder),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(16.sp),
                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.sp),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.folder_special_outlined, size: 40.sp, color: accent),
                  SizedBox(height: 10.sp),
                  Expanded(
                    child: Text(
                      folder.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                    ),
                  ),
                  Text(
                    '${folder.mediaCount} ${i18n('music_tracks_unit')}',
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
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

/// Cloud history, cursor-paged, with the progress bar the server reports.
class _HistoryPane extends ConsumerStatefulWidget {
  const _HistoryPane();

  @override
  ConsumerState<_HistoryPane> createState() => _HistoryPaneState();
}

class _HistoryPaneState extends ConsumerState<_HistoryPane> {
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
    if (_items.isEmpty) return AppStatusView(type: AppStatusType.empty, title: i18n('music_history_empty'), subtitle: '');

    return DpadRegion(
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.all(24.sp),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final progress = item.duration > 0 ? (item.progress / item.duration).clamp(0.0, 1.0) : 0.0;
          return TvFocusable(
            onTap: () => VideoDetailRoute(item.archive).push(context),
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: EdgeInsets.only(bottom: 10.sp),
              height: 118.sp,
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
class _ToViewPane extends ConsumerStatefulWidget {
  const _ToViewPane();

  @override
  ConsumerState<_ToViewPane> createState() => _ToViewPaneState();
}

class _ToViewPaneState extends ConsumerState<_ToViewPane> {
  List<ToViewItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await BilibiliUgcApi.instance.getToView();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _remove(ToViewItem item) async {
    try {
      await BilibiliUgcApi.instance.removeFromView(item.archive.aid);
      _load();
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error);
    }
    if (_items == null) return AppStatusView(type: AppStatusType.loading, title: '', subtitle: '');
    if (_items!.isEmpty) {
      return AppStatusView(type: AppStatusType.empty, title: i18n('video_toview_empty'), subtitle: '');
    }

    return DpadRegion(
      child: GridView.builder(
        padding: EdgeInsets.all(24.sp),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 16.w,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.95,
        ),
        itemCount: _items!.length,
        itemBuilder: (context, index) {
          final archive = _items![index].archive;
          final progress = ref.read(videoProgressControllerProvider.notifier).percentOf(archive.bvid);
          return GestureDetector(
            onLongPress: () => _remove(_items![index]),
            child: VideoCard(
              archive: archive,
              badge: progress > 0 ? '${(progress * 100).toStringAsFixed(0)}%' : '',
              onTap: () => VideoDetailRoute(archive).push(context),
            ),
          );
        },
      ),
    );
  }
}
