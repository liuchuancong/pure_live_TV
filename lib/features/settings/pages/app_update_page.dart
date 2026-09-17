import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 在线更新: current version, the pending release with its changelog and a
/// download+install flow driven by [AppUpdateController], plus the release
/// history (更新历史) fetched from the repo manifest.
class AppUpdatePage extends ConsumerWidget {
  const AppUpdatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);

    return TvPageScaffold(
      title: i18nOr('online_update', 'Online update'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvSettingsGroupTitle(title: i18n('ui_pure_live_tv')),
            TvSettingsCard(
              children: [
                TvSettingsRow(
                  title: i18n('current_version'),
                  subtitle: state.currentVersion.isEmpty
                      ? i18n('ui_loading')
                      : 'v${state.currentVersion}+${state.currentBuild}',
                  icon: Icons.info_outline_rounded,
                  trailingBuilder: (context, focused) {
                    final String label = switch (state.phase) {
                      AppUpdatePhase.checking => i18n('ui_loading'),
                      AppUpdatePhase.upToDate => i18n('already_latest_version'),
                      AppUpdatePhase.available ||
                      AppUpdatePhase.downloading ||
                      AppUpdatePhase.readyToInstall => '${i18n('new_version_found')} ${state.latestVersion}',
                      AppUpdatePhase.failed => i18n('check_update_failed'),
                      _ => i18n('check_update'),
                    };
                    return tvSettingsValueLabel(context, focused, label);
                  },
                  onSelect: state.phase == AppUpdatePhase.checking ? null : () => controller.check(),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            if (state.phase == AppUpdatePhase.available ||
                state.phase == AppUpdatePhase.downloading ||
                state.phase == AppUpdatePhase.readyToInstall) ...[
              _NewVersionCard(state: state, controller: controller),
              SizedBox(height: 20.sp),
            ],
            TvSettingsGroupTitle(title: i18nOr('update_history', 'Release history')),
            TvSettingsCard(children: [_buildHistory(context, state, controller)]),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(BuildContext context, AppUpdateState state, AppUpdateController controller) {
    if (state.historyLoading) {
      return _hintRow(context, i18nOr('update_loading_history', 'Loading release history...'));
    }
    if (state.historyError != null) {
      return TvSettingsOptionTile(
        title: i18nOr('update_history_failed', 'Failed to load release history'),
        subtitle: state.historyError,
        icon: Icons.error_outline_rounded,
        options: [i18n('retry')],
        index: 0,
        onChanged: (_) => controller.loadHistory(),
      );
    }
    if (state.history.isEmpty) {
      return _hintRow(context, i18nOr('update_no_history', 'No release history yet'));
    }
    return Column(
      children: [
        for (final release in state.history)
          TvSettingsRow(
            title: 'v${release.version}',
            subtitle: '${release.date}${release.changeLog.trim().isEmpty ? '' : ' · ${_firstChangelogLine(release.changeLog)}'}',
            icon: Icons.article_outlined,
            trailingBuilder: (context, focused) => tvSettingsValueLabel(
              context,
              focused,
              release.version == state.latestVersion ? i18n('font_in_use') : i18nOr('update_view_log', 'Changelog'),
            ),
            onSelect: () => _showHistoryDetail(context, release, state, controller),
          ),
      ],
    );
  }

  String _firstChangelogLine(String changelog) {
    final cleaned = _cleanMarkdown(changelog);
    final line = cleaned.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return line.trim();
  }

  Future<void> _showHistoryDetail(
    BuildContext context,
    dynamic release,
    AppUpdateState state,
    AppUpdateController controller,
  ) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (dialogContext) => TvDialog(
        title: 'v${release.version} · ${release.date}',
        cancelText: i18n('close'),
        onCancel: () => Navigator.of(dialogContext).pop(),
        child: SizedBox(
          width: 720.w,
          height: 520.sp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _cleanMarkdown(release.changeLog).isEmpty
                        ? i18nOr('update_no_notes', 'No release notes')
                        : _cleanMarkdown(release.changeLog),
                    style: TextStyle(fontSize: 15.sp, height: 1.5, color: context.tvTheme.primaryTextColor),
                  ),
                ),
              ),
              SizedBox(height: 16.sp),
              Text(
                i18nOr('update_assets', 'Download files'),
                style: TextStyle(fontSize: 14.sp, color: context.tvTheme.secondaryTextColor),
              ),
              SizedBox(height: 8.sp),
              for (final file in release.files)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.sp),
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 16.sp, color: context.tvTheme.focusColor),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: Text(
                          '${file.name} · ${file.size}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp, color: context.tvTheme.primaryTextColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          controller.downloadAndInstallUrl(file.url);
                        },
                        child: Text(i18n('download'), style: TextStyle(fontSize: 13.sp)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Strips markdown tables/headers that the release manifest embeds; the TV
  /// changelog view is plain text.
  String _cleanMarkdown(String raw) {
    final buffer = <String>[];
    for (final line in raw.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('|')) continue;
      if (trimmed.startsWith('#')) {
        final withoutHash = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        if (withoutHash.isNotEmpty) buffer.add(withoutHash);
        continue;
      }
      if (trimmed.startsWith('---')) continue;
      buffer.add(line);
    }
    return buffer.join('\n').trim();
  }
}

class _NewVersionCard extends ConsumerWidget {
  const _NewVersionCard({required this.state, required this.controller});

  final AppUpdateState state;
  final AppUpdateController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: '${i18n('new_version_found')} v${state.latestVersion}'),
        TvSettingsCard(
          children: [
            if (state.prerelease)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 2.sp),
                    decoration: BoxDecoration(
                      color: theme.focusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Text(
                      i18nOr('update_prerelease', 'Pre-release'),
                      style: TextStyle(fontSize: 12.sp, color: theme.focusColor),
                    ),
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(maxHeight: 260.sp),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: SingleChildScrollView(
                child: Text(
                  state.changelog.isEmpty ? i18nOr('update_no_notes', 'No release notes') : state.changelog,
                  style: TextStyle(fontSize: 15.sp, height: 1.5, color: theme.primaryTextColor),
                ),
              ),
            ),
            if (state.abis.length > 1) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.sp,
                    children: [
                      for (final abi in state.abis)
                        TvButton(
                          title: abi,
                          size: TvButtonSize.mini,
                          selected: state.selectedAbi == abi,
                          onTap: state.phase == AppUpdatePhase.downloading ? null : () => controller.pickAbi(abi),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: _buildAction(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(BuildContext context) {
    final theme = context.tvTheme;

    switch (state.phase) {
      case AppUpdatePhase.downloading:
        final totalText = state.totalBytes > 0
            ? '${(state.receivedBytes / 1048576).toStringAsFixed(1)} / ${(state.totalBytes / 1048576).toStringAsFixed(1)} MB'
            : '${(state.receivedBytes / 1048576).toStringAsFixed(1)} MB';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6.sp),
              child: LinearProgressIndicator(
                value: state.totalBytes > 0 ? state.progress : null,
                minHeight: 8.sp,
                color: theme.focusColor,
                backgroundColor: theme.cardColor,
              ),
            ),
            SizedBox(height: 8.sp),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$totalText${state.speedMbps > 0 ? ' · ${state.speedMbps.toStringAsFixed(1)} MB/s' : ''}',
                    style: TextStyle(fontSize: 13.sp, color: theme.secondaryTextColor),
                  ),
                ),
                TvButton(
                  title: i18n('cancel'),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: controller.cancelDownload,
                ),
              ],
            ),
          ],
        );
      case AppUpdatePhase.readyToInstall:
        return TvButton(
          title: i18nOr('update_install_now', 'Install now'),
          size: TvButtonSize.small,
          icon: Icon(Icons.install_mobile_rounded, size: 18.sp),
          onTap: controller.installDownloaded,
        );
      case AppUpdatePhase.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error.isNotEmpty)
              Text(
                state.error,
                style: TextStyle(fontSize: 13.sp, color: theme.secondaryTextColor),
              ),
            SizedBox(height: 6.sp),
            TvButton(
              title: i18nOr('update_download_install', 'Download & install'),
              size: TvButtonSize.small,
              icon: Icon(Icons.download_rounded, size: 18.sp),
              onTap: () => controller.downloadAndInstall(),
            ),
          ],
        );
      default:
        return Row(
          children: [
            TvButton(
              title: i18nOr('update_download_install', 'Download & install'),
              size: TvButtonSize.small,
              icon: Icon(Icons.download_rounded, size: 18.sp),
              onTap: () => controller.downloadAndInstall(),
            ),
            SizedBox(width: 12.sp),
            if (state.error.isNotEmpty)
              Expanded(
                child: Text(
                  state.error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: theme.secondaryTextColor),
                ),
              ),
          ],
        );
    }
  }
}

Widget _hintRow(BuildContext context, String label) {
  final theme = context.tvTheme;
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
    child: Row(
      children: [
        SizedBox(
          width: 16.sp,
          height: 16.sp,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12.sp),
        Expanded(child: Text(label, style: TextStyle(fontSize: 15.sp, color: theme.secondaryTextColor))),
      ],
    ),
  );
}