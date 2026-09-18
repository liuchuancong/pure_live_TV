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

/// 设备同步 — the TV end of the LAN sync (39888), and nothing else.
///
/// 连接 (the pairing QR and this TV's address), 局域网设备 (the peers discovered
/// on the LAN, each with its own push action), 导入 (pull by address). The 8888
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
        // -- 连接 -----------------------------------------------------------
        TvSettingsGroupTitle(title: i18nOr('remote_sync_connect', 'Connect a phone')),
        TvSettingsCard(
          children: [
            TvSettingsRow(
              title: i18nOr('remote_sync_service', 'LAN sync service'),
              subtitle: snapshot.started
                  ? snapshot.address
                  : (snapshot.error ?? i18nOr('remote_sync_starting', 'Starting the LAN sync service...')),
              icon: Icons.wifi_tethering_rounded,
              trailingBuilder: (context, focused) =>
                  tvSettingsValueLabel(context, focused, snapshot.started ? i18n('ui_running') : i18n('ui_stopped')),
              onSelect: snapshot.started
                  ? null
                  : () => unawaited(ref.read(remoteSyncControllerProvider.notifier).restart()),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Center(child: RemoteSyncPairQrCard(width: 400)),
        SizedBox(height: 24.h),

        // -- 局域网设备 -------------------------------------------------------
        TvSettingsGroupTitle(title: i18nOr('remote_sync_devices', 'Devices on this network')),
        TvSettingsCard(
          children: [
            if (devices.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 14.h),
                child: Text(
                  i18nOr('remote_sync_no_devices', 'No devices discovered yet'),
                  style: AppTextStyles.t18W500.copyWith(color: theme.secondaryTextColor),
                ),
              )
            else
              for (final device in devices)
                Padding(
                  key: ValueKey(device.id),
                  padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 10.h),
                  child: Row(
                    children: [
                      Icon(_platformIcon(device.platform), size: 22.sp, color: theme.secondaryTextColor),
                      SizedBox(width: 12.w),
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

        // -- 导入 -----------------------------------------------------------
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
