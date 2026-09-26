import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';

class ProxySettingsSectionPage extends ConsumerStatefulWidget {
  const ProxySettingsSectionPage({super.key});

  @override
  ConsumerState<ProxySettingsSectionPage> createState() => ProxySettingsSectionPageState();
}

class ProxySettingsSectionPageState extends ConsumerState<ProxySettingsSectionPage> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  /// The stored values the fields were last seeded from, so an arriving write can
  /// be told apart from text the viewer is still editing here.
  String _hostBaseline = '';
  String _portBaseline = '';

  @override
  void initState() {
    super.initState();
    final proxyState = ref.read(proxySettingsControllerProvider);
    _hostBaseline = proxyState.proxyHost;
    _portBaseline = proxyState.proxyPort.toString();
    _hostController = TextEditingController(text: _hostBaseline);
    _portController = TextEditingController(text: _portBaseline);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proxyState = ref.watch(proxySettingsControllerProvider);
    final proxy = ref.read(proxySettingsControllerProvider.notifier);

    // The phone's page writes this setting in 实时同步模式 while the TV may be
    // showing it. These fields are built once, so without following the store an
    // arriving value stayed invisible — the same gap the cookie box had. Edits
    // made here and not saved yet win, so typing on the TV is never clobbered.
    ref.listen(proxySettingsControllerProvider, (previous, next) {
      final String host = next.proxyHost;
      final String port = next.proxyPort.toString();
      final bool followsHost = host != _hostController.text && _hostController.text == _hostBaseline;
      final bool followsPort = port != _portController.text && _portController.text == _portBaseline;
      if (!followsHost && !followsPort) return;
      setState(() {
        if (followsHost) {
          _hostBaseline = host;
          _hostController.text = host;
        }
        if (followsPort) {
          _portBaseline = port;
          _portController.text = port;
        }
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 20.sp),
        TvSettingsGroupTitle(title: i18n('player_proxy_group_title')),
        TvSettingsCard(
          children: [
            // The player proxy, exactly as the mobile player group labels it.
            //
            // It used to read `ui_enable_network_proxy` / "unified proxy for API, image
            // and danmaku traffic", which describes the *app* proxy
            // (`enableAppProxy`/`appProxyHost`) — a setting this app does not
            // implement at all, while the row actually stores `enableProxy`,
            // `proxyHost` and `proxyPort`, i.e. the media_kit/mpv kernel proxy.
            TvSettingsSwitchTile(
              title: i18n('enable_player_proxy'),
              subtitle: i18n('enable_player_proxy_desc'),
icon: proxyState.enableProxy ? Icons.vpn_key_rounded : Icons.vpn_key_off_outlined,
              value: proxyState.enableProxy,
              onChanged: (v) => proxy.updateSettings(proxyState.copyWith(enableProxy: v)),
            ),
            // Hidden while the proxy is off, like the mobile page (its endpoint
            // fields only exist inside `if (enableProxy)`).
            if (proxyState.enableProxy)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                child: TvInputField(controller: _hostController, hint: i18n('ui_proxy_host_e_g_127_0_0_1'), maxLines: 1),
              ),
            if (proxyState.enableProxy)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                child: TvInputField(controller: _portController, hint: i18n('ui_proxy_port_e_g_7890'), maxLines: 1),
              ),
            if (proxyState.enableProxy)
              TvSettingsOptionTile(
                title: i18n('ui_save_proxy_settings'),
                subtitle: i18n(
                  'proxy_current_endpoint',
                  args: {
                    'host': _hostController.text.isEmpty ? i18n('not_set') : _hostController.text,
                    'port': _portController.text,
                  },
                ),
                icon: Icons.save_rounded,
                options: [i18n('save')],
                index: 0,
                onChanged: (_) {
                  proxy.updateSettings(
                    proxyState.copyWith(
                      proxyHost: _hostController.text.trim(),
                      proxyPort: int.tryParse(_portController.text.trim()) ?? proxyState.proxyPort,
                    ),
                  );
                  // Re-seed the baselines: what was just saved is the new
                  // starting point for a later push from the phone.
                  setState(() {
                    final saved = ref.read(proxySettingsControllerProvider);
                    _hostBaseline = saved.proxyHost;
                    _portBaseline = saved.proxyPort.toString();
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}
