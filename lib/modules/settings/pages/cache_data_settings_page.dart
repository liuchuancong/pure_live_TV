import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_confirm_dialog.dart';

class CacheDataSettingsPage extends StatelessWidget {
  const CacheDataSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("cache_and_data"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/cache_data',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("cache_and_data")),
                  context.buildModernCard([
                    Obx(() {
                      final size = SettingsService.to.cache.cacheSizeMB.value;
                      final turns = SettingsService.to.cache.refreshTurns.value;
                      return context.buildTile(
                        icon: Remix.database_2_line,
                        title: i18n("current_cache_size"),
                        subtitle: "",
                        onTap: () => SettingsService.to.cache.handleManualRefresh(),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "${size.toStringAsFixed(2)} MB",
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: turns,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutCubic,
                              child: Icon(Remix.refresh_line, size: 16, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }),
                    context.buildTile(
                      icon: Remix.delete_bin_6_line,
                      title: i18n("clear_all_cache"),
                      subtitle: i18n("clear_all_cache_meida_desc"),
                      onTap: () async {
                        Get.dialog(
                          TvConfirmDialog(
                            title: i18n("confirm_clear_cache"),
                            message: i18n("confirm_clear_meida_desc"),
                            onConfirm: () async {
                              await SettingsService.to.cache.clearCache();
                              Get.snackbar(i18n("done"), i18n("cache_cleared"), snackPosition: SnackPosition.bottom);
                            },
                          ),
                        );
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
