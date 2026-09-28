import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// The UGC region browser, newBV's 分区: one tab per region, each showing that
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

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final themeState = ref.watch(themeSettingsControllerProvider);
    final rid = _regions[_selected].$1;
    final archives = _cache[rid];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64.sp,
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.leave,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
              itemCount: _regions.length,
              separatorBuilder: (_, _) => SizedBox(width: 10.sp),
              itemBuilder: (context, index) {
                final (_, labelKey, icon) = _regions[index];
                final isSelected = index == _selected;
                return TvFocusable(
                  autofocus: index == 0,
                  onTap: () => _select(index),
                  builder: (context, focused, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: EdgeInsets.symmetric(horizontal: 22.sp, vertical: 8.sp),
                    decoration: BoxDecoration(
                      color: isSelected ? accent.withValues(alpha: 0.22) : tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(24.sp),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(icon, style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 8.sp),
                        Text(
                          i18n(labelKey),
                          style: AppTextStyles.t16W600.copyWith(
                            color: isSelected ? accent : tvTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: themeState.denseRoomLayout,
                          mainAxisSpacing: themeState.mainAxisSpacing.w,
                          crossAxisSpacing: themeState.crossAxisSpacing.w,
                          childAspectRatio:
                              ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
                        ),
                        itemCount: archives?.length ?? 0,
                        itemBuilder: (context, index) {
                          final archive = archives![index];
                          return VideoCard(
                            archive: archive,
                            badge: '${index + 1}',
                            onTap: () => VideoDetailRoute(archive).push(context),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
