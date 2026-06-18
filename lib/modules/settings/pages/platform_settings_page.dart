import 'package:dpad/dpad.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_menu_dialog.dart';

class PlatformSettingsPage extends GetView<SettingsService> {
  const PlatformSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, String> siteMap = {for (var site in Sites.supportSites) site.id: site.name};

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("platform_settings"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/platform',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("platform_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.apps_2_line,
                      title: i18n("platform_display"),
                      subtitle: i18n("platform_display_subtitle"),
                      onTap: () async => Get.toNamed(RoutePath.kSettingsHotAreas),
                    ),
                    Obx(
                      () => context.buildMenuTile<String>(
                        icon: Remix.heart_3_line,
                        title: i18n("prefer_platform"),
                        value: SettingsService.to.fav.preferPlatform.value,
                        valueMap: siteMap,
                        onChanged: (String newValue) {
                          SettingsService.to.fav.preferPlatform.value = newValue;
                        },
                        onTap: () async => showPreferPlatformSelectorDialog(siteMap),
                      ),
                    ),
                    context.buildTile(
                      icon: Remix.accessibility_line,
                      title: i18n('third_party_auth'),
                      subtitle: i18n('third_party_auth_subtitle'),
                      onTap: () async => Get.toNamed(RoutePath.kSettingsAccount),
                    ),
                    context.buildTile(
                      icon: Remix.price_tag_3_line,
                      title: i18n('tag_management'),
                      onTap: () async => Get.toNamed(RoutePath.kSettingsTags),
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

  void showPreferPlatformSelectorDialog(Map<String, String> siteMap) async {
    final List<TvMenuItem<String>> menuItems = Sites.supportSites.map((site) {
      return TvMenuItem<String>(title: site.name, value: site.id);
    }).toList();

    final selected = await Get.dialog<String>(
      TvMenuDialog<String>(
        title: i18n('prefer_platform'),
        items: menuItems,
        selectedValue: SettingsService.to.fav.preferPlatform.value,
      ),
    );

    if (selected != null) {
      SettingsService.to.fav.preferPlatform.value = selected;
    }
  }
}
