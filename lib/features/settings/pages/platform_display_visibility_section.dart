import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';

/// 平台显示 — 显示项目: which platforms appear in 热门 / 分区.
///
/// One switch per supported platform, each with its logo. Turning the last one off
/// is refused: a platform list with nothing in it leaves those pages empty, which
/// reads as a broken app rather than as a setting.
class PlatformDisplayVisibilitySectionPage extends ConsumerWidget {
  const PlatformDisplayVisibilitySectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final List<String> enabled = favState.hotAreasList;
    // Compared without case: a migrated profile can hold a platform id in the
    // platform's own spelling.
    final Set<String> enabledKeys = <String>{for (final id in enabled) id.trim().toLowerCase()};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('platform_display_visibility')),
        TvSettingsCard(
          children: [
            for (final site in Sites.supportSites)
              TvSettingsSwitchTile(
                title: site.name,
                leading: TvPlatformLogo(logo: site.logo),
                value: enabledKeys.contains(site.id),
                onChanged: (value) {
                  if (!value && enabled.length <= 1) {
                    ToastUtil.show(i18n('at_least_one_platform_required'));
                    return;
                  }
                  fav.toggleSiteEnabled(site.id, value);
                },
              ),
          ],
        ),
      ],
    );
  }
}
