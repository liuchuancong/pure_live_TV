import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/backup/backup_controller.dart';

/// Icon per backup module, keyed by the module name.
///
/// Kept next to the picker rather than on the controller: it is presentation, and
/// a module the app does not know still gets a row (with [Icons.extension_outlined]).
const Map<String, IconData> _kModuleIcons = <String, IconData>{
  'app': Icons.settings_outlined,
  'theme': Icons.palette_outlined,
  'font': Icons.text_fields_rounded,
  'player': Icons.play_circle_outline_rounded,
  'danmaku': Icons.chat_bubble_outline_rounded,
  'volume': Icons.volume_up_outlined,
  'favorite': Icons.favorite_border_rounded,
  'history': Icons.history_rounded,
  'iptv': Icons.live_tv_outlined,
  'cookie': Icons.cookie_outlined,
  'proxy': Icons.lan_outlined,
  'exit': Icons.logout_rounded,
  'startup': Icons.power_settings_new_rounded,
  'refresh': Icons.refresh_rounded,
  'page': Icons.dashboard_customize_outlined,
  'log': Icons.receipt_long_outlined,
  'tags': Icons.sell_outlined,
};

/// The name a backup module is shown under.
///
/// Each label is the title its own settings page already uses, so the picker
/// reads like the settings tree it restores. An unknown module falls back to its
/// own name rather than disappearing from the list.
String backupModuleLabel(String module) {
  final String? key = switch (module) {
    'app' => 'general',
    'theme' => 'ui_theme',
    'font' => 'font_family_settings',
    'player' => 'core_kernel_settings',
    'danmaku' => 'danmaku_settings',
    'volume' => 'audio_settings',
    'favorite' => 'favorites',
    'history' => 'history',
    'iptv' => 'iptv_settings',
    'cookie' => 'cookie',
    'proxy' => 'proxy_settings',
    'exit' => 'exit_without_ask',
    'startup' => 'startup',
    'refresh' => 'auto_refresh_settings',
    'page' => 'page_settings',
    'log' => 'log_manage',
    'tags' => 'tag_management',
    _ => null,
  };

  return key == null ? module : i18n(key);
}

/// Picks which settings modules a backup carries or applies.
///
/// This used to be a modal multi-select dialog. It is a page now because the
/// list is long enough to need scrolling and because the same choice is asked for
/// in six places — create a local backup, push one over the LAN, export over the
/// web remote, restore a file, receive a LAN push, receive a web-remote upload —
/// and every one of them should look the same. A pushed page also keeps the
/// d-pad behaviour the rest of the app has: the back button exits without
/// applying anything.
class BackupModulePage extends StatefulWidget {
  const BackupModulePage({
    super.key,
    required this.title,
    required this.modules,
    required this.selected,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<String> modules;
  final Set<String> selected;

  @override
  State<BackupModulePage> createState() => _BackupModulePageState();
}

class _BackupModulePageState extends State<BackupModulePage> {
  late final Set<String> _selected = <String>{...widget.selected};

  void _toggle(String module) {
    setState(() {
      if (!_selected.remove(module)) _selected.add(module);
    });
  }

  void _selectAll() => setState(() {
    _selected
      ..clear()
      ..addAll(widget.modules);
  });

  void _selectNone() => setState(_selected.clear);

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final int total = widget.modules.length;
    final int chosen = _selected.length;

    return TvPageScaffold(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 8.ts(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.subtitle != null)
                    Padding(
                      padding: EdgeInsets.only(left: 8.ts(context), bottom: 12.ts(context)),
                      child: Text(
                        widget.subtitle!,
                        style: AppTextStyles.t18.copyWith(
                          fontWeight: FontWeight.w300,
                          color: theme.secondaryTextColor,
                        ),
                      ),
                    ),
                  TvSettingsCard(
                    children: [
                      for (final String module in widget.modules)
                        TvSettingsRow(
                          title: backupModuleLabel(module),
                          subtitle: module,
                          icon: _kModuleIcons[module] ?? Icons.extension_outlined,
                          onSelect: () => _toggle(module),
                          trailingBuilder: (context, focused) =>
                              TvSettingsSwitchIndicator(value: _selected.contains(module), focused: focused),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.ts(context)),
                ],
              ),
            ),
          ),
          // The action bar is part of the page rather than a dialog footer: the
          // count and the two bulk actions have to stay visible while the list
          // scrolls.
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 16.ts(context)),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.secondaryTextColor.withValues(alpha: 0.12), width: 1.ts(context)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  i18nOr('backup_modules_selected', '{chosen}/{total} 项已选', args: {
                    'chosen': '$chosen',
                    'total': '$total',
                  }),
                  style: AppTextStyles.t18.copyWith(color: theme.secondaryTextColor),
                ),
                SizedBox(width: 20.ts(context)),
                TvButton(
                  title: i18nOr('backup_select_all', '全选'),
                  size: TvButtonSize.small,
                  isSecondary: true,
                  onTap: _selectAll,
                ),
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18nOr('backup_select_none', '全不选'),
                  size: TvButtonSize.small,
                  isSecondary: true,
                  onTap: chosen == 0 ? null : _selectNone,
                ),
                const Spacer(),
                TvButton(
                  title: i18nOr('cancel', '取消'),
                  size: TvButtonSize.small,
                  isSecondary: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18nOr('confirm', '确定'),
                  size: TvButtonSize.small,
                  autofocus: true,
                  // An empty document carries no recognized section and would be
                  // rejected on import, so there is nothing to confirm.
                  onTap: chosen == 0 ? null : () => Navigator.of(context).pop(_selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens [BackupModulePage] and returns the chosen modules.
///
/// Null means the page was left without confirming — the caller must then do
/// nothing at all. Pushed through the root navigator so the service-side callers
/// (a LAN push arriving, a web-remote upload) land on the same page as the ones
/// driven from a settings row.
Future<Set<String>?> showBackupModulePicker(
  BuildContext context, {
  required String title,
  required List<String> modules,
  required Set<String> selected,
  String? subtitle,
}) {
  return Navigator.of(context, rootNavigator: true).push<Set<String>>(
    MaterialPageRoute<Set<String>>(
      builder: (_) => BackupModulePage(
        title: title,
        subtitle: subtitle,
        modules: modules,
        selected: selected,
      ),
    ),
  );
}

/// Which modules of a backup document an import should apply.
///
/// [modules] is what the document can provide and [defaults] is where the
/// selection starts: a TV document has everything ticked, anything else only the
/// user-data modules, because a phone cannot know better than the TV about its
/// player, theme or proxy. The user has the last word for the rest.
///
/// Returns the chosen modules, or null when the page was left — the caller must
/// not import anything then.
Future<Set<String>?> showBackupImportPicker(
  BuildContext context, {
  required List<String> modules,
  required Set<String> defaults,
  required bool sourceIsTv,
}) {
  return showBackupModulePicker(
    context,
    title: i18n('backup_import_modules'),
    subtitle: i18n(sourceIsTv ? 'backup_source_tv' : 'backup_source_other'),
    modules: modules,
    selected: defaults,
  );
}

/// Which modules an export should write.
///
/// Everything starts ticked: an export is the user's own file, and dropping a
/// module silently is exactly the surprise this picker exists to remove.
/// Returns null when the page was left without confirming.
Future<Set<String>?> showBackupExportPicker(BuildContext context, {Set<String>? initial}) {
  return showBackupModulePicker(
    context,
    title: i18nOr('backup_export_modules', '选择要导出的模块'),
    subtitle: i18nOr('backup_export_hint', '勾选需要写入备份文件的模块；未勾选的不会出现在文件里'),
    modules: BackupController.knownSections,
    selected: initial ?? BackupController.knownSections.toSet(),
  );
}
