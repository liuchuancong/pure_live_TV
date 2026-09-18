import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';

/// IPTV import page: network playlist URLs only.
///
/// Local file picking is gone — a playlist file is uploaded through the web
/// remote page (scan the QR) instead, which also carries the request headers.
class IptvImportSectionPage extends StatefulWidget {
  const IptvImportSectionPage({super.key});

  @override
  State<IptvImportSectionPage> createState() => _IptvImportSectionPageState();
}

class _IptvImportSectionPageState extends State<IptvImportSectionPage> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();

  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Downloads a playlist URL into a temp file and imports it.
  ///
  /// When the name field is empty the file name in the URL is used, as the
  /// desktop network-import dialog does.
  Future<void> _importPlaylistUrl() async {
    final target = _urlController.text.trim();
    if (target.isEmpty) {
      setState(() => _status = i18n('ui_parameter_error'));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final content = await HttpClient.instance.getText(target, header: HttpClient.iptvHeaders());
      final ext = p.extension(Uri.parse(target).path).toLowerCase();
      final suffix = {'.m3u', '.m3u8', '.txt'}.contains(ext) ? ext : '.m3u';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}iptv_import_${DateTime.now().millisecondsSinceEpoch}$suffix');
      await file.writeAsString(content);
      final urlName = p.basenameWithoutExtension(Uri.parse(target).path);
      final name = _nameController.text.trim();
      final providerName = name.isNotEmpty ? name : (urlName.isEmpty ? 'iptv' : urlName);
      final ok = await IptvImportManager().importIptvFile(
        file: file,
        providerName: providerName,
        url: target,
        forceUpdate: true,
        showTips: false,
      );
      await file.delete();
      if (mounted) setState(() => _status = i18n(ok ? 'ui_imported' : 'ui_import_failed_or_file_not_found'));
    } catch (error) {
      debugPrint('IPTV network import failure: $error');
      if (mounted) setState(() => _status = i18n('ui_import_failed_or_file_not_found'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Typing a URL on a TV remote is not realistic: the phone page is the
        // primary way in — it offers both the URL import and file upload.
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 24.h),
        TvSettingsGroupTitle(title: i18n('iptv_import_url')),
        TvSettingsCard(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TvInputField(controller: _urlController, hint: i18n('iptv_playlist_url_hint')),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TvInputField(controller: _nameController, hint: i18n('iptv_playlist_name_hint')),
            ),
            TvSettingsOptionTile(
              title: i18n('iptv_import_url'),
              subtitle: i18n('iptv_import_url_desc'),
              icon: Icons.link_rounded,
              options: [i18n('iptv_import_url')],
              index: 0,
              onChanged: _busy ? null : (_) => _importPlaylistUrl(),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        TvSettingsGroupTitle(title: i18n('iptv_import_web_title')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('iptv_import_web_title'),
              subtitle: i18n('iptv_import_web_desc'),
              icon: Icons.qr_code_scanner_rounded,
              options: const [],
              index: 0,
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
