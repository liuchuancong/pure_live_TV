import 'package:flutter/material.dart';
import 'package:pure_live/core/theme/index.dart';
import 'package:pure_live/core/widgets/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/features/settings/pages/widgets/app_download_sections.dart';

/// The download page behind the update page's current-version row - the TV twin of the mobile
/// app's version update page: a platform card with one section per ABI, every
/// section offering the release package through each mirror as a pickable
/// source buttons, and the release notes rendered as markdown at the bottom.
///
/// Unlike the plain download row on the update page (which races the mirrors
/// itself), a source picked here is tried first: "source 3" really means
/// source 3 — with the remaining mirrors kept as fallback. The transfer itself
/// runs in the download dialog, which owns the progress, the cancel and the
/// install action; this page only picks the source.
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
        padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 12.ts(context)),
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
                        padding: EdgeInsets.all(10.ts(context)),
                        decoration: BoxDecoration(
                          color: context.tvTheme.focusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.ts(context)),
                        ),
                        child: Icon(Icons.android_rounded, color: context.tvTheme.focusColor, size: 28.ts(context)),
                      ),
                      SizedBox(width: 14.ts(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Android', style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600)),
                            SizedBox(height: 2.ts(context)),
                            Text(
                              i18n('android_desc'),
                              style: AppTextStyles.t17.copyWith(color: context.tvTheme.secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Renderer variant picker: the dual-variant releases publish
                // Impeller and Skia APKs per ABI; the choice persists and the
                // The source buttons below resolve to the selected variant.
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 4.h),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.layers_rounded, size: 20.ts(context), color: context.tvTheme.secondaryTextColor),
                      SizedBox(width: 10.ts(context)),
                      Text(i18n('update_renderer'), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(width: 16.ts(context)),
                      TvButton(
                        title: i18n('update_renderer_impeller'),
                        size: TvButtonSize.small,
                        selected: state.rendererVariant != 'skia',
                        icon: Icon(Icons.bolt_rounded, size: 18.ts(context)),
                        onTap: () => controller.pickRenderer('impeller'),
                      ),
                      SizedBox(width: 12.ts(context)),
                      TvButton(
                        title: i18n('update_renderer_skia'),
                        size: TvButtonSize.small,
                        selected: state.rendererVariant == 'skia',
                        icon: Icon(Icons.memory_rounded, size: 18.ts(context)),
                        onTap: () => controller.pickRenderer('skia'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 4.h),
                  child: Text(
                    i18n('update_renderer_desc'),
                    style: AppTextStyles.t16.copyWith(color: context.tvTheme.secondaryTextColor),
                  ),
                ),
                // One section per published ABI, the mobile update page's
                // per-architecture download groups.
                for (final String abi in state.abis)
                  AppDownloadAbiSection(
                    abi: abi,
                    sizeText: controller.assetSizeFor(abi),
                    sources: _sourcesFor(context, ref, controller, abi, useOrigin),
                    useOrigin: useOrigin,
                  ),
                if (state.abis.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Text(
                      state.phase == AppUpdatePhase.checking ? i18n('check_update') : i18n('already_latest_version'),
                      style: AppTextStyles.t17.copyWith(color: context.tvTheme.secondaryTextColor),
                    ),
                  ),
                if (state.phase == AppUpdatePhase.readyToInstall)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      children: <Widget>[
                        TvButton(
                          title: i18n('update_install_now'),
                          size: TvButtonSize.small,
                          icon: Icon(Icons.install_mobile_rounded, size: 18.ts(context)),
                          onTap: () => controller.installDownloaded(),
                        ),
                        SizedBox(width: 16.ts(context)),
                        Expanded(
                          child: Text(
                            i18n('update_package_ready'),
                            style: AppTextStyles.t16.copyWith(color: context.tvTheme.secondaryTextColor),
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
                      style: AppTextStyles.t16.copyWith(color: context.tvTheme.secondaryTextColor),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24.ts(context)),
            TvSettingsGroupTitle(title: i18n('update_log')),
            SizedBox(height: 8.ts(context)),
            TvSettingsCard(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: AppReleaseNotesMarkdown(state: state),
                ),
              ],
            ),
            SizedBox(height: 40.ts(context)),
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
    return <String>[for (final String mirror in appUpdateAssetMirrors) '$mirror$origin', origin];
  }
}
