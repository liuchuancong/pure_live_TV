import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';

/// version history — the release list the update page links to, plus local update log.
///
/// Mirrors the mobile app's `version_history.dart`: one row per release (version, date,
/// APK size, pre-release mark), a detail dialog with the changelog and the release
/// assets, a refresh action, and loading/error/empty states instead of a blank page.
/// The device record on top is TV-specific: the release list alone cannot tell the user
/// why the box is still on the old version, but "downloaded, installer opened, failed"
/// can.
class UpdateHistoryPage extends ConsumerStatefulWidget {
  const UpdateHistoryPage({super.key});

  @override
  ConsumerState<UpdateHistoryPage> createState() => _UpdateHistoryPageState();
}

class _UpdateHistoryPageState extends ConsumerState<UpdateHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The update page usually loaded it already; a direct visit (deep link, or after a
      // failed first attempt) has to fetch it.
      final state = ref.read(appUpdateControllerProvider);
      if (state.history.isEmpty && !state.historyLoading) {
        ref.read(appUpdateControllerProvider.notifier).loadHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);

    return TvPageScaffold(
      title: i18n('version_history'),
      actions: <Widget>[
        TvButton(
          title: i18n('refresh'),
          size: TvButtonSize.mini,
          icon: Icon(Remix.refresh_line, size: 22.sp),
          onTap: state.historyLoading ? null : controller.loadHistory,
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildRecordsHeader(state, controller),
            TvSettingsCard(children: <Widget>[_buildRecords(state)]),
            SizedBox(height: 24.sp),
            TvSettingsGroupTitle(
              title: state.currentVersion.isEmpty
                  ? i18n('version_history')
                  : '${i18n('version_history')} · ${i18n('current_version')}v${state.currentVersion}',
            ),
            TvSettingsCard(children: <Widget>[_buildReleases(state, controller)]),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsHeader(AppUpdateState state, AppUpdateController controller) {
    return Row(
      children: <Widget>[
        Expanded(child: TvSettingsGroupTitle(title: i18n('update_local_records'))),
        if (state.records.isNotEmpty)
          TvButton(
            title: i18n('clear'),
            size: TvButtonSize.mini,
            isSecondary: true,
            onTap: () => _confirmClearRecords(controller),
          ),
      ],
    );
  }

  Future<void> _confirmClearRecords(AppUpdateController controller) async {
    await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('update_local_records'),
      message: i18n('clear'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: controller.clearRecords,
    );
  }

  Widget _buildRecords(AppUpdateState state) {
    if (state.records.isEmpty) {
      return _hint(i18n('update_no_records'));
    }
    return Column(
      children: <Widget>[
        for (final AppUpdateRecord record in state.records)
          TvSettingsRow(
            title: _actionLabel(record.action),
            subtitle: '${_formatTime(record.time)}${record.version.isEmpty ? '' : ' · v${record.version}'}',
            icon: _actionIcon(record.action),
            trailingBuilder: (context, focused) =>
                tvSettingsValueLabel(context, focused, record.version.isEmpty ? '' : 'v${record.version}'),
            // The record is a log line, not an action.
            onSelect: null,
          ),
      ],
    );
  }

  Widget _buildReleases(AppUpdateState state, AppUpdateController controller) {
    if (state.historyLoading && state.history.isEmpty) {
      return SizedBox(
        height: 220.h,
        child: const AppStatusView(type: AppStatusType.loading),
      );
    }
    if (state.historyError != null && state.history.isEmpty) {
      return SizedBox(
        height: 220.h,
        child: AppStatusView(
          type: AppStatusType.error,
          title: i18n('update_history_failed'),
          subtitle: state.historyError,
          buttonText: i18n('retry'),
          onTap: controller.loadHistory,
        ),
      );
    }
    if (state.history.isEmpty) {
      return _hint(i18n('update_no_history'));
    }

    return Column(
      children: <Widget>[
        for (final ReleaseModel release in state.history)
          TvSettingsRow(
            title: 'v${release.version}',
            subtitle: releaseSubtitle(release),
            icon: Icons.article_outlined,
            trailingBuilder: (context, focused) => tvSettingsValueLabel(
              context,
              focused,
              release.version == state.currentVersion ? i18n('font_in_use') : i18n('update_view_log'),
            ),
            onSelect: () => showReleaseNotesDialog(
              context: context,
              release: release,
              controller: controller,
              onDownloadStarted: _backToUpdatePage,
            ),
          ),
      ],
    );
  }

  /// `date · size · downloads`, plus the pre-release mark.
  /// Progress for a download started here lives on the update page, which owns the
  /// progress bar; when this page was opened from it, the pop lands right back on it.
  void _backToUpdatePage() {
    if (!mounted) return;
    final NavigatorState? navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    // Reached directly (a widget test, or a future deep link): open the update page so the
    // download is not invisible.
    // Typed navigation needs a router in scope; a bare widget test has none.
    final GoRouter? router = GoRouter.maybeOf(context);
    if (router != null) const AppUpdateRoute().push(context);
  }

  Widget _hint(String label) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(fontSize: 15.sp, color: tvTheme.secondaryTextColor),
        ),
      ),
    );
  }

  String _actionLabel(AppUpdateAction action) => switch (action) {
    AppUpdateAction.checked => i18n('update_record_checked'),
    AppUpdateAction.available => i18n('update_record_available'),
    AppUpdateAction.downloaded => i18n('update_record_downloaded'),
    AppUpdateAction.installed => i18n('update_record_installed'),
    AppUpdateAction.failed => i18n('update_record_failed'),
  };

  IconData _actionIcon(AppUpdateAction action) => switch (action) {
    AppUpdateAction.checked => Icons.refresh_rounded,
    AppUpdateAction.available => Icons.new_releases_outlined,
    AppUpdateAction.downloaded => Icons.download_done_rounded,
    AppUpdateAction.installed => Icons.install_mobile_rounded,
    AppUpdateAction.failed => Icons.error_outline_rounded,
  };

  /// `2026-09-17 20:15` — fixed width, so the list reads as a log.
  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
}

/// `2026-09-17 · 18.4 MB · 320 ↓ · preview`, shared by version history and the preview rows on
/// online update so one release never reads differently on the two pages.
String releaseSubtitle(ReleaseModel release) {
  final List<String> parts = <String>[];
  if (release.date.isNotEmpty) parts.add(release.date);
  final ReleaseFileModel? file = release.files.isEmpty ? null : release.files.first;
  if (file != null && file.size.isNotEmpty) parts.add(file.size);
  if (file != null && file.downloads > 0) parts.add('${file.downloads} ↓');
  if (release.title.isNotEmpty && release.title.toLowerCase().contains('pre')) {
    parts.add(i18n('update_prerelease'));
  }
  return parts.join(' · ');
}

/// The changelog + assets dialog of one release.
///
/// Shared with online update's preview rows. Installing any release listed here is also the
/// rollback path: [AppUpdateController.downloadAndInstallUrl] takes an arbitrary asset
/// url through the same mirrors and the same installer.
Future<void> showReleaseNotesDialog({
  required BuildContext context,
  required ReleaseModel release,
  required AppUpdateController controller,
  VoidCallback? onDownloadStarted,
}) async {
  await TvDialogUtils.show<void>(
    context: context,
    builder: (dialogContext) {
      final tvTheme = dialogContext.tvTheme;
      final String notes = cleanReleaseNotes(release.changeLog);
      return TvDialog(
        title: 'v${release.version}${release.date.isEmpty ? '' : ' · ${release.date}'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              height: 380.sp,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (release.date.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 12.sp),
                        child: Text(
                          i18n('version_published_at', args: <String, String>{'date': release.date}),
                          style: TextStyle(fontSize: 13.sp, color: tvTheme.secondaryTextColor),
                        ),
                      ),
                    Text(
                      notes.isEmpty ? i18n('update_no_notes') : notes,
                      style: TextStyle(fontSize: 16.sp, height: 1.5, color: tvTheme.primaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
            if (release.files.isNotEmpty) ...<Widget>[
              SizedBox(height: 16.sp),
              Text(
                i18n('update_assets'),
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: tvTheme.secondaryTextColor),
              ),
              SizedBox(height: 10.sp),
              Wrap(
                spacing: 12.sp,
                runSpacing: 12.sp,
                children: <Widget>[
                  for (final ReleaseFileModel file in release.files)
                    TvButton(
                      title: '${file.name}${file.size.isEmpty ? '' : ' · ${file.size}'}',
                      size: TvButtonSize.mini,
                      icon: Icon(Icons.download_rounded, size: 20.sp),
                      onTap: file.url.startsWith('http')
                          ? () {
                              Navigator.of(dialogContext).pop();
                              controller.downloadAndInstallUrl(file.url);
                              onDownloadStarted?.call();
                            }
                          : null,
                    ),
                ],
              ),
            ],
            SizedBox(height: 20.sp),
            Align(
              alignment: Alignment.centerRight,
              child: TvButton(
                title: i18n('close'),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
