import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/settings/pages/update_history_page.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';

/// online update: the running version and its check state, the pending release with its
/// notes and assets, and a way into version history.
///
/// The layout changed shape with the history: the full release list now lives on
/// [UpdateHistoryPage] (mirroring the mobile app's version history page), and this page keeps the
/// newest few releases as a preview. States that used to be a bare label — checking, up to
/// date, failed — are drawn with the app's own status view, so a TV user can see whether
/// the box is working or waiting.
class AppUpdatePage extends ConsumerWidget {
  const AppUpdatePage({super.key});

  /// How many releases the preview under version history shows.
  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);

    return TvPageScaffold(
      title: i18n('online_update'),
      actions: <Widget>[
        TvButton(
          title: i18n('check_update'),
          size: TvButtonSize.mini,
          icon: Icon(Remix.refresh_line, size: 22.sp),
          onTap: state.phase == AppUpdatePhase.checking ? null : () => controller.check(userInitiated: true),
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _UpdateHeroHeader(version: state.currentVersion, buildNumber: state.currentBuild),
            SizedBox(height: 24.sp),
            TvSettingsGroupTitle(title: i18n('about')),
            TvSettingsCard(
              children: <Widget>[
                TvSettingsRow(
                  title: i18n('current_version'),
                  subtitle: _currentVersionSubtitle(state, ref),
                  icon: Icons.info_outline_rounded,
                  trailingBuilder: (context, focused) => tvSettingsValueLabel(context, focused, _statusLabel(state)),
                  // Enters the download page (per-ABI sources + markdown changelog);
                  // checking stays on the app bar button and the status view.
                  onSelect: state.phase == AppUpdatePhase.checking
                      ? null
                      : () => const AppDownloadRoute().push(context),
                ),
                _buildStatus(state, controller),
              ],
            ),
            // A new version is no longer an inline card: the download page
            // behind the current-version row carries it, this row keeps the hint.
            SizedBox(height: 24.sp),
            TvSettingsGroupTitle(title: i18n('update_history')),
            TvSettingsCard(children: <Widget>[_buildHistory(context, state, controller)]),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  /// `v1.2.3+45 · mirror` — the mirror suffix is part of reading the state.
  String _currentVersionSubtitle(AppUpdateState state, WidgetRef ref) {
    final bool origin = ref.watch(appSettingsControllerProvider).useGitHubOriginForUpdates;
    final String source = origin ? i18n('update_source_origin') : i18n('update_source_mirror');
    if (state.currentVersion.isEmpty) return source;
    return 'v${state.currentVersion}+${state.currentBuild} · $source';
  }

  String _statusLabel(AppUpdateState state) {
    return switch (state.phase) {
      AppUpdatePhase.checking => i18n('ui_loading'),
      AppUpdatePhase.upToDate => i18n('already_latest_version'),
      AppUpdatePhase.available ||
      AppUpdatePhase.downloading ||
      AppUpdatePhase.readyToInstall => '${i18n('new_version_found')} ${state.latestVersion}',
      AppUpdatePhase.failed => i18n('check_update_failed'),
      _ => i18n('check_update'),
    };
  }

  /// The check states, drawn instead of described.
  Widget _buildStatus(AppUpdateState state, AppUpdateController controller) {
    switch (state.phase) {
      case AppUpdatePhase.checking:
        return SizedBox(
          height: 180.h,
          child: AppStatusView(
            type: AppStatusType.loading,
            subtitle: i18n('check_update'),
            isMini: true,
          ),
        );
      case AppUpdatePhase.upToDate:
        return SizedBox(
          height: 180.h,
          child: AppStatusView(
            type: AppStatusType.empty,
            title: i18n('already_latest_version'),
            subtitle: state.latestVersion.isEmpty ? '' : 'v${state.currentVersion}+${state.currentBuild}',
            isMini: true,
          ),
        );
      case AppUpdatePhase.failed:
        return SizedBox(
          height: 200.h,
          child: AppStatusView(
            type: AppStatusType.error,
            title: i18n('check_update_failed'),
            subtitle: state.error,
            buttonText: i18n('retry'),
            onTap: () => controller.check(userInitiated: true),
            isMini: true,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// The version history entry, a preview of the newest releases and its own load state.
  Widget _buildHistory(BuildContext context, AppUpdateState state, AppUpdateController controller) {
    final tvTheme = context.tvTheme;
    return Column(
      children: <Widget>[
        TvSettingsNavTile(
          title: i18n('version_history'),
          subtitle: state.history.isEmpty
              ? i18n('update_view_log')
              : '${state.history.length} · ${i18n('already_latest_version')} v${state.history.first.version}',
          icon: Remix.history_line,
          onTap: () => const UpdateHistoryRoute().push(context),
        ),
        for (final ReleaseModel release in state.history.take(_previewCount))
          TvSettingsRow(
            title: 'v${release.version}',
            subtitle: releaseSubtitle(release),
            icon: Icons.article_outlined,
            trailingBuilder: (context, focused) => tvSettingsValueLabel(
              context,
              focused,
              release.version == state.currentVersion ? i18n('font_in_use') : i18n('update_view_log'),
            ),
            onSelect: () => showReleaseNotesDialog(context: context, release: release, controller: controller),
          ),
        if (state.history.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                state.historyLoading
                    ? i18n('update_loading_history')
                    : state.historyError != null
                    ? i18n('update_history_failed')
                    : i18n('update_no_history'),
                style: TextStyle(fontSize: 15.sp, color: tvTheme.secondaryTextColor),
              ),
            ),
          ),
      ],
    );
  }
}

/// The about-style header: centred app icon, name and a version pill, matching
/// the mobile app's about page.
class _UpdateHeroHeader extends StatelessWidget {
  const _UpdateHeroHeader({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final hasVersion = version.isNotEmpty;

    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 96.sp,
            height: 96.sp,
            decoration: BoxDecoration(
              color: tvTheme.cardColor,
              borderRadius: BorderRadius.circular(24.sp),
              border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35), width: 1.sp),
              boxShadow: [
                BoxShadow(color: tvTheme.focusColor.withValues(alpha: 0.25), blurRadius: 18.sp, spreadRadius: 2.sp),
              ],
            ),
            padding: EdgeInsets.all(14.sp),
            child: Image.asset('assets/icons/icon.png', fit: BoxFit.contain),
          ),
          SizedBox(height: 14.sp),
          Text(
            i18n('ui_pure_live_tv'),
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: tvTheme.primaryTextColor),
          ),
          if (hasVersion) ...<Widget>[
            SizedBox(height: 8.sp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: tvTheme.focusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999.sp),
              ),
              child: Text(
                'v$version+$buildNumber',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: tvTheme.focusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
