import 'dart:io';

import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/models/font_model/font_model.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/font_settings/font_download_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

/// Cloud-font manager: factory default on top, one card per family under cloud fonts.
///
/// One row per family does everything by direct clicks — no pre-action menu:
/// an un-downloaded family starts its download right away, a downloading one
/// cancels it, and a downloaded one applies itself (multi-weight families ask
/// which weight to lock, or apply all). Downloads live in the global
/// [FontDownloadController], so they continue — and apply the font — after the
/// user leaves this page; while one runs, the row's trailing side shows a mini
/// [AppStatusView] loading button. The family in force is re-registered on
/// startup (see `FontSettingsController`), with a fallback to the bundled font
/// when its files are gone.
class FontFamilyManagerSectionPage extends ConsumerStatefulWidget {
  const FontFamilyManagerSectionPage({super.key, this.danmaku = false});

  /// danmaku font instead of the app font.
  final bool danmaku;

  @override
  ConsumerState<FontFamilyManagerSectionPage> createState() => FontFamilyManagerSectionPageState();
}

class FontFamilyManagerSectionPageState extends ConsumerState<FontFamilyManagerSectionPage> {
  /// Family id → disk usage, for the families that are actually on disk.
  final Map<String, String> _sizes = <String, String>{};

  bool get _danmakuMode => widget.danmaku;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  List<FontModel> get _fonts => ref.read(fontSettingsControllerProvider.notifier).fontList;

  /// The family in force for this page's mode.
  String get _activeId {
    if (_danmakuMode) return ref.read(danmakuSettingsControllerProvider).danmakuFontFamilyName;
    return ref.read(fontSettingsControllerProvider).value?.fontFamilyName ?? 'Default';
  }

  /// The weight file the family in force is locked to (`''` = the whole family).
  String get _activeFileName {
    if (_danmakuMode) return ref.read(danmakuSettingsControllerProvider.notifier).danmakuFontFamilyFileName;
    return ref.read(fontSettingsControllerProvider.notifier).fontFamilyFileName;
  }

  bool _isDownloaded(FontModel font) => _sizes.containsKey(font.id);

  /// Re-reads the disk and re-registers every downloaded family.
  ///
  /// Registering more than the active family is what lets each card preview itself in
  /// its own font; the active one has to be registered anyway after a restart.
  Future<void> _refresh() async {
    await ref.read(fontSettingsControllerProvider.notifier).refreshFontDiskSizes(force: true);
    if (!mounted) return;

    final Map<String, String> sizes = Map<String, String>.of(
      ref.read(fontSettingsControllerProvider.notifier).fontFolderSizes,
    );
    setState(() {
      _sizes
        ..clear()
        ..addAll(sizes);
    });

    for (final FontModel font in _fonts) {
      if (!sizes.containsKey(font.id)) continue;
      // The active family is already registered with the weight it is locked to;
      // registering all of its files here would undo that lock.
      if (font.id == _activeId) continue;
      try {
        await FontDownloadManager.instance.loadFont(font.id);
      } catch (_) {
        // The preview falls back to the platform family; not fatal.
      }
    }
  }

  /// factory default.
  Future<void> _resetFamily() async {
    if (_danmakuMode) {
      await ref.read(danmakuSettingsControllerProvider.notifier).resetDanmakuFontFamily();
    } else {
      await ref.read(fontSettingsControllerProvider.notifier).resetAppFontFamily();
    }
    if (mounted) setState(() {});
    ToastUtil.show(i18n('font_reset_default'));
  }

  /// What one click on a family row does: download → cancel download → apply.
  Future<void> _onSelectFamily(FontModel font) async {
    final downloads = ref.read(fontDownloadControllerProvider.notifier);

    // Downloading: the same click that started it cancels it.
    if (downloads.isDownloading(font.id)) {
      downloads.cancel(font.id);
      return;
    }

    // Not on disk yet: download in the background, apply when it lands.
    if (!_isDownloaded(font)) {
      await downloads.startDownload(font, danmaku: _danmakuMode);
      if (mounted) await _refresh();
      return;
    }

    // Downloaded: apply — several weights ask which one to lock.
    if (font.files.length <= 1) {
      await _activate(font);
      return;
    }
    await _chooseWeight(font);
  }

  Future<void> _activate(FontModel font, {String? targetFileName}) async {
    final bool ok = _danmakuMode
        ? await ref
              .read(danmakuSettingsControllerProvider.notifier)
              .activateDanmakuFontFamily(font, targetFileName: targetFileName)
        : await ref
              .read(fontSettingsControllerProvider.notifier)
              .activateFontFamily(font, targetFileName: targetFileName);
    if (ok && mounted) setState(() {});
  }

  /// The weight picker of a multi-weight family, with auto (all files) on top.
  Future<void> _chooseWeight(FontModel font) async {
    final List<File> files = await FontDownloadManager.instance.listDownloadedFontFiles(font.id);
    if (!mounted) return;
    if (files.isEmpty) {
      ToastUtil.show(i18n('font_not_downloaded_or_corrupted'));
      return;
    }

    final String activeFile = _activeId == font.id ? _activeFileName : '';
    final List<TvSelectItem<String>> items = <TvSelectItem<String>>[
      TvSelectItem(
        title: i18n('font_auto_weight'),
        subtitle: i18n('font_auto_weight_desc'),
        value: '',
        leading: Icon(Icons.auto_awesome, size: 26.sp),
      ),
      for (final File file in files)
        TvSelectItem(
          title: i18n('font_lock_weight', args: {'label': FontDownloadManager.weightLabelOf(file.path)}),
          subtitle: i18n('font_lock_weight_desc'),
          value: FontDownloadManager.fileNameOf(file.path),
          leading: Icon(Icons.font_download_outlined, size: 26.sp),
        ),
    ];

    final String? choice = await TvDialogUtils.showSelect<String>(
      context: context,
      title: i18n('font_selector_title', args: {'name': font.name}),
      items: items,
      selectedValue: activeFile,
    );
    if (!mounted || choice == null) return;
    await _activate(font, targetFileName: choice.isEmpty ? null : choice);
  }

  Future<void> _confirmDelete(FontModel font) async {
    await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('delete'),
      message: font.name,
      confirmText: i18n('confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () async => _deleteFamily(font),
    );
  }

  /// Deletes the files and drops both selections when they pointed at this family.
  Future<void> _deleteFamily(FontModel font) async {
    await ref.read(fontSettingsControllerProvider.notifier).uninstallFontFamily(font);
    await ref.read(danmakuSettingsControllerProvider.notifier).resetIfActive(font.id);
    if (!mounted) return;
    // Re-read the disk: the deleted family must stop looking installed right away.
    await _refresh();
    if (!mounted) return;
    ToastUtil.show(i18n('delete_success'));
  }

  @override
  Widget build(BuildContext context) {
    // Watch all three: the manifest arrives from an async provider (the list is
    // otherwise empty until something else rebuilds), an activation from anywhere has
    // to move the in use mark, and the download phases drive the trailing button.
    ref.watch(fontSettingsControllerProvider);
    ref.watch(danmakuSettingsControllerProvider);
    final downloadState = ref.watch(fontDownloadControllerProvider);

    final String activeId = _activeId;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('factory_default_group')),
          TvSettingsCard(
            children: [
              TvSettingsRow(
                title: _danmakuMode ? i18n('font_system_default') : i18n('font_default'),
                subtitle: activeId == 'Default'
                    ? i18n('factory_default_desc')
                    : '${i18n('font_family')}: ${_fontNameOf(activeId)}',
                icon: Icons.settings_suggest_outlined,
                trailingBuilder: (context, focused) =>
                    tvSettingsValueLabel(context, focused, activeId == 'Default' ? i18n('font_currently_active') : i18n('apply')),
                onSelect: _resetFamily,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          TvSettingsGroupTitle(title: i18n('cloud_font_group')),
          if (_fonts.isEmpty)
            SizedBox(
              height: 200.h,
              child: const AppStatusView(type: AppStatusType.loading),
            ),
          for (final FontModel font in _fonts) ...[
            TvSettingsCard(
              children: [
                TvSettingsRow(
                  title: font.name,
                  subtitle: _subtitleOf(font),
                  icon: Icons.font_download_outlined,
                  trailingBuilder: (context, focused) => _trailingOf(font, downloadState, focused),
                  onSelect: () => _onSelectFamily(font),
                  // Delete keeps its own affordance below the row: the click
                  // itself now applies the family.
                  footer: _isDownloaded(font) && downloadState[font.id] != FontDownloadPhase.downloading
                      ? Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: TvButton(
                            title: i18n('delete'),
                            size: TvButtonSize.mini,
                            isSecondary: true,
                            onTap: () => _confirmDelete(font),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }

  /// The right-hand status: a mini [AppStatusView] loading button while the
  /// family downloads (the row's click cancels it), the state label otherwise.
  Widget _trailingOf(FontModel font, Map<String, FontDownloadPhase> downloadState, bool focused) {
    if (downloadState[font.id] == FontDownloadPhase.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28.w,
            height: 28.w,
            child: const AppStatusView(type: AppStatusType.loading, isMini: true),
          ),
          SizedBox(width: 10.w),
          tvSettingsValueLabel(context, focused, i18n('cancel')),
        ],
      );
    }
    if (downloadState[font.id] == FontDownloadPhase.failed) {
      return tvSettingsValueLabel(context, focused, i18n('font_download_failed'));
    }
    return tvSettingsValueLabel(context, focused, _stateLabelOf(font));
  }

  /// Description · weight count · licence · disk usage, plus the locked weight.
  String _subtitleOf(FontModel font) {
    final List<String> parts = <String>[];
    if (font.desc.isNotEmpty) parts.add(font.desc);
    parts.add('${font.files.length} ${i18n('font_units_suffix')}');
    final String license = '${font.license['name'] ?? ''}';
    if (license.isNotEmpty) parts.add(license);
    final String? size = _sizes[font.id];
    if (size != null) parts.add(size);
    if (_activeId == font.id) {
      final String locked = _activeFileName;
      if (locked.isNotEmpty) parts.add(FontDownloadManager.weightLabelOf(locked));
    }
    return parts.join(' · ');
  }

  String _stateLabelOf(FontModel font) {
    if (_activeId == font.id) return i18n('font_currently_active');
    if (_isDownloaded(font)) return i18n('font_downloaded');
    return i18n('download');
  }

  String _fontNameOf(String id) {
    for (final font in _fonts) {
      if (font.id == id) return font.name;
    }
    return id == 'Default' ? i18n('font_default') : id;
  }
}
