import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';


/// The grid of one library category.
///
/// Clicking a picture or video opens the fullscreen preview (apply happens
/// there); clicking a gradient applies it directly — a full-bleed gradient
/// preview adds nothing over the tile.
class WallpaperItemsPage extends ConsumerStatefulWidget {
  const WallpaperItemsPage({super.key, required this.source, required this.category});

  final BackgroundSource source;
  final BackgroundCategory category;

  @override
  ConsumerState<WallpaperItemsPage> createState() => _WallpaperItemsPageState();
}

class _WallpaperItemsPageState extends ConsumerState<WallpaperItemsPage> {
  /// Item currently being applied (gradients only). Drives the tile spinner.
  String? _applyingItem;

  @override
  Widget build(BuildContext context) {
    final shardKey = (
      sourceId: widget.source.id,
      kind: widget.source.kind,
      category: widget.category,
    );
    final shardAsync = ref.watch(backgroundShardProvider(shardKey));
    final languageCode = Localizations.localeOf(context).languageCode;
    final bgState = SettingsService.to.bgState;
    final currentUrl = widget.source.kind == BackgroundKind.video ? bgState.networkVideoUrl : bgState.networkImageUrl;

    return TvScaffold(
      title: widget.category.localizedName(languageCode),
      child: shardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorRetryView(
          message: '$error',
          onRetry: () => ref.invalidate(backgroundShardProvider(shardKey)),
        ),
        data: (shard) {
          final items = shard.items;
          if (items.isEmpty) {
            return Center(
              child: Text(
                i18nOr('background_no_item', 'No wallpapers in this category'),
                style: TextStyle(fontSize: 16.sp, color: context.tvTheme.secondaryTextColor),
              ),
            );
          }
          return DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            child: GridView.builder(
              // Generous cache extent: the tiles are cheap (one small webp
              // each) and keeping a screenful ahead stops the d-pad from
              // outrunning the images on fast scrolling.
              scrollCacheExtent:  ScrollCacheExtent.pixels(800.sp),
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16.w,
                crossAxisSpacing: 16.w,
                childAspectRatio: 16 / 9,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return WallpaperTile(
                  item: item,
                  kind: widget.source.kind,
                  current: _isCurrent(currentUrl, item.file),
                  applying: _applyingItem == item.key,
                  onSelect: () => _openItem(items, index),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openItem(List<BackgroundItem> items, int index) {
    final item = items[index];
    if (widget.source.kind == BackgroundKind.gradient) {
      _applyGradient(item);
      return;
    }
    context.push(
      AppRoutes.kWallpaperPreview,
      extra: WallpaperPreviewArgs.catalog(items: items, kind: widget.source.kind, initialIndex: index),
    );
  }

  Future<void> _applyGradient(BackgroundItem item) async {
    setState(() => _applyingItem = item.key);
    try {
      final colors = <Color>[
        for (final stop in item.gradient ?? const <BackgroundGradientStop>[]) ColorUtil.hexToColor(stop.color),
      ];
      if (colors.length < 2) {
        ToastUtil.show(i18nOr('background_invalid_gradient', 'Gradient data is incomplete'));
        return;
      }
      SettingsService.to.bg.setGradient(colors);
      ToastUtil.show(i18nOr('wallpaper_set_done', 'Background updated'));
    } catch (error) {
      ToastUtil.show(
        i18nOr('background_apply_failed', 'Failed to apply: {msg}', args: {'msg': '$error'}),
      );
    } finally {
      if (mounted) setState(() => _applyingItem = null);
    }
  }

  /// Whether the given file backs the background in use right now.
  static bool _isCurrent(String? currentUrl, String file) =>
      currentUrl != null && currentUrl.isNotEmpty && file.isNotEmpty && currentUrl.endsWith(file);
}

/// Failure state with a retry button.
class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(20.sp);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 42.sp, color: theme.secondaryTextColor),
            SizedBox(height: 12.sp),
            Text(
              i18nOr('background_load_failed', 'Failed to load wallpapers'),
              style: TextStyle(fontSize: 18.sp, color: theme.primaryTextColor),
            ),
            SizedBox(height: 6.sp),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.sp, color: theme.secondaryTextColor),
            ),
            SizedBox(height: 18.sp),
            DpadFocusable(
              autofocus: true,
              onSelect: onRetry,
              effects: <DpadEffect>[
                DpadScaleEffect(scale: 1.05),
                DpadBorderEffect(color: theme.focusColor, width: 2, borderRadius: radius),
              ],
              child: Container(
                height: 36.sp,
                padding: EdgeInsets.symmetric(horizontal: 22.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: theme.cardColor, borderRadius: radius),
                child: Text(
                  i18nOr('retry', 'Retry'),
                  style: TextStyle(fontSize: 15.sp, color: theme.primaryTextColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
