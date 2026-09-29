import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';

import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// region's ranking feed (`ranking/v2?rid=`) — the guest-readable endpoint
/// family; the region feed/rcmd endpoints trip the web risk control and are
/// deliberately not used.
class VideoRegionPage extends ConsumerStatefulWidget {
  const VideoRegionPage({super.key});

  @override
  ConsumerState<VideoRegionPage> createState() => _VideoRegionPageState();
}

class _VideoRegionPageState extends ConsumerState<VideoRegionPage> {
  static const List<(int, String, String)> _regions = [
    (1, 'video_region_anime', '🎮'),
    (4, 'video_region_game', '🕹️'),
    (3, 'video_region_music', '🎵'),
    (36, 'video_region_knowledge', '📚'),
    (160, 'video_region_life', '🏠'),
    (119, 'video_region_kichiku', '😈'),
    (155, 'video_region_fashion', '👕'),
    (5, 'video_region_entertainment', '🍿'),
    (181, 'video_region_movie', '🎬'),
    (177, 'video_region_documentary', '🦁'),
  ];

  int _selected = 0;
  final Map<int, List<MusicArchive>> _cache = {};
  final Map<int, String?> _errors = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rid = _regions[_selected].$1;
    if (_cache.containsKey(rid)) return;
    setState(() => _loading = true);
    try {
      final archives = await BilibiliMusicApi.instance.getRegionRanking(rid: rid);
      if (!mounted) return;
      setState(() {
        _cache[rid] = archives;
        _errors[rid] = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errors[rid] = e.toString();
        _loading = false;
      });
    }
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() => _selected = index);
    _load();
  }

  /// The bar's OK-twice refresh: drop the region's cache and refetch.
  Future<void> _refresh() async {
    _cache.remove(_regions[_selected].$1);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final rid = _regions[_selected].$1;
    final archives = _cache[rid];

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
          child: _loading
              ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
              : _errors[rid] != null
              ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _errors[rid])
              : DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    padding: EdgeInsets.all(24.sp),
                    // newBV's density, sized for VideoCard (cover +
                    // two-line title + UP line) — the shared delegate.
                    gridDelegate: defaultVideoGridDelegate(context, ref),
                    itemCount: archives?.length ?? 0,
                    itemBuilder: (context, index) {
                      final archive = archives![index];
                      return VideoCard(
                        archive: archive,
                        badge: '${index + 1}',
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
