import 'dart:io';

import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/models/font_model/font_model.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

/// The actions the manager offers for one family.
enum FontFamilyAction { download, apply, delete }

/// Cloud-font manager: 出厂默认 on top, one card per family under 云字体.
///
/// Follows the mobile page (`font_family_manager_page.dart`) rather than doing the work
/// inline in the rows: picking a family opens a menu (下载 / 应用 / 删除), deleting asks
/// first, a download runs behind a modal [AppStatusView], and a family made of several
/// weight files asks which weight to lock — or applies all of them. The family in force
/// is re-registered on startup (see `FontSettingsController`), with a fallback to the
/// bundled font when its files are gone.
class FontFamilyManagerSectionPage extends ConsumerStatefulWidget {
  const FontFamilyManagerSectionPage({super.key, this.danmaku = false});

  /// 弹幕字体 instead of the app font.
  final bool danmaku;

  @override
  ConsumerState<FontFamilyManagerSectionPage> createState() => FontFamilyManagerSectionPageState();
}

class FontFamilyManagerSectionPageState extends ConsumerState<FontFamilyManagerSectionPage> {
  /// Family id → disk usage, for the families that are actually on disk.
  final Map<String, String> _sizes = <String, String>{};

  /// The family a download dialog is currently open for.
  String _busyFontId = '';

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

  /// 出厂默认.
  Future<void> _resetFamily() async {
    if (_danmakuMode) {
      await ref.read(danmakuSettingsControllerProvider.notifier).resetDanmakuFontFamily();
    } else {
      await ref.read(fontSettingsControllerProvider.notifier).resetAppFontFamily();
    }
    if (mounted) setState(() {});
    ToastUtil.show(i18n('font_reset_default'));
  }

  /// The menu behind one family row.
  Future<void> _openFamilyMenu(FontModel font) async {
    if (_busyFontId.isNotEmpty) return;

    final bool downloaded = _isDownloaded(font);
    final List<TvMenuItem<FontFamilyAction>> items = <TvMenuItem<FontFamilyAction>>[
      if (!downloaded)
        TvMenuItem(
          title: i18n('download'),
          subtitle: i18nOr('font_download_entry_subtitle', '下载后即可应用'),
          value: FontFamilyAction.download,
          leading: Icon(Remix.download_cloud_2_line, size: 26.sp),
        )
      else ...[
        TvMenuItem(
          title: i18n('apply'),
          subtitle: font.files.length > 1 ? i18n('font_selector_subtitle') : null,
          value: FontFamilyAction.apply,
          leading: Icon(Icons.check_rounded, size: 26.sp),
        ),
        TvMenuItem(
          title: i18n('delete'),
          value: FontFamilyAction.delete,
          leading: Icon(Remix.delete_bin_6_line, size: 26.sp),
        ),
      ],
    ];

    final FontFamilyAction? action = await TvDialogUtils.showMenu<FontFamilyAction>(
      context: context,
      title: font.name,
      items: items,
      selectedValue: downloaded ? FontFamilyAction.apply : FontFamilyAction.download,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case FontFamilyAction.download:
        await _downloadAndApply(font);
      case FontFamilyAction.apply:
        await _applyFamily(font);
      case FontFamilyAction.delete:
        await _confirmDelete(font);
    }
  }

  /// 应用: a single-file family goes straight on; several weights ask which one.
  Future<void> _applyFamily(FontModel font) async {
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

  /// The weight picker of a multi-weight family, with 自动 (all files) on top.
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

  /// 下载, behind the modal that shows the app's loading animation, then apply.
  Future<void> _downloadAndApply(FontModel font) async {
    setState(() => _busyFontId = font.id);

    final bool ok =
        await TvDialogUtils.show<bool>(
          context: context,
          builder: (_) => FontDownloadProgressDialog(
            fontName: font.name,
            download: () => FontDownloadManager.instance.downloadFontFamily(fontModel: font, onStateChanged: (_) {}),
          ),
        ) ??
        false;

    if (!mounted) return;
    setState(() => _busyFontId = '');

    if (!ok) {
      ToastUtil.show(i18n('font_download_failed'));
      return;
    }

    await _refresh();
    if (!mounted) return;
    ToastUtil.show(i18n('font_downloaded'));
    await _applyFamily(font);
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
    // Watch both controllers: the manifest arrives from an async provider (the list is
    // otherwise empty until something else rebuilds) and an activation from anywhere has
    // to move the 当前使用中 mark.
    ref.watch(fontSettingsControllerProvider);
    ref.watch(danmakuSettingsControllerProvider);

    final tvTheme = context.tvTheme;
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
                  trailingBuilder: (context, focused) => tvSettingsValueLabel(context, focused, _stateLabelOf(font)),
                  onSelect: () => _openFamilyMenu(font),
                ),
                // The sample is drawn in the family itself, so picking one is not a
                // guess at a name. Only for downloaded families: the family has to be
                // registered for the text to render in it.
                if (_isDownloaded(font))
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 16.h),
                    child: Text(
                      i18n('font_preview_sample'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: font.id, fontSize: 22.sp, color: tvTheme.primaryTextColor),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
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
    if (_busyFontId == font.id) return i18n('font_downloading');
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

/// The modal shown while a family downloads.
///
/// It owns the flow: [download] starts on the first frame, the dialog pops itself with
/// the result, and the page then decides whether to apply the family, ask for a weight,
/// or report the failure. Waiting behind a spinner with no way back is only acceptable
/// because it always ends — a failure pops with `false` rather than leaving it open.
class FontDownloadProgressDialog extends StatefulWidget {
  const FontDownloadProgressDialog({super.key, required this.fontName, required this.download});

  final String fontName;
  final Future<bool> Function() download;

  @override
  State<FontDownloadProgressDialog> createState() => _FontDownloadProgressDialogState();
}

class _FontDownloadProgressDialogState extends State<FontDownloadProgressDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final bool ok = await widget.download();
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: widget.fontName,
      child: SizedBox(
        height: 200.sp,
        child: AppStatusView(type: AppStatusType.loading, subtitle: i18n('font_downloading')),
      ),
    );
  }
}
