import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

/// Mask presets. A remote cycles through fixed steps instead of dragging a
/// slider, which is far easier to operate from a couch.
const List<double> _kMaskSteps = <double>[0, 0.2, 0.35, 0.5, 0.7];

/// Background picker.
///
/// Reads the remote catalog through the fastest available mirror and offers
/// static wallpapers, live wallpapers and gradients. The whole layout is
/// dpad-driven so every control is reachable with a remote.
class WallpaperPage extends ConsumerStatefulWidget {
  const WallpaperPage({super.key});

  @override
  ConsumerState<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends ConsumerState<WallpaperPage> {
  int _sourceIndex = 0;
  int _categoryIndex = 0;

  /// Item currently being applied. Drives the tile spinner and stops repeated
  /// presses from queueing more work.
  String? _applyingItem;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(backgroundCatalogProvider);

    return TvScaffold(
      title: i18nOr('ui_background_settings', 'Background'),
      child: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: '$error',
          onRetry: () {
            BackgroundRepository.instance.clear();
            ref.invalidate(backgroundCatalogProvider);
          },
        ),
        data: _buildCatalog,
      ),
    );
  }

  Widget _buildCatalog(BackgroundCatalog catalog) {
    final sources = catalog.sources;
    final languageCode = Localizations.localeOf(context).languageCode;
    if (sources.isEmpty) {
      return _ErrorView(
        message: i18nOr('background_catalog_empty', 'Remote catalog is empty'),
        onRetry: () {
          BackgroundRepository.instance.clear();
          ref.invalidate(backgroundCatalogProvider);
        },
      );
    }

    final sourceIndex = _sourceIndex.clamp(0, sources.length - 1);
    final source = sources[sourceIndex];
    final categories = source.visibleCategories;
    if (categories.isEmpty) {
      return _ErrorView(
        message: i18nOr('background_no_category', 'Nothing available here'),
        onRetry: () => ref.invalidate(backgroundCatalogProvider),
      );
    }
    final categoryIndex = _categoryIndex.clamp(0, categories.length - 1);
    final category = categories[categoryIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvTabBar(
          tabs: [
            for (final s in sources)
              TvTabItemData(
                title: _tabTitle(s.localizedName(languageCode), s.id),
              ),
          ],
          currentIndex: sourceIndex,
          onTabChange: (index) => setState(() {
            _sourceIndex = index;
            _categoryIndex = 0;
          }),
        ),
        if (source.categorized)
          TvTabBar(
            tabs: [
              for (final c in categories)
                TvTabItemData(
                  title:
                      '${_tabTitle(c.localizedName(languageCode), c.id)} (${c.count})',
                ),
            ],
            currentIndex: categoryIndex,
            onTabChange: (index) => setState(() => _categoryIndex = index),
          ),
        _Toolbar(
          source: source,
          busy: _busy,
          onRefresh: () {
            BackgroundRepository.instance.clear();
            ref.invalidate(backgroundCatalogProvider);
          },
        ),
        SizedBox(height: 8.sp),
        Expanded(child: _buildGrid(source, category)),
      ],
    );
  }

  Widget _buildGrid(BackgroundSource source, BackgroundCategory category) {
    final shardKey = (
      sourceId: source.id,
      kind: source.kind,
      category: category,
    );
    final shardAsync = ref.watch(backgroundShardProvider(shardKey));
    // 列间距/行间距 are an offset from the 6.0 design default. This grid never
    // used the shared 32 default, so it keeps its own 16 design-pixel baseline
    // and the untouched setting reproduces it.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = 16 + themeState.crossAxisSpacing - ThemeSettingsController.defaultSpacing;
    final double mainSpacing = 16 + themeState.mainAxisSpacing - ThemeSettingsController.defaultSpacing;
    final bgState = SettingsService.to.bgState;
    final currentUrl = source.kind == BackgroundKind.video
        ? bgState.networkVideoUrl
        : bgState.networkImageUrl;

    return shardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: '$error',
        onRetry: () => ref.invalidate(backgroundShardProvider(shardKey)),
      ),
      data: (shard) {
        final items = shard.items;
        if (items.isEmpty) {
          return Center(
            child: Text(
              i18nOr('background_no_item', 'No wallpapers in this category'),
              style: TextStyle(
                fontSize: 16.sp,
                color: context.tvTheme.secondaryTextColor,
              ),
            ),
          );
        }
        return DpadRegion(
          verticalEdge: DpadEdgeBehavior.leave,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: mainSpacing.w,
              crossAxisSpacing: crossSpacing.w,
              childAspectRatio: 16 / 9,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _WallpaperTile(
                item: item,
                kind: source.kind,
                current: _isCurrent(currentUrl, item.file),
                applying: _applyingItem == item.key,
                onSelect: () => _apply(source, item),
              );
            },
          ),
        );
      },
    );
  }

  /// Falls back to the raw id when the catalog carries no display name.
  static String _tabTitle(String localized, String id) =>
      localized.isNotEmpty ? localized : id;

  /// Whether the given file backs the background in use right now.
  static bool _isCurrent(String? currentUrl, String file) =>
      currentUrl != null &&
      currentUrl.isNotEmpty &&
      file.isNotEmpty &&
      currentUrl.endsWith(file);

  Future<void> _apply(BackgroundSource source, BackgroundItem item) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _applyingItem = item.key;
    });
    try {
      switch (source.kind) {
        case BackgroundKind.image:
        case BackgroundKind.video:
          final url = await BackgroundRepository.instance.urlOf(item.file);
          if (!mounted) return;
          if (source.kind == BackgroundKind.video) {
            SettingsService.to.bg.setNetworkVideo(url);
          } else {
            SettingsService.to.bg.setNetworkImage(url);
          }
        case BackgroundKind.gradient:
          final colors = <Color>[
            for (final stop
                in item.gradient ?? const <BackgroundGradientStop>[])
              ColorUtil.hexToColor(stop.color),
          ];
          if (colors.length < 2) {
            _toast(
              i18nOr(
                'background_invalid_gradient',
                'Gradient data is incomplete',
              ),
            );
            return;
          }
          SettingsService.to.bg.setGradient(colors);
      }
    } catch (error) {
      _toast(
        i18nOr(
          'background_apply_failed',
          'Failed to apply: {msg}',
          args: {'msg': '$error'},
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _applyingItem = null;
        });
      }
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

/// Toolbar above the grid: mask preset, fit mode, clear, refresh.
class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.source,
    required this.busy,
    required this.onRefresh,
  });

  final BackgroundSource source;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.tvTheme;
    final bg = SettingsService.to.bg;
    final state = SettingsService.to.bgState;
    final maskIndex = _nearestMaskIndex(state.maskOpacity);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sp),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.brightness_6_outlined,
            label: i18nOr(
              'background_mask',
              'Mask {value}%',
              args: {'value': '${(state.maskOpacity * 100).round()}'},
            ),
            onSelect: () => bg.setMaskOpacity(
              _kMaskSteps[(maskIndex + 1) % _kMaskSteps.length],
            ),
          ),
          SizedBox(width: 12.sp),
          _ActionChip(
            icon: state.boxFit == BoxFit.contain
                ? Icons.fit_screen_outlined
                : Icons.crop_free_outlined,
            label: state.boxFit == BoxFit.contain
                ? i18nOr('background_fit_contain', 'Fit')
                : i18nOr('background_fit_cover', 'Fill'),
            onSelect: () => bg.setBoxFit(
              state.boxFit == BoxFit.cover ? BoxFit.contain : BoxFit.cover,
            ),
          ),
          SizedBox(width: 12.sp),
          _ActionChip(
            icon: Icons.layers_clear_outlined,
            label: i18nOr('background_clear', 'Clear background'),
            onSelect: bg.setNone,
          ),
          const Spacer(),
          if (busy)
            SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            _ActionChip(
              icon: Icons.refresh,
              label: i18nOr('refresh', 'Refresh'),
              onSelect: onRefresh,
            ),
          SizedBox(width: 8.sp),
          Text(
            '${source.count}',
            style: TextStyle(fontSize: 13.sp, color: theme.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  /// Index of the preset closest to [value], so the cycle continues from
  /// wherever the stored opacity happens to sit.
  int _nearestMaskIndex(double value) {
    var best = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < _kMaskSteps.length; i++) {
      final delta = (_kMaskSteps[i] - value).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    return best;
  }
}

/// One tile. Images load a scaled-down thumbnail, videos show their poster,
/// gradients are painted locally.
class _WallpaperTile extends StatefulWidget {
  const _WallpaperTile({
    required this.item,
    required this.kind,
    required this.current,
    required this.applying,
    required this.onSelect,
  });

  final BackgroundItem item;
  final BackgroundKind kind;
  final bool current;
  final bool applying;
  final VoidCallback onSelect;

  @override
  State<_WallpaperTile> createState() => _WallpaperTileState();
}

class _WallpaperTileState extends State<_WallpaperTile> {
  String? _thumbUrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveThumb();
  }

  @override
  void didUpdateWidget(covariant _WallpaperTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.file != widget.item.file) {
      _thumbUrl = null;
      _failed = false;
      _resolveThumb();
    }
  }

  Future<void> _resolveThumb() async {
    // Videos use their poster image, everything else uses the file itself.
    final raw = await BackgroundRepository.instance.urlOf(
      widget.item.poster ?? widget.item.file,
    );
    if (!mounted) return;
    setState(() => _thumbUrl = raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(12.sp);

    return DpadFocusable(
      autofocus: false,
      effects: <DpadEffect>[
        DpadScaleEffect(
          scale: 1.04,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        ),
        DpadGlowEffect(
          color: theme.focusColor,
          blurRadius: 16,
          borderRadius: radius,
          duration: const Duration(milliseconds: 120),
        ),
        DpadBorderEffect(
          color: theme.focusColor,
          width: 3,
          borderRadius: radius,
          duration: const Duration(milliseconds: 120),
        ),
      ],
      onSelect: widget.onSelect,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: theme.cardColor,
              child: _buildPreview(theme),
            ),
            if (widget.item.bytes != null)
              Positioned(
                right: 6.sp,
                bottom: 6.sp,
                child: _Badge(text: _sizeLabel(widget.item.bytes!)),
              ),
            if (widget.kind == BackgroundKind.video)
              Positioned(
                left: 6.sp,
                bottom: 6.sp,
                child: Icon(
                  Icons.play_circle_fill,
                  size: 20.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            if (widget.current)
              Positioned(
                right: 6.sp,
                top: 6.sp,
                child: Icon(
                  Icons.check_circle,
                  size: 20.sp,
                  color: theme.focusColor,
                ),
              ),
            if (widget.applying)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(TvThemeData theme) {
    if (widget.kind == BackgroundKind.gradient) {
      return _GradientPreview(item: widget.item);
    }
    final thumb = _thumbUrl;
    if (thumb == null) return const SizedBox.shrink();
    if (_failed) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 24.sp,
          color: theme.secondaryTextColor,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: BackgroundRepository.thumbnail(thumb),
      cacheManager: CustomImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: 480,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) => ColoredBox(color: theme.cardColor),
      errorWidget: (context, _, _) {
        // Thumbnail service unavailable, fall back to the full-size file.
        return CachedNetworkImage(
          imageUrl: thumb,
          cacheManager: CustomImageCacheManager.instance,
          fit: BoxFit.cover,
          memCacheWidth: 480,
          errorWidget: (context, _, _) {
            if (!_failed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _failed = true);
              });
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}M';
    }
    return '${(bytes / 1024).round()}K';
  }
}

/// Paints a gradient tile locally; no download involved.
class _GradientPreview extends StatelessWidget {
  const _GradientPreview({required this.item});

  final BackgroundItem item;

  @override
  Widget build(BuildContext context) {
    final stops = item.gradient ?? const <BackgroundGradientStop>[];
    final colors = <Color>[];
    final positions = <double>[];
    for (final stop in stops) {
      colors.add(ColorUtil.hexToColor(stop.color));
      positions.add((stop.pos / 100).clamp(0.0, 1.0));
    }
    if (colors.length < 2) {
      return ColoredBox(
        color: colors.isNotEmpty ? colors.first : const Color(0xFF141E30),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: positions,
        ),
      ),
    );
  }
}

/// Rounded size label drawn over a tile.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
    );
  }
}

/// Compact focusable button used by the toolbar.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onSelect,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(20.sp);

    return DpadFocusable(
      onSelect: onSelect,
      effects: <DpadEffect>[
        DpadScaleEffect(
          scale: 1.05,
          duration: const Duration(milliseconds: 100),
        ),
        DpadBorderEffect(
          color: theme.focusColor,
          width: 2,
          borderRadius: radius,
          duration: const Duration(milliseconds: 100),
        ),
      ],
      child: Container(
        height: 34.sp,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17.sp, color: theme.primaryTextColor),
            SizedBox(width: 6.sp),
            Text(
              label,
              style: TextStyle(fontSize: 14.sp, color: theme.primaryTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// Failure state with a retry button, used for catalog and shard errors.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            Icon(
              Icons.cloud_off_outlined,
              size: 42.sp,
              color: theme.secondaryTextColor,
            ),
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
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.secondaryTextColor,
              ),
            ),
            SizedBox(height: 18.sp),
            DpadFocusable(
              autofocus: true,
              onSelect: onRetry,
              effects: <DpadEffect>[
                DpadScaleEffect(scale: 1.05),
                DpadBorderEffect(
                  color: theme.focusColor,
                  width: 2,
                  borderRadius: radius,
                ),
              ],
              child: Container(
                height: 36.sp,
                padding: EdgeInsets.symmetric(horizontal: 22.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: radius,
                ),
                child: Text(
                  i18nOr('retry', 'Retry'),
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: theme.primaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
