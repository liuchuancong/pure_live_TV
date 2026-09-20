import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/data/db_service.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/iptv/data/database.dart' as database;
import 'package:pure_live/features/iptv/services/iptv_sync_engine.dart';

import 'package:pure_live/app/router/web_router.dart';
/// IPTV resource list page: the imported sources with per-item sync /
/// auto-sync / delete. Deleting a source always asks for confirmation because
/// the cascading delete also drops its channels.
class IptvResourcesSectionPage extends StatefulWidget {
  const IptvResourcesSectionPage({super.key});

  @override
  State<IptvResourcesSectionPage> createState() => _IptvResourcesSectionPageState();
}

class _IptvResourcesSectionPageState extends State<IptvResourcesSectionPage> {
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

  database.AppDatabase get _db => DbService.to.db;

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

  // ---------------------------------------------------------------- actions

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
    // A source delete cascades to its channels and favourites, so it always
    // confirms with the source name before touching the database.
    final confirmed = await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('delete_confirm_title'),
      message: '"${provider.name}"\n\n${i18n('delete_confirm_message')}',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280, route: WebRemoteRouter.sync)),
        SizedBox(height: 24.h),
        TvSettingsGroupTitle(title: i18n('hot_resource_url')),
        TvSettingsCard(children: [_buildHotResourceRow()]),
        SizedBox(height: 24.h),
        TvSettingsGroupTitle(title: i18n('iptv_resource_list')),
        TvSettingsCard(children: _buildResourceRows()),
        if (_status.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 10.h),
            child: Text(_status, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
          ),
      ],
    );
  }

  /// The built-in hot list's subscription URL, editable in place. An empty
  /// override means the scheduler uses the built-in iptv-org default.
  Widget _buildHotResourceRow() {
    final settings = SettingsService.to.iptv;
    final String override = settings.hotResourceUrl.v.trim();
    return TvSettingsRow(
      title: i18n('hot_resource_url'),
      subtitle: override.isNotEmpty
          ? override
          : '${i18n('hot_resource_url_hint')}\n${IptvSettingsController.defaultHotResourceUrl}',
      icon: Icons.live_tv_rounded,
      trailingBuilder: (context, focused) => TvButton(
        title: i18n('edit'),
        size: TvButtonSize.mini,
        onTap: _editHotResourceUrl,
      ),
      onSelect: _editHotResourceUrl,
    );
  }

  Future<void> _editHotResourceUrl() async {
    final settings = SettingsService.to.iptv;
    final result = await TvDialogUtils.showInput(
      context: context,
      title: i18n('hot_resource_url'),
      hintText: i18n('hot_resource_url_hint'),
      initialValue: settings.hotResourceUrl.v.trim(),
    );
    if (result == null) return;
    settings.setHotResourceUrl(result);
    if (!mounted) return;
    setState(() {});
  }

  /// Provider rows: empty state, load-failure state, then the network resources /
  /// local resources groups. A section is omitted when it has no rows.
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
        TvSettingsRow(
          title: i18n('refresh_loading'),
          icon: Icons.hourglass_empty_rounded,
        ),
      );
      return rows;
    }

    if (_providers.isEmpty) {
      rows.add(
        TvSettingsRow(
          title: i18n('manage_page_empty_title'),
          subtitle: i18n('manage_page_empty_subtitle'),
          icon: Icons.playlist_add_rounded,
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

  /// Per-item actions from the desktop manage page: sync, the auto-sync switch
  /// and delete, as one focusable TV button each.
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
