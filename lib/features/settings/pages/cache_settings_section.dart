import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/cache/cache_controller.dart';

/// Cache and data management, in the mobile page's order: the current size
/// (re-measured when selected) and the confirmed clear.
class CacheSettingsSectionPage extends ConsumerStatefulWidget {
  const CacheSettingsSectionPage({super.key});

  @override
  ConsumerState<CacheSettingsSectionPage> createState() => CacheSettingsSectionPageState();
}

class CacheSettingsSectionPageState extends ConsumerState<CacheSettingsSectionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cacheControllerProvider.notifier).getCacheSize();
    });
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
    await ref.read(cacheControllerProvider.notifier).getCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(cacheControllerProvider);
    final cache = ref.read(cacheControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('current_cache_size'),
          subtitle: i18n('cache_size_used', args: {'size': cacheState.cacheSizeMB.toStringAsFixed(1)}),
          icon: Remix.database_2_line,
          options: [i18n('refresh')],
          index: 0,
          onChanged: (_) => cache.getCacheSize(),
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
    );
  }
}
