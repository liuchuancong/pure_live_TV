import 'dart:async';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/remote_sync_pair_qr_card.dart';
import 'package:pure_live/services/remote_sync/remote_sync_device.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';

/// Device sync — the TV end of the LAN sync (39888), and nothing else.
///
/// connect (the pairing QR and this TV's address), LAN devices (the peers discovered
/// on the LAN, each with its own push action), import (pull by address). The 8888
/// web-remote is a separate service owned by its own page and is not touched.
class DeviceSyncSectionPage extends ConsumerStatefulWidget {
  const DeviceSyncSectionPage({super.key});

  @override
  ConsumerState<DeviceSyncSectionPage> createState() => DeviceSyncSectionPageState();
}

class DeviceSyncSectionPageState extends ConsumerState<DeviceSyncSectionPage> {
  bool _syncing = false;

  Future<void> _pullByAddress() async {
    final kit = ref.read(remoteSyncControllerProvider.notifier).kit;
    if (_syncing) return;
    final input = await TvDialogUtils.showInput(
      context: context,
      title: i18nOr('remote_sync_pull_title', 'Pull settings from a device'),
      hintText: '192.168.1.100:39888',
    );
    if (input == null || input.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _syncing = true);
    // receiveFromQrOrAddress does a real GET /api/remote-sync/settings and
    // applies it — it is not just a /status reachability check.
    final ok = await kit.receiveFromQrOrAddress(input.trim());
    if (!mounted) return;
    setState(() => _syncing = false);
    ToastUtil.show(ok ? i18n('webdav_sync_success') : i18n('ui_import_failed_or_file_not_found'));
  }

  Future<void> _pullFrom(RemoteSyncDevice device) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final ok = await ref.read(remoteSyncControllerProvider.notifier).receiveFromAddress(device.ip, device.port);
    if (!mounted) return;
    setState(() => _syncing = false);
    ToastUtil.show(
      ok
          ? i18nOr('remote_sync_pull_done', 'Settings pulled from {name}', args: {'name': device.name})
          : i18nOr('remote_sync_pull_failed', 'Pull from {name} failed', args: {'name': device.name}),
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
      case 'ios':
        return Icons.smartphone_rounded;
      case 'windows':
      case 'macos':
      case 'linux':
        return Icons.computer_rounded;
      default:
        return Icons.tv_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(remoteSyncControllerProvider);
    final devices = snapshot.devices;
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -- pairing: QR on the left, status/steps on the right ------------------------
        TvSettingsGroupTitle(title: i18nOr('remote_sync_connect', 'Connect a phone')),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.sp),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20.sp),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RemoteSyncPairQrCard(width: 400),
              SizedBox(width: 28.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ServiceStatusPill(
                      started: snapshot.started,
                      address: snapshot.address,
                      error: snapshot.error,
                    ),
                    // A phone that pushes its settings leaves the TV otherwise
                    // unchanged, so the last result stays on screen: the toast
                    // is usually gone by the time the operator looks up.
                    if (snapshot.lastReceiveNotice.isNotEmpty) ...[
                      SizedBox(height: 12.sp),
                      _ReceiveNoticeRow(notice: snapshot.lastReceiveNotice, ok: snapshot.lastReceiveOk),
                    ],
                    SizedBox(height: 20.sp),
                    _StepBullet(
                      icon: Icons.qr_code_scanner_rounded,
                      text: i18nOr('remote_sync_step_scan', 'Scan the QR code with pure_live on another device'),
                    ),
                    SizedBox(height: 10.sp),
                    _StepBullet(
                      icon: Icons.cloud_download_outlined,
                      text: i18nOr('remote_sync_step_pull', 'Confirm on that device to push its settings here'),
                    ),
                    SizedBox(height: 10.sp),
                    _StepBullet(
                      icon: Icons.devices_other_rounded,
                      text: i18nOr('remote_sync_step_pair', 'Or pick a discovered device below to pull from it'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // -- multi-NIC correction: pick which address to advertise ---------------
        if (snapshot.localIps.length > 1) ...[
          TvSettingsMenuTile<String>(
            title: i18nOr('remote_sync_local_ip', 'This device address'),
            subtitle: i18nOr('remote_sync_local_ip_desc', 'Multiple networks detected; pick the one your phone can reach'),
            icon: Icons.lan_rounded,
            value: snapshot.address.split(':').first,
            valueMap: {for (final ip in snapshot.localIps) ip: ip},
            onChanged: (ip) => unawaited(ref.read(remoteSyncControllerProvider.notifier).selectLocalIp(ip)),
          ),
          SizedBox(height: 16.h),
        ],

        // -- LAN devices ----------------------------------------------------------
        TvSettingsGroupTitle(title: i18nOr('remote_sync_devices', 'Devices on this network')),
        TvSettingsCard(
          children: [
            if (devices.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
                child: Row(
                  children: [
                    Icon(Icons.wifi_find_rounded,
                        size: 26.sp, color: theme.secondaryTextColor.withValues(alpha: 0.6)),
                    SizedBox(width: 14.sp),
                    Expanded(
                      child: Text(
                        i18nOr('remote_sync_no_devices', 'No devices discovered yet'),
                        style: AppTextStyles.t18W300.copyWith(color: theme.secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final device in devices)
                Padding(
                  key: ValueKey(device.id),
                  padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
                  child: Row(
                    children: [
                      Container(
                        width: 40.sp,
                        height: 40.sp,
                        decoration: BoxDecoration(
                          color: theme.focusColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_platformIcon(device.platform), size: 22.sp, color: theme.focusColor),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              style: AppTextStyles.t18W500,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${device.address} · ${device.platform.isEmpty ? '—' : device.platform}',
                              style: AppTextStyles.t18W300.copyWith(color: theme.secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      TvButton(
                        title: _syncing ? i18n('ui_loading') : i18nOr('remote_sync_pull_from', 'Pull settings'),
                        size: TvButtonSize.small,
                        isSecondary: true,
                        onTap: _syncing ? null : () => unawaited(_pullFrom(device)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        SizedBox(height: 16.h),

        // -- import --------------------------------------------------------------
        TvSettingsGroupTitle(title: i18nOr('remote_sync_import', 'Import')),
        TvSettingsCard(
          children: [
            TvSettingsRow(
              title: i18nOr('remote_sync_pull', 'Pull settings by address'),
              subtitle: i18nOr('remote_sync_pull_subtitle', 'Enter a peer address to import its settings'),
              icon: Icons.download_rounded,
              onSelect: _syncing ? null : () => unawaited(_pullByAddress()),
            ),
          ],
        ),
      ],
    );
  }
}

/// Status colours shared by the service pill and the receive notice.
const Color _serviceOkColor = Color(0xFF4CAF50);
const Color _serviceFailColor = Color(0xFFEF5350);

/// Service status pill: dot + address/error + running label.
class _ServiceStatusPill extends StatelessWidget {
  const _ServiceStatusPill({
    required this.started,
    required this.address,
    required this.error,
  });

  final bool started;
  final String address;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final running = started;
    final Color badgeColor = running ? _serviceOkColor : _serviceFailColor;
    final String label = running ? i18n('ui_running') : i18n('ui_stopped');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.sp,
            height: 10.sp,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.sp),
          Flexible(
            child: Text(
              running
                  ? address
                  : (error ?? i18nOr('remote_sync_starting', 'Starting the LAN sync service...')),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t18W500.copyWith(color: theme.primaryTextColor),
            ),
          ),
          SizedBox(width: 12.sp),
          Text(label, style: AppTextStyles.t16W500.copyWith(color: badgeColor)),
        ],
      ),
    );
  }
}

/// Result of the last inbound settings push, kept on screen after the toast.
class _ReceiveNoticeRow extends StatelessWidget {
  const _ReceiveNoticeRow({required this.notice, required this.ok});

  final String notice;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? _serviceOkColor : _serviceFailColor;
    return Row(
      children: [
        Icon(ok ? Icons.check_circle_rounded : Icons.error_outline_rounded, size: 20.sp, color: color),
        SizedBox(width: 8.sp),
        Expanded(
          child: Text(
            notice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t18W500.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Guide step row: icon + description.
class _StepBullet extends StatelessWidget {
  const _StepBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30.sp,
          height: 30.sp,
          decoration: BoxDecoration(
            color: theme.focusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8.sp),
          ),
          child: Icon(icon, size: 17.sp, color: theme.focusColor),
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.sp),
            child: Text(
              text,
              style: AppTextStyles.t18W300.copyWith(color: theme.secondaryTextColor, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}
