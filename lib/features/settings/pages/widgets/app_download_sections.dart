import 'package:flutter/material.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:pure_live/core/theme/index.dart';
import 'package:pure_live/core/widgets/index.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/core/models/release_model/release_model.dart';
import 'package:pure_live/features/settings/widgets/download_apk_dialog.dart';

class AppDownloadAbiSection extends ConsumerWidget {
  const AppDownloadAbiSection({
    super.key,
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
    final tvTheme = context.tvTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.memory_rounded, size: 20.ts(context), color: tvTheme.secondaryTextColor),
              SizedBox(width: 10.ts(context)),
              Text(_abiLabel(abi), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600)),
              if (sizeText != null && sizeText!.isNotEmpty) ...<Widget>[
                SizedBox(width: 12.ts(context)),
                Text(sizeText!, style: AppTextStyles.t16.copyWith(color: tvTheme.secondaryTextColor)),
              ],
            ],
          ),
          SizedBox(height: 12.ts(context)),
          Wrap(
            spacing: 12.ts(context),
            runSpacing: 12.ts(context),
            children: <Widget>[
              for (int i = 0; i < sources.length; i++)
                TvButton(
                  title: useOrigin ? i18n('github_origin_source') : i18n('download_source', args: {'num': '${i + 1}'}),
                  size: TvButtonSize.small,
                  icon: Icon(Remix.link, size: 18.ts(context)),
                  onTap: () => _startDownload(context, sources[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Starts the download from the picked source: the download dialog
  /// opens on that URL — with the other mirrors kept as fallback by the
  /// controller — and carries the progress, the cancel and the install action
  /// itself, so the page keeps no transfer state of its own.
  void _startDownload(BuildContext context, String url) {
    showDownloadApkDialog(context: context, url: url, preferGivenUrl: true);
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

class AppReleaseNotesMarkdown extends ConsumerWidget {
  const AppReleaseNotesMarkdown({super.key, required this.state});

  final AppUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String markdown = _resolveMarkdown();
    if (markdown.isEmpty) {
      return Text(
        i18n('update_no_notes'),
        style: AppTextStyles.t17.copyWith(color: context.tvTheme.secondaryTextColor),
      );
    }

    final tvTheme = context.tvTheme;
    final MarkdownConfig baseConfig = tvTheme.isLight ? MarkdownConfig.defaultConfig : MarkdownConfig.darkConfig;
    final Color ink = tvTheme.primaryTextColor;

    return MarkdownBlock(
      data: markdown,
      config: baseConfig.copy(
        configs: [
          PConfig(textStyle: AppTextStyles.t19.copyWith(height: 1.5, color: ink)),
          H1Config(
            style: AppTextStyles.t25.copyWith(fontWeight: FontWeight.w700, color: ink),
          ),
          H2Config(
            style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: ink),
          ),
          H3Config(
            style: AppTextStyles.t19.copyWith(fontWeight: FontWeight.w700, color: ink),
          ),
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
