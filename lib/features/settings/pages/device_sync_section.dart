import 'dart:async';

import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 设备同步 — the TV end of the LAN sync.
///
/// The phone app's 设备同步 row is the other end: it scans this address and then
/// pushes (or pulls) the configuration through the LAN remote the TV already
/// runs for the danmaku filter and cookies — `/api/remote-sync/status`,
/// `/api/remote-sync/settings`, `/api/backup/export` and `/api/backup/import`.
/// A TV has no network scanner and no browser, so all this page has to do is
/// bring the service up and show the address it is reachable at.
class DeviceSyncSectionPage extends ConsumerStatefulWidget {
  const DeviceSyncSectionPage({super.key});

  @override
  ConsumerState<DeviceSyncSectionPage> createState() => DeviceSyncSectionPageState();
}

class DeviceSyncSectionPageState extends ConsumerState<DeviceSyncSectionPage> {
  bool _starting = false;

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

  @override
  Widget build(BuildContext context) {
    final ServerState? server = ref.watch(tvRemoteReceiverProvider).value;
    final bool running = server?.isRunning == true;
    final String url = running ? (server?.serverUrl ?? '') : '';
    final theme = context.tvTheme;
    // The mobile app's remote-sync page understands this URI form and offers
    // send/receive once it scans it; a bare origin still works as a fallback.
    final String qrData = url.isEmpty ? '' : '${url.replaceFirst('http://', 'purelive://')}/sync';

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
        if (url.isEmpty)
          Text(
            i18n('remote_service_unavailable'),
            style: AppTextStyles.t18W600.copyWith(color: theme.focusColor),
          )
        else
          Center(child: TvQrCodeCard(qrData: qrData, urlText: url)),
      ],
    );
  }
}
