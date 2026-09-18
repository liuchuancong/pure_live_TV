import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';

/// IPTV request-header page: User-Agent, Referer and Cookie, each its own
/// field. These headers are sent with every playlist download/sync and used as
/// the playback fallback for channels without their own directives; the phone
/// web page edits the same three fields remotely.
class IptvHeadersSectionPage extends ConsumerStatefulWidget {
  const IptvHeadersSectionPage({super.key});

  @override
  ConsumerState<IptvHeadersSectionPage> createState() => _IptvHeadersSectionPageState();
}

class _IptvHeadersSectionPageState extends ConsumerState<IptvHeadersSectionPage> {
  IptvSettingsController get _settings => ref.read(iptvSettingsControllerProvider.notifier);

  String _status = '';

  Future<void> _edit({
    required String title,
    required String hint,
    required String current,
    required ValueChanged<String> onSave,
  }) async {
    final value = await TvDialogUtils.showInput(
      context: context,
      title: title,
      hintText: hint,
      initialValue: current,
      maxLength: 2000,
    );
    if (value == null) return;
    onSave(value.trim());
    setState(() => _status = i18n('settings_saved'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final settings = ref.watch(iptvSettingsControllerProvider);

    String subtitle(String value) => value.isEmpty ? i18n('iptv_headers_empty_desc') : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('iptv_headers_settings')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('custom_ua_title'),
              subtitle: subtitle(settings.customIptvUserAgent),
              icon: Icons.tv_rounded,
              options: [i18n('edit')],
              index: 0,
              onChanged: (_) => _edit(
                title: i18n('edit_ua_title'),
                hint: 'Mozilla/5.0...',
                current: settings.customIptvUserAgent,
                onSave: _settings.setCustomIptvUserAgent,
              ),
            ),
            TvSettingsOptionTile(
              title: i18n('iptv_referer_title'),
              subtitle: subtitle(settings.customIptvReferer),
              icon: Icons.link_rounded,
              options: [i18n('edit')],
              index: 0,
              onChanged: (_) => _edit(
                title: i18n('iptv_referer_title'),
                hint: 'http://example.com/',
                current: settings.customIptvReferer,
                onSave: _settings.setCustomIptvReferer,
              ),
            ),
            TvSettingsOptionTile(
              title: i18n('iptv_cookie_title'),
              subtitle: subtitle(settings.customIptvCookie),
              icon: Icons.cookie_rounded,
              options: [i18n('edit')],
              index: 0,
              onChanged: (_) => _edit(
                title: i18n('iptv_cookie_title'),
                hint: 'a=b; c=d',
                current: settings.customIptvCookie,
                onSave: _settings.setCustomIptvCookie,
              ),
            ),
          ],
        ),
        if (_status.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 10.h),
            child: Text(_status, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
          ),
      ],
    );
  }
}
