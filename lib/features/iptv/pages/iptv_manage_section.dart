import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/app/router/app_router.dart';

/// IPTV page: the entry menu only. Every concern lives on its own screen —
/// the resource list, import, auto-sync and request headers — and every one of
/// those screens carries the QR card, so anything that needs typing happens on
/// the phone.
class IptvManageSectionPage extends ConsumerStatefulWidget {
  const IptvManageSectionPage({super.key});

  @override
  ConsumerState<IptvManageSectionPage> createState() => IptvManageSectionPageState();
}

class IptvManageSectionPageState extends ConsumerState<IptvManageSectionPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 24.h),
        TvSettingsGroupTitle(title: i18n('iptv_settings')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('iptv_resource_list'),
              subtitle: i18n('iptv_resource_list_desc'),
              icon: Icons.playlist_play_rounded,
              onTap: () => const IptvResourcesRoute().push(context),
            ),
            TvSettingsNavTile(
              title: i18n('iptv_import_source'),
              subtitle: i18n('iptv_import_source_desc'),
              icon: Icons.playlist_add_rounded,
              onTap: () => const IptvImportRoute().push(context),
            ),
            TvSettingsNavTile(
              title: i18n('auto_sync_settings'),
              subtitle: i18n('iptv_sync_entry_desc'),
              icon: Icons.sync_rounded,
              onTap: () => const IptvSyncRoute().push(context),
            ),
            TvSettingsNavTile(
              title: i18n('iptv_headers_settings'),
              subtitle: i18n('iptv_headers_entry_desc'),
              icon: Icons.vpn_key_rounded,
              onTap: () => const IptvHeadersRoute().push(context),
            ),
          ],
        ),
      ],
    );
  }
}
