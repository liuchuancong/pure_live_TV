import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
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
          title: '启用网络代理',
          subtitle: '为 API、图片与弹幕连接启用统一代理',
          icon: Icons.vpn_key_rounded,
          value: proxyState.enableProxy,
          onChanged: (v) => proxy.updateSettings(proxyState.copyWith(enableProxy: v)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: TvInputField(controller: _hostController, hint: '代理主机，如 127.0.0.1', maxLines: 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: TvInputField(controller: _portController, hint: '代理端口，如 7890', maxLines: 1),
        ),
        TvSettingsOptionTile(
          title: '保存代理设置',
          subtitle: '主机：${_hostController.text.isEmpty ? '未填写' : _hostController.text}  端口：${_portController.text}',
          icon: Icons.save_rounded,
          options: const ['保存'],
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
