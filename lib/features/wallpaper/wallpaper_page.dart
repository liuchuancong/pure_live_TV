import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';

/// Mask presets. A remote cycles through fixed steps instead of dragging a
/// slider, which is far easier to operate from a couch.
const List<double> _kMaskSteps = <double>[0, 0.2, 0.35, 0.5, 0.7];

/// Fill modes offered in the display-settings group, in the order the old app
/// numbered them.
const List<BoxFit> _kFitModes = <BoxFit>[
  BoxFit.fill,
  BoxFit.contain,
  BoxFit.cover,
  BoxFit.fitWidth,
  BoxFit.fitHeight,
  BoxFit.none,
  BoxFit.scaleDown,
];

String _fitLabel(BoxFit fit) => switch (fit) {
  BoxFit.fill => i18nOr('wallpaper_fit_fill', 'Stretch'),
  BoxFit.contain => i18nOr('wallpaper_fit_contain', 'Fit'),
  BoxFit.cover => i18nOr('wallpaper_fit_cover', 'Cover'),
  BoxFit.fitWidth => i18nOr('wallpaper_fit_fit_width', 'Fit width'),
  BoxFit.fitHeight => i18nOr('wallpaper_fit_fit_height', 'Fit height'),
  BoxFit.none => i18nOr('wallpaper_fit_none', 'Original'),
  BoxFit.scaleDown => i18nOr('wallpaper_fit_scale_down', 'Scale down'),
};

/// Background picker, laid out like the settings pages: one list, three
/// groups. The old two-tabbar layout rebuilt the whole page on every state
/// change and a 19-tab category bar — visibly slow, so browsing is now a
/// drill-down of list pages instead.
class WallpaperPage extends ConsumerStatefulWidget {
  const WallpaperPage({super.key});

  @override
  ConsumerState<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends ConsumerState<WallpaperPage> {
  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(backgroundCatalogProvider);
    final bgState = SettingsService.to.bgState;

    return TvScaffold(
      title: i18nOr('ui_background_settings', 'Background'),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvSettingsGroupTitle(title: i18nOr('wallpaper_library', 'Wallpaper library')),
            TvSettingsCard(
              children: [
                ...catalogAsync.when(
                  loading: () => [_LoadingRow(label: i18nOr('wallpaper_library_loading', 'Loading library...'))],
                  error: (error, _) => [
                    _LoadingRow(label: i18nOr('background_load_failed', 'Failed to load wallpapers')),
                  ],
                  data: (catalog) => catalog.sources.isEmpty
                      ? [_LoadingRow(label: i18nOr('background_catalog_empty', 'Remote catalog is empty'))]
                      : [
                          for (final source in catalog.sources)
                            TvSettingsMenuTile<void>(
                              title: source.localizedName(Localizations.localeOf(context).languageCode),
                              subtitle: i18nOr(
                                'wallpaper_library_subtitle',
                                '{count} items · {categories} categories',
                                args: {'count': '${source.count}', 'categories': '${source.visibleCategories.length}'},
                              ),
                              onTap: () => context.push(AppRoutes.kWallpaperGallery, extra: source),
                            ),
                        ],
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            TvSettingsGroupTitle(title: i18nOr('wallpaper_api_group', 'Random wallpaper APIs')),
            TvSettingsCard(
              children: [
                for (final api in kWallpaperApiSources)
                  TvSettingsMenuTile<void>(
                    title: api.name,
                    subtitle: api.host,
                    onTap: () => context.push(AppRoutes.kWallpaperPreview, extra: WallpaperPreviewArgs.api(api)),
                  ),
              ],
            ),
            SizedBox(height: 20.sp),
            TvSettingsGroupTitle(title: i18nOr('wallpaper_display_group', 'Display settings')),
            TvSettingsCard(
              children: [
                TvSettingsOptionTile(
                  title: i18nOr('wallpaper_fit_mode', 'Fill mode'),
                  icon: Icons.aspect_ratio_outlined,
                  options: [for (final fit in _kFitModes) _fitLabel(fit)],
                  index: _kFitModes.indexOf(bgState.boxFit).clamp(0, _kFitModes.length - 1),
                  onChanged: (index) => SettingsService.to.bg.setBoxFit(_kFitModes[index]),
                ),
                TvSettingsOptionTile(
                  title: i18nOr('background_mask', 'Mask'),
                  icon: Icons.brightness_6_outlined,
                  options: [for (final step in _kMaskSteps) '${(step * 100).round()}%'],
                  index: _nearestMaskIndex(bgState.maskOpacity),
                  onChanged: (index) => SettingsService.to.bg.setMaskOpacity(_kMaskSteps[index]),
                ),
                TvSettingsOptionTile(
                  title: i18nOr('background_clear', 'Clear background'),
                  icon: Icons.layers_clear_outlined,
                  options: const [''],
                  index: 0,
                  onChanged: (_) {
                    SettingsService.to.bg.setNone();
                    ToastUtil.show(i18nOr('wallpaper_background_cleared', 'Background cleared'));
                  },
                ),
              ],
            ),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  /// Index of the preset closest to [value], so the selection highlights the
  /// stored opacity even when it is not exactly one of the presets.
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

/// Placeholder row shown while the catalog (or an error) blocks the library
/// group; the rest of the page stays usable.
class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 14.sp),
      child: Row(
        children: [
          SizedBox(width: 16.sp, height: 16.sp, child: const CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15.sp, color: theme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
