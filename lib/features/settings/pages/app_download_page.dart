import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The download page behind 在线更新's 当前版本 row — the TV twin of the mobile
/// app's version update page: a platform card with one section per ABI, every
/// section offering the release package through each mirror as a pickable
/// 下载源 button, and the release notes rendered as markdown at the bottom.
///
/// Unlike the plain 下载安装 row on the update page (which races the mirrors
/// itself), a source picked here is tried first — "下载源 3" really means
/// source 3 — with the remaining mirrors kept as fallback.
class AppDownloadPage extends ConsumerWidget {
  const AppDownloadPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateControllerProvider);
    final controller = ref.read(appUpdateControllerProvider.notifier);
    final useOrigin = ref.watch(appSettingsControllerProvider).useGitHubOriginForUpdates;

    return TvPageScaffold(
      title: i18n('version_update'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TvSettingsGroupTitle(title: 'Android'),
            TvSettingsCard(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: BoxDecoration(
                          color: context.tvTheme.focusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.sp),
                        ),
                        child: Icon(Icons.android_rounded, color: context.tvTheme.focusColor, size: 28.sp),
                      ),
                      SizedBox(width: 14.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Android', style: AppTextStyles.t20W600),
                            SizedBox(height: 2.sp),
                            Text(
                              i18n('android_desc'),
                              style: TextStyle(fontSize: 15.sp, color: context.tvTheme.secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Renderer variant picker: the dual-variant releases publish
                // Impeller and Skia APKs per ABI; the choice persists and the
                // 下载源 buttons below resolve to the selected variant.
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.layers_rounded, size: 20.sp, color: context.tvTheme.secondaryTextColor),
                      SizedBox(width: 10.sp),
                      Text(i18n('update_renderer'), style: AppTextStyles.t18W600),
                      SizedBox(width: 16.sp),
                      TvButton(
                        title: i18n('update_renderer_impeller'),
                        size: TvButtonSize.small,
                        selected: state.rendererVariant != 'skia',
                        icon: Icon(Icons.bolt_rounded, size: 18.sp),
                        onTap: () => controller.pickRenderer('impeller'),
                      ),
                      SizedBox(width: 12.sp),
                      TvButton(
                        title: i18n('update_renderer_skia'),
                        size: TvButtonSize.small,
                        selected: state.rendererVariant == 'skia',
                        icon: Icon(Icons.memory_rounded, size: 18.sp),
                        onTap: () => controller.pickRenderer('skia'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 4.h),
                  child: Text(
                    i18n('update_renderer_desc'),
                    style: TextStyle(fontSize: 13.sp, color: context.tvTheme.secondaryTextColor),
                  ),
                ),
                // One section per published ABI, the mobile update page's
                // per-architecture download groups.
                for (final String abi in state.abis)
                  _AbiDownloadSection(
                    abi: abi,
                    sizeText: controller.assetSizeFor(abi),
                    sources: _sourcesFor(context, ref, controller, abi, useOrigin),
                    useOrigin: useOrigin,
                  ),
                if (state.abis.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Text(
                      state.phase == AppUpdatePhase.checking
                          ? i18n('check_update')
                          : i18n('already_latest_version'),
                      style: TextStyle(fontSize: 15.sp, color: context.tvTheme.secondaryTextColor),
                    ),
                  ),
                if (state.phase == AppUpdatePhase.downloading) _DownloadProgress(state: state),
                if (state.phase == AppUpdatePhase.readyToInstall)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      children: <Widget>[
                        TvButton(
                          title: i18n('update_install_now'),
                          size: TvButtonSize.small,
                          icon: Icon(Icons.install_mobile_rounded, size: 18.sp),
                          onTap: controller.installDownloaded,
                        ),
                        SizedBox(width: 16.sp),
                        Expanded(
                          child: Text(
                            i18n('update_package_ready'),
                            style: TextStyle(fontSize: 13.sp, color: context.tvTheme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (state.error.isNotEmpty && state.phase != AppUpdatePhase.failed)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
                    child: Text(
                      state.error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, color: context.tvTheme.secondaryTextColor),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24.sp),
            TvSettingsGroupTitle(title: i18n('update_log')),
            SizedBox(height: 8.sp),
            TvSettingsCard(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: _ReleaseNotesMarkdown(state: state),
                ),
              ],
            ),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }

  /// Every pickable mirror of one ABI's package. Origin-only mode collapses
  /// the list to the GitHub origin, mirroring the mobile page; otherwise each
  /// proxy prefix becomes one source and the plain origin is the last one.
  List<String> _sourcesFor(
    BuildContext context,
    WidgetRef ref,
    AppUpdateController controller,
    String abi,
    bool useOrigin,
  ) {
    final String? origin = controller.resolveAssetUrl(abi);
    if (origin == null || !origin.startsWith('http')) return const <String>[];
    if (useOrigin) return <String>[origin];
    return <String>[for (final String mirror in AppUpdateController.assetMirrors) '$mirror$origin', origin];
  }
}

class _AbiDownloadSection extends ConsumerWidget {
  const _AbiDownloadSection({
    required this.abi,
    required this.sizeText,
    required this.sources,
    required this.useOrigin,
  });

  final String abi;
  final String? sizeText;
  final List<String> sources;
  final bool useOrigin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final controller = ref.read(appUpdateControllerProvider.notifier);
    final tvTheme = context.tvTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.memory_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
              SizedBox(width: 10.sp),
              Text(_abiLabel(abi), style: AppTextStyles.t18W600),
              if (sizeText != null && sizeText!.isNotEmpty) ...<Widget>[
                SizedBox(width: 12.sp),
                Text(sizeText!, style: TextStyle(fontSize: 14.sp, color: tvTheme.secondaryTextColor)),
              ],
            ],
          ),
          SizedBox(height: 12.sp),
          Wrap(
            spacing: 12.sp,
            runSpacing: 12.sp,
            children: <Widget>[
              for (int i = 0; i < sources.length; i++)
                TvButton(
                  title: useOrigin ? i18n('github_origin_source') : i18n('download_source', args: {'num': '${i + 1}'}),
                  size: TvButtonSize.small,
                  icon: Icon(Remix.link, size: 18.sp),
                  onTap: () => _confirmSource(context, controller, sources[i], i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Shows the source's URL and starts the download from exactly that source
  /// on confirm — the given URL is tried first, the other mirrors stay as
  /// fallback (see [AppUpdateController.downloadAndInstallUrl]).
  void _confirmSource(BuildContext context, AppUpdateController controller, String url, int index) {
    final tvTheme = context.tvTheme;
    TvDialogUtils.show(
      context: context,
      builder: (dialogContext) => TvDialog(
        title: useOrigin ? i18n('github_origin_source') : i18n('download_source', args: {'num': '${index + 1}'}),
        confirmText: i18n('download'),
        cancelText: i18n('cancel'),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          controller.downloadAndInstallUrl(url, preferGivenUrl: true);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            url,
            style: TextStyle(fontSize: 14.sp, color: tvTheme.secondaryTextColor),
          ),
        ),
      ),
    );
  }

  String _abiLabel(String abi) {
    return switch (abi) {
      'arm64-v8a' => i18n('arch_arm64'),
      'armeabi-v7a' => i18n('arch_arm32'),
      'x86_64' => i18n('arch_x86_64'),
      _ => abi,
    };
  }
}

class _DownloadProgress extends ConsumerWidget {
  const _DownloadProgress({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final controller = ref.read(appUpdateControllerProvider.notifier);
    final String done = (state.receivedBytes / 1048576).toStringAsFixed(1);
    final String total = state.totalBytes > 0 ? ' / ${(state.totalBytes / 1048576).toStringAsFixed(1)} MB' : ' MB';
    final String percent = state.totalBytes > 0 ? '${(state.progress * 100).toStringAsFixed(0)}%' : '';
    final String speed = state.speedMbps > 0 ? '${state.speedMbps.toStringAsFixed(1)} MB/s' : '';

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(6.sp),
            child: LinearProgressIndicator(
              value: state.totalBytes > 0 ? state.progress : null,
              minHeight: 8.sp,
              color: tvTheme.focusColor,
              backgroundColor: tvTheme.cardColor,
            ),
          ),
          SizedBox(height: 8.sp),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  [done + total, if (percent.isNotEmpty) percent, if (speed.isNotEmpty) speed]
                      .join(' · '),
                  style: TextStyle(fontSize: 13.sp, color: tvTheme.secondaryTextColor),
                ),
              ),
              TvButton(title: i18n('cancel'), size: TvButtonSize.mini, isSecondary: true, onTap: controller.cancelDownload),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReleaseNotesMarkdown extends ConsumerWidget {
  const _ReleaseNotesMarkdown({required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String markdown = _resolveMarkdown();
    if (markdown.isEmpty) {
      return Text(
        i18n('update_no_notes'),
        style: TextStyle(fontSize: 15.sp, color: context.tvTheme.secondaryTextColor),
      );
    }

    final tvTheme = context.tvTheme;
    final MarkdownConfig baseConfig = tvTheme.isLight ? MarkdownConfig.defaultConfig : MarkdownConfig.darkConfig;
    final Color ink = tvTheme.primaryTextColor;

    return MarkdownBlock(
      data: markdown,
      config: baseConfig.copy(
        configs: [
          PConfig(textStyle: TextStyle(fontSize: 17.sp, height: 1.5, color: ink)),
          H1Config(style: TextStyle(fontSize: 25.sp, fontWeight: FontWeight.bold, color: ink)),
          H2Config(style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: ink)),
          H3Config(style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold, color: ink)),
        ],
      ),
    );
  }

  /// The manifest's raw update log first, the matching history entry second,
  /// the stripped plain-text preview last.
  String _resolveMarkdown() {
    if (state.changelogMarkdown.trim().isNotEmpty) return state.changelogMarkdown;
    for (final ReleaseModel release in state.history) {
      if (release.version == state.latestVersion ||
          release.version.replaceFirst(RegExp('^[vV]'), '') == state.latestVersion) {
        if (release.changeLog.trim().isNotEmpty) return release.changeLog;
      }
    }
    return state.changelog;
  }
}
