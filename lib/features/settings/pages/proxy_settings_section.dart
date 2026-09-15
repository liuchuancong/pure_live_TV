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

  @override
  void initState() {
    super.initState();
    final proxyState = ref.read(proxySettingsControllerProvider);
    _hostController = TextEditingController(text: proxyState.proxyHost);
    _portController = TextEditingController(text: proxyState.proxyPort.toString());
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSwitchTile(
          title: i18n('ui_enable_network_proxy'),
          subtitle: i18n('ui_route_api_image_and_danmaku_traffic_through_one'),
          icon: Icons.vpn_key_rounded,
          value: proxyState.enableProxy,
          onChanged: (v) => proxy.updateSettings(proxyState.copyWith(enableProxy: v)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: TvInputField(controller: _hostController, hint: i18n('ui_proxy_host_e_g_127_0_0_1'), maxLines: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: TvInputField(controller: _portController, hint: i18n('ui_proxy_port_e_g_7890'), maxLines: 1),
        ),
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
          onChanged: (_) => proxy.updateSettings(
            proxyState.copyWith(
              proxyHost: _hostController.text.trim(),
              proxyPort: int.tryParse(_portController.text.trim()) ?? proxyState.proxyPort,
            ),
          ),
        ),
      ],
    );
  }
}
