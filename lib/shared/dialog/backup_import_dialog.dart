import 'tv_dialog_utils.dart';
import 'tv_multi_select_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Asks which modules of a backup document an import should apply.
///
/// [modules] is what the document can provide and [defaults] is where the
/// selection starts: a TV document has everything ticked, anything else only the
/// user-data modules, because a phone cannot know better than the TV about its
/// player, theme or proxy. The user has the last word for the rest.
///
/// Returns the chosen modules, or null when the dialog was cancelled — the
/// caller must not import anything then.
Future<Set<String>?> showBackupImportPicker(
  BuildContext context, {
  required List<String> modules,
  required Set<String> defaults,
  required bool sourceIsTv,
}) {
  return TvDialogUtils.showMultiSelect<String>(
    context: context,
    title: '${i18n('backup_import_modules')} · '
        '${i18n(sourceIsTv ? 'backup_source_tv' : 'backup_source_other')}',
    items: <TvMultiSelectItem<String>>[
      for (final String module in modules)
        TvMultiSelectItem<String>(title: backupModuleLabel(module), value: module),
    ],
    initialSelection: defaults,
  );
}

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
