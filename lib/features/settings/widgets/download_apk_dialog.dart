import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The update package download, as a TV dialog: progress, cancel, install.
///
/// The mobile app's `DownloadApkDialog` is the model — the dialog owns the
/// transfer, shows a progress bar with the transferred size and speed, offers
/// the cancel while it runs, and turns into an install action once the package
/// has landed.
///
/// TV differences:
///
/// - the package always lands in the app's private download directory
///   (`DOWNLOADS/update` under the app support/cache path), so there is no
///   directory picker and no "open folder" action — nothing outside the app is
///   written
/// - the transfer itself runs through [AppUpdateController], which owns the
///   mirror fallback, the staged commit into the private directory and the
///   local update log, instead of the dialog holding a Dio client of its own
/// - the dialog is drawn with the app's TV dialog frame, so the remote's d-pad
///   and back key behave like every other modal in the app
///
/// Downloading continues for as long as the dialog is open: dismissing it
/// (back key or cancel) aborts the transfer, and the partial file is removed by
/// the controller.
class DownloadApkDialog extends ConsumerStatefulWidget {
  const DownloadApkDialog({super.key, required this.url, this.preferGivenUrl = false});

  /// The release asset to download.
  final String url;

  /// Whether [url] is tried before the app's mirror list.
  ///
  /// The download page passes true — "source 3" means source 3 — while the
  /// version history keeps the mirror-first order, exactly like the plain
  /// update path did.
  final bool preferGivenUrl;

  @override
  ConsumerState<DownloadApkDialog> createState() => _DownloadApkDialogState();
}

/// Shows the download dialog for [url] and completes when it closes.
Future<void> showDownloadApkDialog({
  required BuildContext context,
  required String url,
  bool preferGivenUrl = false,
}) {
  return TvDialogUtils.show<void>(
    context: context,
    builder: (_) => DownloadApkDialog(url: url, preferGivenUrl: preferGivenUrl),
  );
}

class _DownloadApkDialogState extends ConsumerState<DownloadApkDialog> {
  late final AppUpdateController _controller;

  /// Tracks whether a transfer is running, so [dispose] can abort it.
  ///
  /// The phase is followed through a manual subscription rather than read from
  /// the notifier, which would be a protected-member access, and rather than
  /// from [build], which may never run before the dialog goes away.
  ProviderSubscription<AppUpdateState>? _stateSubscription;

  /// Set in [dispose]: a microtask that has not started its download yet must
  /// not start one after the dialog is gone.
  bool _disposed = false;

  bool _downloading = false;

  /// The name the package is stored under, shown in the dialog.
  late final String _fileName;

  bool _installing = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _controller = ref.read(appUpdateControllerProvider.notifier);
    _fileName = safeDownloadFileName(widget.url);

    _stateSubscription = ref.listenManual<AppUpdateState>(appUpdateControllerProvider, (previous, next) {
      _downloading = next.phase == AppUpdatePhase.downloading;
    });

    // The dialog is the download: it starts the transfer as soon as it is on
    // screen, and the cancel button (or leaving) is the way out.
    unawaited(
      Future<void>.microtask(() {
        if (_disposed) return;
        _controller.downloadAsset(widget.url, preferGivenUrl: widget.preferGivenUrl);
      }),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _stateSubscription?.close();

    // Leaving while the transfer is still running must not leave a download
    // going with nothing on screen showing it. The controller deletes the
    // partial file it was writing.
    if (_downloading) {
      _controller.cancelDownload();
    }
    super.dispose();
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  void _cancel() {
    _controller.cancelDownload();
    _close();
  }

  Future<void> _retry() {
    return _controller.downloadAsset(widget.url, preferGivenUrl: widget.preferGivenUrl);
  }

  Future<void> _install() async {
    if (_installing) return;

    setState(() => _installing = true);

    final AppInstallResult result = await _controller.installDownloaded();

    if (!mounted) return;

    setState(() => _installing = false);

    switch (result) {
      case AppInstallResult.launched:
        _close();
      case AppInstallResult.permissionDenied:
        ToastUtil.show(i18n('grant_install_permission'));
      case AppInstallResult.launchFailed:
      case AppInstallResult.missingPackage:
        ToastUtil.show(i18n('install_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUpdateState state = ref.watch(appUpdateControllerProvider);
    final tvTheme = context.tvTheme;

    final bool downloading = state.phase == AppUpdatePhase.downloading;
    final bool ready = state.phase == AppUpdatePhase.readyToInstall;
    // A download that ended without a package: the controller publishes the
    // reason and returns to the available phase.
    final bool failed = !downloading && !ready && state.error.isNotEmpty;

    return TvDialog(
      title: _title(downloading: downloading, ready: ready, failed: failed),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (downloading || _installing)
                SizedBox.square(
                  dimension: 20.sp,
                  child: CircularProgressIndicator(strokeWidth: 2.5.sp, color: tvTheme.focusColor),
                )
              else
                Icon(
                  failed ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                  size: 22.sp,
                  color: failed ? tvTheme.secondaryTextColor : tvTheme.focusColor,
                ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Text(
                  _fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15.sp, color: tvTheme.secondaryTextColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.sp),
            child: LinearProgressIndicator(
              // Indeterminate only while bytes are actually arriving without a
              // Content-Length: every settled state keeps a fixed value, so the
              // bar never animates on forever after the transfer stopped.
              value: ready ? 1 : (downloading && state.totalBytes <= 0 ? null : state.progress),
              minHeight: 10.sp,
              color: tvTheme.focusColor,
              backgroundColor: tvTheme.buttonSurface,
            ),
          ),
          SizedBox(height: 12.sp),
          Text(
            _statusText(state, downloading: downloading, ready: ready, failed: failed),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              color: failed ? tvTheme.secondaryTextColor : tvTheme.primaryTextColor,
            ),
          ),
          SizedBox(height: 28.sp),
          // The action set follows the phase: cancel while the transfer runs,
          // install (or retry) once it settled.
          Row(mainAxisAlignment: MainAxisAlignment.end, children: _actions(downloading: downloading, ready: ready, failed: failed)),
        ],
      ),
    );
  }

  String _title({required bool downloading, required bool ready, required bool failed}) {
    if (downloading) return i18n('update_download_install');
    if (ready) return i18n('update_package_ready');
    if (failed) return i18n('download_failed');
    return i18n('update_download_install');
  }

  /// `12.3 MB / 42.5 MB · 29% · 3.4 MB/s`, or the same figures as they arrive.
  String _statusText(AppUpdateState state, {required bool downloading, required bool ready, required bool failed}) {
    if (ready) return i18n('download_success');
    // 失败原因来自状态：体积校验失败/超时/HTTP 状态码等都已经是可以直接展示的
    // 整句（见 AppUpdateService._describeError），比笼统的"下载失败"有用。
    if (failed) {
      final String reason = state.error.trim();
      return reason.isEmpty ? i18n('download_failed') : reason;
    }

    if (!downloading) return i18n('download_preparing');

    final String done = (state.receivedBytes / 1048576).toStringAsFixed(1);
    final String total = state.totalBytes > 0 ? ' / ${(state.totalBytes / 1048576).toStringAsFixed(1)} MB' : ' MB';
    final String percent = state.totalBytes > 0 ? '${(state.progress * 100).toStringAsFixed(0)}%' : '';
    final String speed = state.speedMbps > 0 ? '${state.speedMbps.toStringAsFixed(1)} MB/s' : '';

    return <String>[
      done + total,
      if (percent.isNotEmpty) percent,
      if (speed.isNotEmpty) speed,
    ].join(' · ');
  }

  List<Widget> _actions({required bool downloading, required bool ready, required bool failed}) {
    if (downloading) {
      return <Widget>[
        TvButton(
          key: const ValueKey('download-cancel'),
          title: i18n('cancel'),
          size: TvButtonSize.mini,
          isSecondary: true,
          autofocus: true,
          onTap: _cancel,
        ),
      ];
    }

    if (ready) {
      return <Widget>[
        TvButton(
          key: const ValueKey('download-close'),
          title: i18n('close'),
          size: TvButtonSize.mini,
          isSecondary: true,
          onTap: _close,
        ),
        SizedBox(width: 16.sp),
        TvButton(
          key: const ValueKey('download-install'),
          title: _installing ? i18n('download_complete_installing') : i18n('update_install_now'),
          size: TvButtonSize.mini,
          icon: Icon(Icons.install_mobile_rounded, size: 18.sp),
          autofocus: true,
          onTap: _installing ? null : _install,
        ),
      ];
    }

    if (failed) {
      return <Widget>[
        TvButton(
          key: const ValueKey('download-close-failed'),
          title: i18n('close'),
          size: TvButtonSize.mini,
          isSecondary: true,
          onTap: _close,
        ),
        SizedBox(width: 16.sp),
        TvButton(
          key: const ValueKey('download-retry'),
          title: i18n('retry'),
          size: TvButtonSize.mini,
          icon: Icon(Remix.refresh_line, size: 18.sp),
          autofocus: true,
          onTap: () => _retry(),
        ),
      ];
    }

    return <Widget>[
      TvButton(
        key: const ValueKey('download-close-idle'),
        title: i18n('close'),
        size: TvButtonSize.mini,
        isSecondary: true,
        autofocus: true,
        onTap: _close,
      ),
    ];
  }
}
