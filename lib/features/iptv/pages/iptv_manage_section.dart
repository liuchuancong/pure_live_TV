import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/iptv/data/database.dart' as database;
import 'package:pure_live/features/iptv/services/epg_import_manager.dart';
import 'package:pure_live/features/iptv/services/epg_sync_engine.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';
import 'package:pure_live/features/iptv/services/iptv_sync_engine.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/data/db_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// IPTV source management: imported playlists, EPG sources and the import
/// actions for both (local file or URL).
class IptvManageSectionPage extends ConsumerStatefulWidget {
  const IptvManageSectionPage({super.key});

  @override
  ConsumerState<IptvManageSectionPage> createState() => IptvManageSectionPageState();
}

class IptvManageSectionPageState extends ConsumerState<IptvManageSectionPage> {
  final _urlController = TextEditingController();

  List<database.Provider> _providers = const [];
  List<database.EpgSource> _epgSources = const [];
  String _status = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  database.AppDatabase get _db => DbService.to.db;

  Future<void> _reload() async {
    final providers = await _db.getAllProviders();
    final epgSources = await _db.getAllEpgSources();
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _epgSources = epgSources;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _status = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Imports a playlist from the file picker.
  Future<void> _importPlaylistFile() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: i18n('iptv_import_file'),
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    final path = picked?.path;
    if (path == null) return;
    await _run(() async {
      final file = File(path);
      final ok = await IptvImportManager().importIptvFile(
        file: file,
        providerName: p.basenameWithoutExtension(path),
        forceUpdate: true,
        showTips: false,
      );
      await _reload();
      if (mounted) setState(() => _status = ok ? i18n('ui_imported') : i18n('ui_import_failed_or_file_not_found'));
    });
  }

  /// Downloads a playlist URL into a temp file and imports it.
  Future<void> _importPlaylistUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _status = i18n('ui_parameter_error'));
      return;
    }
    await _run(() async {
      final content = await HttpClient.instance.getText(url);
      final ext = p.extension(Uri.parse(url).path).toLowerCase();
      final suffix = {'.m3u', '.m3u8', '.txt'}.contains(ext) ? ext : '.m3u';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}iptv_import_${DateTime.now().millisecondsSinceEpoch}$suffix');
      await file.writeAsString(content);
      final ok = await IptvImportManager().importIptvFile(
        file: file,
        providerName: p.basenameWithoutExtension(Uri.parse(url).path).isEmpty
            ? 'iptv'
            : p.basenameWithoutExtension(Uri.parse(url).path),
        url: url,
        forceUpdate: true,
        showTips: false,
      );
      await file.delete();
      await _reload();
      if (mounted) setState(() => _status = ok ? i18n('ui_imported') : i18n('ui_import_failed_or_file_not_found'));
    });
  }

  Future<void> _refreshProvider(database.Provider provider) => _run(() async {
    final ok = await IptvSyncEngine.instance.syncPlaylist(provider, showTips: false);
    await _reload();
    if (mounted) setState(() => _status = ok ? i18n('webdav_sync_success') : i18n('subscription_download_or_parse_failed'));
  });

  Future<void> _deleteProvider(database.Provider provider) => _run(() async {
    await _db.deleteProviderAndChannels(provider.id);
    await _db.deleteMappingsByProviderId(provider.id);
    await _reload();
    if (mounted) setState(() => _status = i18n('ui_saved'));
  });

  Future<void> _importEpg() => _run(() async {
    final ok = await EpgImportManager().importFromLocalPicker();
    await _reload();
    if (mounted) setState(() => _status = ok ? i18n('ui_imported') : i18n('epg_import_failed'));
  });

  Future<void> _refreshEpg(database.EpgSource source) => _run(() async {
    final ok = await EpgSyncEngine.instance.updateEpgCache(source, forceUpdate: true, showTips: false);
    await _reload();
    if (mounted) setState(() => _status = ok ? i18n('epg_source_updated') : i18n('epg_import_failed'));
  });

  Future<void> _deleteEpg(database.EpgSource source) => _run(() async {
    await _db.deleteEpgSourceCascading(source.id);
    await _reload();
    if (mounted) setState(() => _status = i18n('ui_saved'));
  });

  String _selectedSourceName() => ref.read(iptvSettingsControllerProvider).selectedSourceName;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: TvInputField(controller: _urlController, hint: i18n('iptv_playlist_url_hint')),
              ),
              TvSettingsOptionTile(
                title: i18n('iptv_import_url'),
                icon: Icons.link_rounded,
                options: [i18n('iptv_import_url')],
                index: 0,
                onChanged: _busy ? null : (_) => _importPlaylistUrl(),
              ),
              TvSettingsOptionTile(
                title: i18n('iptv_import_file'),
                subtitle: i18n('unsupported_file_format'),
                icon: Icons.upload_file_rounded,
                options: [i18n('iptv_import_file')],
                index: 0,
                onChanged: _busy ? null : (_) => _importPlaylistFile(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              for (final provider in _providers) ...[
                TvSettingsOptionTile(
                  title: provider.name,
                  subtitle: '${provider.type}${_selectedSourceName() == provider.name ? " · ${i18n('logined')}" : ""}',
                  icon: Icons.playlist_play_rounded,
                  options: [i18n('ui_refresh')],
                  index: 0,
                  onChanged: _busy ? null : (_) => _refreshProvider(provider),
                ),
                TvSettingsOptionTile(
                  title: '${provider.name} · ${i18n('delete')}',
                  icon: Icons.delete_outline_rounded,
                  options: [i18n('delete')],
                  index: 0,
                  onChanged: _busy ? null : (_) => _deleteProvider(provider),
                ),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('epg_import'),
                icon: Icons.event_note_outlined,
                options: [i18n('epg_import')],
                index: 0,
                onChanged: _busy ? null : (_) => _importEpg(),
              ),
              for (final source in _epgSources) ...[
                TvSettingsOptionTile(
                  title: source.name,
                  subtitle: source.url,
                  icon: Icons.calendar_month_outlined,
                  options: [i18n('ui_refresh')],
                  index: 0,
                  onChanged: _busy ? null : (_) => _refreshEpg(source),
                ),
                TvSettingsOptionTile(
                  title: '${source.name} · ${i18n('delete')}',
                  icon: Icons.delete_outline_rounded,
                  options: [i18n('delete')],
                  index: 0,
                  onChanged: _busy ? null : (_) => _deleteEpg(source),
                ),
              ],
            ],
          ),
          if (_status.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(_status, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
            ),
        ],
      ),
    );
  }
}
