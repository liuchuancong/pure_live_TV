import 'dart:async';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Home-page update dialog: shown once per session, after the startup check,
/// with the version, changelog and a download entry.
class HomeUpdateDialog {
  static bool _shownThisSession = false;

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (_shownThisSession) return;
    _shownThisSession = true;

    if (!SettingsService.to.appState.enableAutoCheckUpdate) return;

    // Waits for the startup check to say something. Sampling the verdict a beat
    // after the first frame always read "no update": the check is deferred a few
    // seconds past those frames, so its answer was never in yet.
    final hasUpdate = await VersionUtil.verdict();

    if (!context.mounted || !hasUpdate) return;

    await TvDialogUtils.show(context: context, builder: (dialogContext) => const _UpdateDialogBody());
  }
}

class _UpdateDialogBody extends ConsumerStatefulWidget {
  const _UpdateDialogBody();

  @override
  ConsumerState<_UpdateDialogBody> createState() => _UpdateDialogBodyState();
}

class _UpdateDialogBodyState extends ConsumerState<_UpdateDialogBody> {
  bool _downloading = false;

  Future<void> _openDownload() async {
    final url = VersionUtil.downloadUrl.trim();

    if (url.isEmpty) {
      // Falls back to the releases page when a source has no direct URL.
      final ok = await FileUtils.openFileOrUrl(VersionUtil.releaseUrl);
      if (!ok && mounted) {
        ToastUtil.show(i18nOr('update_open_failed', 'Unable to open the download page'));
      }
      return;
    }

    setState(() => _downloading = true);
    try {
      final ok = await FileUtils.openFileOrUrl(url);
      if (!mounted) return;
      if (!ok) {
        ToastUtil.show(i18nOr('update_open_failed', 'Unable to open the download page'));
      } else {
        ToastUtil.show(i18nOr('update_opened', 'Download page opened'));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return TvDialog(
      title: i18nOr('update_available_title', 'New version available'),
      confirmText: _downloading ? i18n('ui_loading') : i18nOr('update_download', 'Download'),
      cancelText: i18n('ui_later'),
      onConfirm: _downloading ? null : () => unawaited(_openDownload()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Version comparison row.
          Row(
            children: [
              Icon(Icons.system_update_alt_rounded, size: 28.ts(context), color: theme.focusColor),
              SizedBox(width: 12.ts(context)),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w600, color: theme.primaryTextColor),
                    children: [
                      TextSpan(text: 'v${VersionUtil.version}'),
                      TextSpan(
                        text: '  →  ',
                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor),
                      ),
                      TextSpan(
                        text: 'v${VersionUtil.latestVersion}',
                        style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w600, color: theme.focusColor),
                      ),
                      if (VersionUtil.prerelease)
                        TextSpan(
                          text: '  ${i18nOr('update_prerelease', 'pre-release')}',
                          style: AppTextStyles.t16.copyWith(
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFFFA726),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.ts(context)),
          // Changelog card.
          if (VersionUtil.latestUpdateLog.isNotEmpty) ...[
            Text(
              i18nOr('update_changelog', 'What is new'),
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: theme.secondaryTextColor),
            ),
            SizedBox(height: 8.ts(context)),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxHeight: 260.ts(context)),
              padding: EdgeInsets.all(16.ts(context)),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(12.ts(context)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  VersionUtil.latestUpdateLog,
                  style: AppTextStyles.t18.copyWith(
                    fontWeight: FontWeight.w300,
                    color: theme.primaryTextColor,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
