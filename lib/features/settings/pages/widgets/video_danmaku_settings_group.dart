import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';

/// The danmaku group: the three danmaku destinations.
class VideoDanmakuSettingsGroup extends ConsumerWidget {
  const VideoDanmakuSettingsGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.ts(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('danmaku_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('danmaku_settings'),
                subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
                icon: Remix.chat_settings_line,
                onTap: () => const DanmakuSettingsRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('change_danmaku_font_family'),
                icon: Remix.font_size,
                // Danmaku mode: the selection writes danmakuFontFamilyName and
                // the flame engine picks it up live, instead of the old path
                // that silently changed the whole app font.
                onTap: () => const FontFamilyDanmakuRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('danmaku_filter'),
                icon: Remix.filter_2_line,
                onTap: () => const DanmuShieldRoute().push(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
