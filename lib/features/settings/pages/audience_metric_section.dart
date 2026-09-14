import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

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
          TvSettingsCard(
            children: [
              for (final site in Sites.supportSites)
                TvSettingsSwitchTile(
                  title: site.name,
                  subtitle: i18nOr('audience_${site.id}_detail', i18n('audience_metric_support_summary')),
                  icon: Icons.bar_chart_rounded,
                  value: appState.realOnlinePlatforms.contains(site.id),
                  onChanged: (enabled) {
                    final platforms = List<String>.from(appState.realOnlinePlatforms);
                    if (enabled) {
                      if (!platforms.contains(site.id)) platforms.add(site.id);
                    } else {
                      platforms.remove(site.id);
                    }
                    app.update(appState.copyWith(realOnlinePlatforms: platforms));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
