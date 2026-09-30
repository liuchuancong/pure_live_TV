import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';

class ProxySettingsSectionPage extends ConsumerStatefulWidget {
  const ProxySettingsSectionPage({super.key});

  @override
  ConsumerState<ProxySettingsSectionPage> createState() => ProxySettingsSectionPageState();
}

class ProxySettingsSectionPageState extends ConsumerState<ProxySettingsSectionPage> {
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _appHostController;
  late final TextEditingController _appPortController;

  /// The stored values the fields were last seeded from, so an arriving write can
  /// be told apart from text the viewer is still editing here.
  String _hostBaseline = '';
  String _portBaseline = '';
  String _appHostBaseline = '';
  String _appPortBaseline = '';

  @override
  void initState() {
    super.initState();
    final proxyState = ref.read(proxySettingsControllerProvider);
    _hostBaseline = proxyState.proxyHost;
    _portBaseline = proxyState.proxyPort.toString();
    _appHostBaseline = proxyState.appProxyHost;
    _appPortBaseline = proxyState.appProxyPort.toString();
    _hostController = TextEditingController(text: _hostBaseline);
    _portController = TextEditingController(text: _portBaseline);
    _appHostController = TextEditingController(text: _appHostBaseline);
    _appPortController = TextEditingController(text: _appPortBaseline);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _appHostController.dispose();
    _appPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proxyState = ref.watch(proxySettingsControllerProvider);
    final proxy = ref.read(proxySettingsControllerProvider.notifier);

    // showing them. These fields are built once, so without following the store an
    // arriving value stayed invisible — the same gap the cookie box had. Edits
    // made here and not saved yet win, so typing on the TV is never clobbered.
    ref.listen(proxySettingsControllerProvider, (previous, next) {
      final String host = next.proxyHost;
      final String port = next.proxyPort.toString();
      final String appHost = next.appProxyHost;
      final String appPort = next.appProxyPort.toString();
      final bool followsHost = host != _hostController.text && _hostController.text == _hostBaseline;
      final bool followsPort = port != _portController.text && _portController.text == _portBaseline;
      final bool followsAppHost = appHost != _appHostController.text && _appHostController.text == _appHostBaseline;
      final bool followsAppPort = appPort != _appPortController.text && _appPortController.text == _appPortBaseline;
      if (!followsHost && !followsPort && !followsAppHost && !followsAppPort) return;
      setState(() {
        if (followsHost) {
          _hostBaseline = host;
          _hostController.text = host;
        }
        if (followsPort) {
          _portBaseline = port;
          _portController.text = port;
        }
        if (followsAppHost) {
          _appHostBaseline = appHost;
          _appHostController.text = appHost;
        }
        if (followsAppPort) {
          _appPortBaseline = appPort;
          _appPortController.text = appPort;
        }
      });
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 20.ts(context)),
        // Two switches with two consumers, so both are shown:
        //
        // * the player kernel proxy (`enableProxy`) — what media_kit / mpv use to
        //   fetch the live stream itself;
        // * the application-layer proxy (`enableAppProxy`) — what the API client,
        //   the danmaku sockets, the image cache and the update download follow.
        //
        // This page used to label only the player switch with the app proxy's
        // strings and leave the app proxy itself without a switch, so the second
        // setting could not be configured on the TV at all.
        TvSettingsGroupTitle(title: i18n('player_proxy_group_title')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('enable_player_proxy'),
              subtitle: i18n('enable_player_proxy_desc'),
              icon: Icons.play_circle_outline_rounded,
              value: proxyState.enableProxy,
              onChanged: (v) => proxy.updateSettings(proxyState.copyWith(enableProxy: v)),
            ),
            if (proxyState.enableProxy)
              _endpointEditor(
                host: _hostController,
                port: _portController,
                onSave: () {
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
        SizedBox(height: 20.ts(context)),
        TvSettingsGroupTitle(title: i18n('app_proxy_group_title')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('enable_app_proxy'),
              subtitle: i18n('enable_app_proxy_desc'),
              icon: Icons.apps_rounded,
              value: proxyState.enableAppProxy,
              onChanged: (v) => proxy.updateSettings(proxyState.copyWith(enableAppProxy: v)),
            ),
            if (proxyState.enableAppProxy)
              _endpointEditor(
                host: _appHostController,
                port: _appPortController,
                onSave: () {
                  proxy.updateSettings(
                    proxyState.copyWith(
                      appProxyHost: _appHostController.text.trim(),
                      appProxyPort: int.tryParse(_appPortController.text.trim()) ?? proxyState.appProxyPort,
                    ),
                  );
                  setState(() {
                    final saved = ref.read(proxySettingsControllerProvider);
                    _appHostBaseline = saved.appProxyHost;
                    _appPortBaseline = saved.appProxyPort.toString();
                  });
                },
              ),
          ],
        ),
      ],
    );
  }

  /// The endpoint fields and their save tile — identical for both groups.
  ///
  /// Hidden while the group's switch is off, like the mobile page (its endpoint
  /// fields only exist inside `if (enable…)`).
  Widget _endpointEditor({
    required TextEditingController host,
    required TextEditingController port,
    required VoidCallback onSave,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.ts(context), vertical: 8.ts(context)),
          child: TvInputField(controller: host, hint: i18n('ui_proxy_host_e_g_127_0_0_1'), maxLines: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.ts(context), vertical: 8.ts(context)),
          child: TvInputField(controller: port, hint: i18n('ui_proxy_port_e_g_7890'), maxLines: 1),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_save_proxy_settings'),
          subtitle: i18n(
            'proxy_current_endpoint',
            args: {'host': host.text.isEmpty ? i18n('not_set') : host.text, 'port': port.text},
          ),
          icon: Icons.save_rounded,
          options: [i18n('save')],
          index: 0,
          onChanged: (_) => onSave(),
        ),
      ],
    );
  }
}
