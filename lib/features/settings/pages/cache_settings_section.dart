import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/services/cache/cache_controller.dart';

/// Cache and data management, mirroring the mobile page: the current size
/// (re-measured when selected), the thumbnail refresh, then the confirmed clear.
class CacheSettingsSectionPage extends ConsumerStatefulWidget {
  const CacheSettingsSectionPage({super.key});

  @override
  ConsumerState<CacheSettingsSectionPage> createState() => CacheSettingsSectionPageState();
}

class CacheSettingsSectionPageState extends ConsumerState<CacheSettingsSectionPage> {
  String _result = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cacheControllerProvider.notifier).getCacheSize();
    });
  }

  Future<void> _rescan() async {
    setState(() => _result = '');
    await ref.read(cacheControllerProvider.notifier).getCacheSize();
  }

  /// Drops the encoded thumbnail cache and rolls the visible covers onto a new
  /// cache key (`imageCacheEpoch`), which is what makes the refresh visible on
  /// screen instead of only freeing disk space.
  Future<void> _refreshThumbnails() async {
    setState(() => _result = '');
    await ref.read(cacheControllerProvider.notifier).refreshImageCache();
    if (!mounted) return;
    setState(() => _result = i18n('thumbnail_refresh_done'));
  }

  Future<void> _clearCache() async {
    final bool? confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('clear_local_cache'),
      message: i18n('confirm_clear_local_cache'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true) return;
    await ref.read(cacheControllerProvider.notifier).clearCache();
    if (!mounted) return;
    setState(() => _result = i18n('clear_success'));
  }

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(cacheControllerProvider);
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('cache_and_data')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('current_cache_size'),
              subtitle: i18n('cache_size_used', args: {'size': cacheState.cacheSizeMB.toStringAsFixed(1)}),
              icon: Remix.database_2_line,
              options: [i18n('refresh')],
              index: 0,
              onChanged: (_) => _rescan(),
            ),
            TvSettingsOptionTile(
              title: i18n('refresh_thumbnails'),
              subtitle: cacheState.isRefreshingImages ? i18n('ui_loading') : i18n('refresh_thumbnails_subtitle'),
              icon: Remix.image_line,
              options: [i18n('refresh')],
              index: 0,
              onChanged: cacheState.isRefreshingImages ? (_) {} : (_) => _refreshThumbnails(),
            ),
            TvSettingsOptionTile(
              title: i18n('clear_local_cache'),
              subtitle: i18n('ui_image_and_data_cache'),
              icon: Remix.delete_bin_6_line,
              options: [i18n('clear')],
              index: 0,
              onChanged: (_) => _clearCache(),
            ),
          ],
        ),
        if (_result.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.sp, top: 8.sp),
            child: Text(_result, style: AppTextStyles.t16W500.copyWith(color: theme.focusColor)),
          ),
      ],
    );
  }
}
