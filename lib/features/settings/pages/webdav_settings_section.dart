import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/webdav/webdav_config.dart';
import 'package:pure_live/services/webdav/webdav_sync_service.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// WebDAV settings: pick or edit a server configuration, then upload, list,
/// restore or delete remote settings backups.
class WebDavSettingsSectionPage extends ConsumerStatefulWidget {
  const WebDavSettingsSectionPage({super.key});

  @override
  ConsumerState<WebDavSettingsSectionPage> createState() => WebDavSettingsSectionPageState();
}

class WebDavSettingsSectionPageState extends ConsumerState<WebDavSettingsSectionPage> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();

  final _backup = WebDavBackupService();

  String _currentName = '';
  String _result = '';
  bool _busy = false;
  List<webdav.File> _remoteFiles = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialConfig());
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _loadInitialConfig() {
    final controller = ref.read(webDavControllerProvider.notifier);
    final stored = ref.read(webDavControllerProvider).currentWebDavConfig;
    final config = controller.getWebDavConfigByName(stored) ?? ref.read(webDavControllerProvider).webDavConfigs.firstOrNull;
    if (config != null) _applyConfig(config);
  }

  void _applyConfig(WebDAVConfig config) {
    setState(() {
      _currentName = config.name;
      _name.text = config.name;
      _address.text = config.address;
      _username.text = config.username;
      _password.text = config.password;
      _remoteFiles = const [];
      _result = '';
    });
  }

  WebDAVConfig? get _draftConfig {
    if (_address.text.trim().isEmpty) return null;
    return WebDAVConfig(name: _name.text.trim(), address: _address.text.trim(), username: _username.text, password: _password.text);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _result = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _saveConfig() {
    final config = _draftConfig;
    if (config == null) {
      setState(() => _result = i18n('webdav_address_empty'));
      return;
    }
    if (config.name.isEmpty) {
      setState(() => _result = i18n('webdav_config_name_empty'));
      return;
    }
    if (!WebDavSyncService.isValidAddress(config.address)) {
      setState(() => _result = i18n('webdav_address_invalid'));
      return;
    }
    final controller = ref.read(webDavControllerProvider.notifier);
    final existing = controller.getWebDavConfigByName(config.name);
    final ok = existing == null ? controller.addWebDavConfig(config) : controller.updateWebDavConfig(config);
    setState(() {
      _currentName = config.name;
      _result = ok ? i18n('save_success') : i18n('webdav_config_name_exists');
    });
  }

  void _deleteConfig() {
    final config = ref.read(webDavControllerProvider.notifier).getWebDavConfigByName(_currentName);
    if (config == null) return;
    ref.read(webDavControllerProvider.notifier).removeWebDavConfig(config);
    setState(() {
      _currentName = '';
      _name.clear();
      _address.clear();
      _username.clear();
      _password.clear();
      _remoteFiles = const [];
      _result = i18n('webdav_delete_success');
    });
  }

  @override
  Widget build(BuildContext context) {
    final configs = ref.watch(webDavControllerProvider).webDavConfigs;
    final config = _draftConfig;
    final theme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('webdav'),
                subtitle: _currentName.isEmpty ? i18n('webdav_no_config_create_first') : _currentName,
                icon: Icons.cloud_outlined,
                options: configs.isEmpty ? [i18n('webdav_no_config_create_first')] : configs.map((e) => e.name).toList(growable: false),
                index: configs.indexWhere((e) => e.name == _currentName),
                onChanged: configs.isEmpty ? null : (index) => _applyConfig(configs[index]),
              ),
              _field(_name, i18n('webdav_config_name'), false),
              _field(_address, i18n('webdav_address'), false),
              _field(_username, i18n('webdav_username'), false),
              _field(_password, i18n('webdav_password'), true),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('save'),
                icon: Icons.save_outlined,
                options: [i18n('save')],
                index: 0,
                onChanged: (_) => _saveConfig(),
              ),
              TvSettingsOptionTile(
                title: i18n('webdav_delete'),
                icon: Icons.delete_outline_rounded,
                options: [i18n('webdav_delete')],
                index: 0,
                onChanged: _currentName.isEmpty ? null : (_) => _deleteConfig(),
              ),
              TvSettingsOptionTile(
                title: i18n('webdav_upload_current'),
                subtitle: i18n('backup_to_webdav'),
                icon: Icons.cloud_upload_outlined,
                options: [i18n('webdav_upload_current')],
                index: 0,
                onChanged: config == null
                    ? null
                    : (_) => _run(() async {
                        await _backup.uploadBackup(config);
                        if (mounted) setState(() => _result = i18n('webdav_upload_success'));
                      }),
              ),
              TvSettingsOptionTile(
                title: i18n('webdav_my_files'),
                subtitle: i18n('webdav_refresh'),
                icon: Icons.folder_open_rounded,
                options: [i18n('webdav_refresh')],
                index: 0,
                onChanged: config == null
                    ? null
                    : (_) => _run(() async {
                        final files = await _backup.listBackups(config);
                        if (mounted) {
                          setState(() {
                            _remoteFiles = files;
                            _result = files.isEmpty ? i18n('webdav_load_failed') : i18n('webdav_sync_success');
                          });
                        }
                      }),
              ),
            ],
          ),
          if (_remoteFiles.isNotEmpty) ...[
            SizedBox(height: 12.h),
            TvSettingsCard(
              children: [
                for (final file in _remoteFiles) ...[
                  TvSettingsOptionTile(
                    title: '${file.name ?? i18n('webdav_unnamed_file')}  ${_formatSize(file.size)}',
                    icon: Icons.cloud_download_outlined,
                    options: [i18n('webdav_sync_to_local')],
                    index: 0,
                    onChanged: config == null
                        ? null
                        : (_) => _run(() async {
                            final path = _remotePath(file);
                            if (path == null) return;
                            await _backup.downloadAndRestore(config, path);
                            if (mounted) setState(() => _result = i18n('webdav_sync_success'));
                          }),
                  ),
                  TvSettingsOptionTile(
                    title: '${file.name ?? i18n('webdav_unnamed_file')}  ${i18n('webdav_delete')}',
                    icon: Icons.delete_outline_rounded,
                    options: [i18n('webdav_delete')],
                    index: 0,
                    onChanged: config == null
                        ? null
                        : (_) => _run(() async {
                            final path = _remotePath(file);
                            if (path == null) return;
                            await _backup.deleteRemoteFile(config, path);
                            if (mounted) {
                              setState(() {
                                _remoteFiles = _remoteFiles.where((e) => e != file).toList(growable: false);
                                _result = i18n('webdav_delete_success');
                              });
                            }
                          }),
                  ),
                ],
              ],
            ),
          ],
          if (_result.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(_result, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
            ),
          if (_busy)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(i18n('webdav_uploading'), style: TextStyle(fontSize: 14.sp, color: theme.primaryTextColor)),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint, bool obscure) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: TvInputField(controller: controller, hint: hint, obscureText: obscure, showPasswordToggle: obscure),
    );
  }

  static String? _remotePath(webdav.File file) {
    final path = file.path;
    if (path != null && path.isNotEmpty) return path;
    final name = file.name;
    if (name == null || name.isEmpty) return null;
    return name.startsWith('/') ? name : '/$name';
  }

  static String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
