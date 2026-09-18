import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/data/db_service.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/iptv/data/database.dart' as database;
import 'package:pure_live/features/iptv/services/iptv_sync_engine.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';


/// IPTV source management: imported playlists, the import actions (local file or
/// URL) and the auto-sync / request-header settings.
///
/// The rows mirror the desktop page (`pure_live/lib/modules/iptv/iptv_page.dart`)
/// and its manage page (`iptv_manage.dart`): the settings group carries the
/// auto-sync switch, the interval and the custom User-Agent; the resource lists
/// are grouped into network and local sources with per-item sync / auto-sync /
/// delete.
class IptvManageSectionPage extends ConsumerStatefulWidget {
  const IptvManageSectionPage({super.key});

  @override
  ConsumerState<IptvManageSectionPage> createState() => IptvManageSectionPageState();
}

class IptvManageSectionPageState extends ConsumerState<IptvManageSectionPage> {
  /// Interval choices offered by the desktop interval dialog.
  static const List<int> _intervalOptions = <int>[2, 6, 12, 24, 48, 72];

  final _urlController = TextEditingController();

  List<database.Provider> _providers = const [];
  String _status = '';
  bool _busy = false;
  bool _loading = true;
  bool _loadFailed = false;

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

  IptvSettingsController get _settings => ref.read(iptvSettingsControllerProvider.notifier);

  Future<void> _reload() async {
    try {
      final providers = await _db.getAllProviders();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _loading = false;
        _loadFailed = false;
      });
    } catch (error) {
      debugPrint('IPTV manage load failure: $error');
      if (!mounted) return;
      // The raw exception is never shown: it leaks paths and SQL internals.
      setState(() {
        _loading = false;
        _loadFailed = true;
        _status = i18n('manage_page_load_failed_subtitle');
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      // The desktop page reports a translated failure; the raw exception stays
      // in the debug log.
      debugPrint('IPTV manage action failure: $error');
      if (mounted) setState(() => _status = i18n('manage_page_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Re-reads the database after an action that changed sources or mappings.
  Future<void> _reloadWithStatus(String status) async {
    await _reload();
    if (mounted) setState(() => _status = status);
  }

  // ---------------------------------------------------------------- imports

  /// Downloads a playlist URL into a temp file and imports it.
  ///
  /// When [name] is empty the file name in the URL is used, as the desktop
  /// network-import dialog does.
  Future<void> _importPlaylistUrl({String url = '', String name = ''}) async {
    final target = url.trim().isEmpty ? _urlController.text.trim() : url.trim();
    if (target.isEmpty) {
      setState(() => _status = i18n('ui_parameter_error'));
      return;
    }
    await _run(() async {
      final content = await HttpClient.instance.getText(target, header: {'user-agent': HttpClient.iptvUserAgent});
      final ext = p.extension(Uri.parse(target).path).toLowerCase();
      final suffix = {'.m3u', '.m3u8', '.txt'}.contains(ext) ? ext : '.m3u';
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}iptv_import_${DateTime.now().millisecondsSinceEpoch}$suffix');
      await file.writeAsString(content);
      final urlName = p.basenameWithoutExtension(Uri.parse(target).path);
      final providerName = name.trim().isNotEmpty ? name.trim() : (urlName.isEmpty ? 'iptv' : urlName);
      final ok = await IptvImportManager().importIptvFile(
        file: file,
        providerName: providerName,
        url: target,
        forceUpdate: true,
        showTips: false,
      );
      await file.delete();
      await _reloadWithStatus(ok ? i18n('ui_imported') : i18n('ui_import_failed_or_file_not_found'));
    });
  }

  // --------------------------------------------------------------- provider

  Future<void> _syncProvider(database.Provider provider) => _run(() async {
    final ok = await IptvSyncEngine.instance.syncPlaylist(provider, showTips: false);
    await _reloadWithStatus(ok ? i18n('webdav_sync_success') : i18n('subscription_download_or_parse_failed'));
  });

  /// The desktop manage page's batch action: every network source whose
  /// per-item auto-sync switch is on.
  Future<void> _syncAllProviders() async {
    final targets = _networkProviders.where((provider) => provider.isAutoUpdate).toList(growable: false);
    if (targets.isEmpty) {
      setState(() => _status = i18n('manage_page_empty_tip'));
      return;
    }
    await _run(() async {
      var failures = 0;
      for (final provider in targets) {
        final ok = await IptvSyncEngine.instance.syncPlaylist(provider, showTips: false);
        if (!ok) failures++;
      }
      await _reloadWithStatus(i18n(failures == 0 ? 'manage_page_success' : 'manage_page_failed'));
    });
  }

  Future<void> _toggleAutoUpdate(database.Provider provider, bool value) => _run(() async {
    await _db.updateProviderUpdateStatus(provider.id, value);
    await _reloadWithStatus(i18n(value ? 'auto_sync_tag' : 'auto_sync_disabled'));
  });

  Future<void> _deleteProvider(database.Provider provider) async {
    final confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('delete_confirm_title'),
      message: i18n('delete_confirm_message'),
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
    );
    if (confirmed != true) return;
    // One cascading delete: channels and their favourites/failover rows go
    // together, so nothing can outlive the channel it points at.
    await _run(() async {
      await _db.deleteProviderCascading(provider.id);
      await _reloadWithStatus(i18n('manage_page_delete_success'));
    });
  }

  // --------------------------------------------------------------- settings

  Future<void> _editUserAgent() async {
    final value = await TvDialogUtils.showInput(
      context: context,
      title: i18n('edit_ua_title'),
      hintText: 'Mozilla/5.0...',
      initialValue: ref.read(iptvSettingsControllerProvider).customIptvUserAgent,
      maxLength: 500,
    );
    if (value == null) return;
    _settings.setCustomIptvUserAgent(value.trim());
    setState(() => _status = i18n('settings_saved'));
  }

  void _selectInterval(int hours) {
    _settings.setAutoSyncHoursInterval(hours);
    setState(() => _status = i18n('settings_saved'));
  }

  // ----------------------------------------------------------- list helpers

  static bool _isNetworkSource(String? url) {
    final value = url?.trim().toLowerCase() ?? '';
    return value.startsWith('http://') || value.startsWith('https://');
  }

  List<database.Provider> get _networkProviders =>
      _providers.where((provider) => _isNetworkSource(provider.url)).toList(growable: false);

  List<database.Provider> get _localProviders =>
      _providers.where((provider) => !_isNetworkSource(provider.url)).toList(growable: false);

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final settings = ref.watch(iptvSettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 20.h),
        TvSettingsGroupTitle(title: i18n('iptv_manage')),
        TvSettingsCard(children: _buildResourceRows()),
        SizedBox(height: 20.h),
        TvSettingsGroupTitle(title: i18n('playlist_settings')),
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
          ],
        ),
        SizedBox(height: 20.h),
        TvSettingsGroupTitle(title: i18n('auto_sync_settings')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('auto_sync_title'),
              subtitle: i18n('auto_sync_desc'),
              icon: Icons.sync_rounded,
              value: settings.isAutoSyncEnabled,
              onChanged: _busy ? null : (value) => _settings.setAutoSyncEnabled(value),
            ),
            if (settings.isAutoSyncEnabled)
              TvSettingsMenuTile<int>(
                title: i18n('sync_interval_title'),
                subtitle: i18n(
                  'sync_interval_hours',
                  args: {'hour': '${settings.autoSyncHoursInterval}'},
                ),
                icon: Icons.schedule_rounded,
                value: settings.autoSyncHoursInterval,
                valueMap: {
                  for (final hours in _intervalOptions) hours: '$hours ${i18n('hours')}',
                },
                onChanged: _busy ? null : _selectInterval,
              ),
            TvSettingsOptionTile(
              title: i18n('custom_ua_title'),
              subtitle: settings.customIptvUserAgent.isEmpty
                  ? i18n('custom_ua_desc')
                  : settings.customIptvUserAgent,
              icon: Icons.tv_rounded,
              options: [i18n('custom_ua_title')],
              index: 0,
              onChanged: _busy ? null : (_) => _editUserAgent(),
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

  /// Provider rows: empty state, load-failure state, then the 网络资源 /
  /// 本地资源 groups. A section is omitted when it has no rows.
  List<Widget> _buildResourceRows() {
    final rows = <Widget>[];

    if (_loadFailed) {
      rows.add(
        TvSettingsOptionTile(
          title: i18n('manage_page_load_failed_title'),
          subtitle: i18n('manage_page_load_failed_subtitle'),
          icon: Icons.error_outline_rounded,
          options: [i18n('retry')],
          index: 0,
          onChanged: _busy ? null : (_) => _run(_reload),
        ),
      );
      return rows;
    }
    if (_loading) {
      rows.add(
        TvSettingsOptionTile(
          title: i18n('refresh_loading'),
          icon: Icons.hourglass_empty_rounded,
          options: const [],
          index: 0,
        ),
      );
      return rows;
    }

    if (_providers.isEmpty) {
      rows.add(
        TvSettingsOptionTile(
          title: i18n('manage_page_empty_title'),
          subtitle: i18n('manage_page_empty_subtitle'),
          icon: Icons.playlist_add_rounded,
          options: const [],
          index: 0,
        ),
      );
      return rows;
    }

    void addGroupTitle(String title) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: 12.h));
      rows.add(TvSettingsGroupTitle(title: title));
    }

    final networkProviders = _networkProviders;
    final localProviders = _localProviders;

    if (networkProviders.isNotEmpty) {
      addGroupTitle(i18n('network_resource'));
      if (networkProviders.length > 1) {
        rows.add(
          TvSettingsOptionTile(
            title: i18n('sync'),
            icon: Icons.cloud_sync_outlined,
            options: [i18n('sync')],
            index: 0,
            onChanged: _busy ? null : (_) => _syncAllProviders(),
          ),
        );
      }
      for (final provider in networkProviders) {
        rows.addAll(_buildProviderRows(provider));
      }
    }
    if (localProviders.isNotEmpty) {
      addGroupTitle(i18n('local_resource'));
      for (final provider in localProviders) {
        rows.addAll(_buildProviderRows(provider));
      }
    }
    return rows;
  }

  List<Widget> _buildProviderRows(database.Provider provider) {
    final network = _isNetworkSource(provider.url);
    return [
      TvSettingsRow(
        title: provider.name,
        subtitle: provider.type,
        icon: Icons.playlist_play_rounded,
        trailingBuilder: (context, focused) => _buildActions(
          onSync: _busy || !network ? null : () => _syncProvider(provider),
          autoSync: _busy || !network ? null : provider.isAutoUpdate,
          onAutoSync: _busy || !network ? null : (value) => _toggleAutoUpdate(provider, value),
          onDelete: _busy ? null : () => _deleteProvider(provider),
        ),
      ),
    ];
  }

  /// Per-item actions from the desktop manage page: 同步, the 自动同步 switch
  /// and 删除, as one focusable TV button each.
  Widget _buildActions({
    required VoidCallback? onSync,
    required bool? autoSync,
    required ValueChanged<bool>? onAutoSync,
    required VoidCallback? onDelete,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSync != null)
          TvButton(
            title: i18n('sync'),
            size: TvButtonSize.mini,
            icon: Icon(Icons.cloud_download_outlined, size: 18.sp),
            onTap: onSync,
          ),
        if (autoSync != null) ...[
          SizedBox(width: 8.w),
          TvButton(
            title: i18n('auto_sync'),
            size: TvButtonSize.mini,
            selected: autoSync,
            icon: Icon(Icons.autorenew_rounded, size: 18.sp),
            onTap: () => onAutoSync?.call(!autoSync),
          ),
        ],
        SizedBox(width: 8.w),
        TvButton(
          title: i18n('delete'),
          size: TvButtonSize.mini,
          icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
          onTap: onDelete,
        ),
      ],
    );
  }
}
