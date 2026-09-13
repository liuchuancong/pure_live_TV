import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/cache/cache_controller.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';

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
          title: '图片与数据缓存',
          subtitle: '当前占用 ${cacheState.cacheSizeMB.toStringAsFixed(1)} MB',
          icon: Icons.cleaning_services_rounded,
          options: const ['清除'],
          index: 0,
          onChanged: (_) => cache.clearCache(),
        ),
      ],
    );
  }
}
