import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

/// Chooses which audience number the cards and rankings use: the platform heat
/// value or the concurrent online count, per platform.
class AudienceMetricSectionPage extends ConsumerWidget {
  const AudienceMetricSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('audience_display_mode')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('audience_metric_settings'),
                subtitle: i18n('audience_metric_settings_desc'),
                icon: Icons.insights_rounded,
                options: [i18n('audience_mode_heat'), i18n('audience_mode_online')],
                index: appState.preferRealOnlineCounts ? 1 : 0,
                onChanged: (index) => app.update(appState.copyWith(preferRealOnlineCounts: index == 1)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsGroupTitle(title: i18n('audience_online_platforms')),
          TvSettingsCard(
            children: [
              for (final site in Sites.supportSites)
                _AudiencePlatformTile(
                  id: site.id,
                  label: site.name,
                  detailKey: 'audience_${site.id}_detail',
                  enabled: app.isRealOnlineEnabledFor(site.id),
                  onChanged: (value) => app.setRealOnlineEnabledFor(site.id, value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One platform row of the audience settings.
///
/// A platform that never publishes a concurrent head count stays visible but
/// read-only, so the row explains why it cannot be selected instead of letting
/// the user switch on a number the platform does not expose.
class _AudiencePlatformTile extends StatelessWidget {
  const _AudiencePlatformTile({
    required this.id,
    required this.label,
    required this.detailKey,
    required this.enabled,
    required this.onChanged,
  });

  final String id;
  final String label;
  final String detailKey;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final capability = LiveRoom.audienceCapabilityFor(id);
    final supported = capability.supportsConcurrentOnline;
    final sourceLabel = supported
        ? i18n(capability.onlineAvailableInRoomLists ? 'audience_source_room_list' : 'audience_source_room_realtime')
        : i18n('audience_source_not_exposed');

    return TvSettingsSwitchTile(
      title: label,
      subtitle: '$sourceLabel · ${i18nOr(detailKey, i18n('audience_metric_support_summary'))}',
      icon: supported ? Icons.people_alt_rounded : Icons.whatshot_rounded,
      value: supported && enabled,
      onChanged: supported ? onChanged : null,
    );
  }
}
