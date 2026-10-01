import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';

/// The 分区 browser — newBV's UGC region feed. One tab per top-level region,
/// each riding `region/feed/rcmd` (the plain, non-WBI endpoint) paged by
/// `display_id`, in a grid of plain [VideoCard]s with infinite scroll and no
/// ranking badge.
class VideoRegionPage extends ConsumerStatefulWidget {
  const VideoRegionPage({super.key});

  @override
  ConsumerState<VideoRegionPage> createState() => _VideoRegionPageState();
}

class _VideoRegionPageState extends ConsumerState<VideoRegionPage> {
  static const List<(int, String, String)> _regions = [
    (1005, 'video_region_anime', '🎨'),
    (1008, 'video_region_game', '🕹️'),
    (1007, 'video_region_kichiku', '😈'),
    (1003, 'video_region_music', '🎵'),
    (1004, 'video_region_dance', '💃'),
    (1001, 'video_region_movie', '🎬'),
    (1002, 'video_region_entertainment', '🍿'),
    (1010, 'video_region_knowledge', '📚'),
    (1012, 'video_region_tech', '💻'),
    (1009, 'video_region_information', '📰'),
    (1020, 'video_region_food', '🍜'),
    (1013, 'video_region_car', '🚗'),
    (1014, 'video_region_fashion', '💄'),
    (1018, 'video_region_sports', '⚽'),
    (1024, 'video_region_animal', '🐾'),
  ];

  int _selected = 0;
  final Map<int, List<MusicArchive>> _cache = {};
  final Map<int, int> _pageOf = {};
  final Map<int, bool> _hasMoreOf = {};
  final Map<int, String?> _errors = {};
  bool _loading = false;

  int get _tid => _regions[_selected].$1;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    if (_cache.containsKey(_tid)) return;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    final tid = _tid;
    setState(() => _loading = true);
    try {
      final page = (_pageOf[tid] ?? 0) + 1;
      final archives = await BilibiliMusicApi.instance.getRegionFeed(tid: tid, page: page);
      if (!mounted) return;
      setState(() {
        _cache[tid] = [...(_cache[tid] ?? const <MusicArchive>[]), ...archives];
        _pageOf[tid] = page;
        _hasMoreOf[tid] = archives.isNotEmpty;
        _errors[tid] = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[tid] = e.toString();
        _loading = false;
      });
    }
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _loadFirst();
  }

  /// The bar's OK-twice refresh: drop the region's cache and refetch.
  Future<void> _refresh() async {
    final tid = _tid;
    _cache.remove(tid);
    _pageOf.remove(tid);
    _hasMoreOf.remove(tid);
    _errors.remove(tid);
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final tid = _tid;
    final archives = _cache[tid];
    final accent = context.tvTheme.focusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The shared TV tab bar: one tab per region, emoji as the leading icon.
        TvTabBar(
          tabs: [
            for (final (_, labelKey, icon) in _regions)
              TvTabItemData(
                title: i18n(labelKey),
                icon: Text(icon, style: AppTextStyles.t20),
              ),
          ],
          currentIndex: _selected,
          refreshing: _loading,
          onTabChange: _select,
          onTabRefresh: (_) => _refresh(),
        ),
        Expanded(
          child: _errors[tid] != null && (archives?.isEmpty ?? true)
              ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _errors[tid])
              : archives == null
              ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
              : archives.isEmpty
              ? AppStatusView(type: AppStatusType.empty, title: i18n('video_region_empty'), subtitle: '')
              : DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    padding: EdgeInsets.all(24.ts(context)),
                    // newBV's density, sized for VideoCard (cover +
                    // two-line title + UP line) — the shared delegate.
                    gridDelegate: defaultVideoGridDelegate(context, ref),
                    itemCount: archives.length + (_hasMoreOf[tid] == true || _loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= archives.length) {
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
                      final nearEnd = index >= archives.length - 8;
                      if (nearEnd && !_loading && _hasMoreOf[tid] == true) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _loadMore();
                        });
                      }
                      final archive = archives[index];
                      return VideoCard(
                        archive: archive,
                        onTap: () => openVideoArchive(context, ref, archive),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
