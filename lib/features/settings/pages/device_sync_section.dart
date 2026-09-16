import 'dart:async';

import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:tv_remote_kit/tv_remote_kit.dart';

/// 设备同步 — the TV end of the LAN sync.
///
/// Two halves live here. The 8888 web-remote row is unchanged. Below it, the
/// [TvRemoteKit] service (bonsoir broadcast + discovery, HTTP on 39888) shows
/// its own pairing QR, lists the peers discovered on the LAN, and pushes/pulls
/// full settings documents between devices.
class DeviceSyncSectionPage extends ConsumerStatefulWidget {
  const DeviceSyncSectionPage({super.key});

  @override
  ConsumerState<DeviceSyncSectionPage> createState() => DeviceSyncSectionPageState();
}

class DeviceSyncSectionPageState extends ConsumerState<DeviceSyncSectionPage> {
  bool _starting = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureRunning());
  }

  Future<void> _ensureRunning() async {
    final ServerState? server = ref.read(tvRemoteReceiverProvider).value;
    if (server?.isRunning == true || _starting) return;
    await _restart();
  }

  Future<void> _restart() async {
    setState(() => _starting = true);
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    await notifier.stopServer();
    await notifier.startServer();
    if (!mounted) return;
    setState(() => _starting = false);
  }

  Future<void> _pushTo(RemoteSyncDevice device) async {
    final kit = ref.read(remoteSyncControllerProvider.notifier).kit;
    if (kit == null || _syncing) return;
    setState(() => _syncing = true);
    final ok = await kit.syncToDevice(device);
    if (!mounted) return;
    setState(() => _syncing = false);
    ToastUtil.show(
      ok
          ? i18nOr('remote_sync_push_done', 'Settings pushed to {name}', args: {'name': device.name})
          : i18nOr('remote_sync_push_failed', 'Push to {name} failed', args: {'name': device.name}),
    );
  }

  Future<void> _pullByAddress() async {
    final kit = ref.read(remoteSyncControllerProvider.notifier).kit;
    if (kit == null || _syncing) return;
    final input = await TvDialogUtils.showInput(
      context: context,
      title: i18nOr('remote_sync_pull_title', 'Pull settings from a device'),
      hintText: '192.168.1.100:39888',
    );
    if (input == null || input.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _syncing = true);
    final ok = await kit.receiveFromQrOrAddress(input);
    if (!mounted) return;
    setState(() => _syncing = false);
    ToastUtil.show(ok ? i18n('webdav_sync_success') : i18n('ui_import_failed_or_file_not_found'));
  }

  @override
  Widget build(BuildContext context) {
    final ServerState? server = ref.watch(tvRemoteReceiverProvider).value;
    final bool running = server?.isRunning == true;
    final String url = running ? (server?.serverUrl ?? '') : '';
    final theme = context.tvTheme;
    final syncSnapshot = ref.watch(remoteSyncControllerProvider);
    final devices = syncSnapshot.devices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('remote_sync')),
        TvSettingsCard(
          children: [
            TvSettingsRow(
              title: i18n('remote_sync'),
              subtitle: running
                  ? url
                  : (_starting ? i18n('ui_loading') : (server?.error ?? i18n('remote_service_unavailable'))),
              icon: Icons.wifi_tethering_rounded,
              trailingBuilder: (context, focused) =>
                  tvSettingsValueLabel(context, focused, running ? i18n('ui_running') : i18n('ui_stopped')),
              onSelect: _starting ? null : () => unawaited(_restart()),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          i18n('remote_sync_subtitle'),
          style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
        ),
        SizedBox(height: 16.h),
        // The native pairing QR: the phone app scans it, or types the address.
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 24.h),
        // Discovered peers: selecting a row pushes this device's settings to it.
        TvSettingsGroupTitle(title: i18nOr('remote_sync_devices', 'Devices on this network')),
        TvSettingsCard(
          children: [
            if (devices.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 14.h),
                child: Text(
                  i18nOr('remote_sync_no_devices', 'No devices discovered yet'),
                  style: AppTextStyles.t16W500.copyWith(color: theme.secondaryTextColor),
                ),
              )
            else
              for (final device in devices)
                TvSettingsRow(
                  title: device.name,
                  subtitle: '${device.address} · ${device.platform}',
                  icon: Icons.devices_rounded,
                  trailingBuilder: (context, focused) => tvSettingsValueLabel(
                    context,
                    focused,
                    _syncing ? i18n('ui_loading') : i18nOr('remote_sync_push', 'Push settings'),
                  ),
                  onSelect: _syncing ? null : () => unawaited(_pushTo(device)),
                ),
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
