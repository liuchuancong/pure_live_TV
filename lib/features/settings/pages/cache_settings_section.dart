import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/cache/cache_controller.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:remixicon/remixicon.dart';

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

  @override
  Widget build(BuildContext context) {
    final cacheState = ref.watch(cacheControllerProvider);
    final cache = ref.read(cacheControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_image_and_data_cache'),
          subtitle: i18n('cache_size_used', args: {'size': cacheState.cacheSizeMB.toStringAsFixed(1)}),
          icon: Remix.delete_bin_6_line,
          options: [i18n('clear')],
          index: 0,
          onChanged: (_) => cache.clearCache(),
        ),
      ],
    );
  }
}
