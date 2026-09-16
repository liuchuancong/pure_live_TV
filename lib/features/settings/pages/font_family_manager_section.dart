import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/font_model/font_model.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';

/// Font family manager: download a font from the manifest, activate it or
/// remove it from the device.
///
/// Two modes share this page: [danmaku] `false` switches the whole app font
/// (`fontFamilyName`); `true` writes `danmakuFontFamilyName` so only the
/// danmaku layer picks the family up. Each downloaded font renders a preview
/// line in its own family, and the trailing label always says where the font
/// stands (使用中 / 已下载 / 下载).
class FontFamilyManagerSectionPage extends ConsumerStatefulWidget {
  const FontFamilyManagerSectionPage({super.key, this.danmaku = false});

  final bool danmaku;

  @override
  ConsumerState<FontFamilyManagerSectionPage> createState() => FontFamilyManagerSectionPageState();
}

class FontFamilyManagerSectionPageState extends ConsumerState<FontFamilyManagerSectionPage> {
  final Set<String> _downloaded = {};
  String _status = '';
  String _busyFontId = '';

  bool get _danmakuMode => widget.danmaku;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDownloaded());
  }

  List<FontModel> get _fonts => ref.read(fontSettingsControllerProvider.notifier).fontList;

  /// The family in force for this page's mode.
  String get _activeId {
    if (_danmakuMode) {
      return ref.read(danmakuSettingsControllerProvider).danmakuFontFamilyName;
    }
    return ref.read(fontSettingsControllerProvider).value?.fontFamilyName ?? 'Default';
  }

  /// Refreshes the downloaded set and registers every downloaded family, so
  /// the preview line can render in the font itself instead of the fallback.
  Future<void> _refreshDownloaded() async {
    final manager = FontDownloadManager.instance;
    final downloaded = <String>{};
    for (final font in _fonts) {
      if (font.id.isEmpty) continue;
      if (await manager.checkFontDownloaded(font.id)) {
        downloaded.add(font.id);
        try {
          await manager.loadFont(font.id);
        } catch (_) {
          // Preview falls back to the default family; not fatal.
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _downloaded
        ..clear()
        ..addAll(downloaded);
    });
  }

  Future<void> _activate(FontModel font) async {
    if (_danmakuMode) {
      final current = ref.read(danmakuSettingsControllerProvider);
      ref.read(danmakuSettingsControllerProvider.notifier).updateSettings(
        current.copyWith(danmakuFontFamilyName: font.id),
      );
      await FontDownloadManager.instance.loadFont(font.id);
    } else {
      await ref.read(fontSettingsControllerProvider.notifier).activateFontFamily(font);
    }
    if (mounted) setState(() => _status = '${i18n('font_family')}: ${font.name}');
  }

  Future<void> _resetFont() async {
    if (_danmakuMode) {
      final current = ref.read(danmakuSettingsControllerProvider);
      ref.read(danmakuSettingsControllerProvider.notifier).updateSettings(
        current.copyWith(danmakuFontFamilyName: 'Default'),
      );
    } else {
      final controller = ref.read(fontSettingsControllerProvider.notifier);
      final current = ref.read(fontSettingsControllerProvider).value;
      if (current == null) return;
      await controller.updateSettings(current.copyWith(fontFamilyName: 'Default'));
    }
    if (mounted) setState(() => _status = i18n('font_default'));
  }

  Future<void> _download(FontModel font) async {
    if (_busyFontId.isNotEmpty) return;
    setState(() {
      _busyFontId = font.id;
      _status = '${i18n('font_downloading')} ${font.name}';
    });
    final ok = await FontDownloadManager.instance.downloadFontFamily(
      fontModel: font,
      onStateChanged: (state) {
        if (state.isDownloading && mounted) setState(() => _status = '${i18n('font_downloading')} ${font.name}');
      },
    );
    if (!mounted) return;
    setState(() {
      _busyFontId = '';
      _status = ok ? i18n('font_downloaded') : i18n('font_download_failed');
    });
    if (ok) await _refreshDownloaded();
  }

  Future<void> _delete(FontModel font) async {
    // Deleting the family in force would leave text falling back silently;
    // reset the mode's selection first.
    if (_activeId == font.id) await _resetFont();
    await FontDownloadManager.instance.deleteFontFamily(font, (_) {});
    if (!mounted) return;
    setState(() {
      _downloaded.remove(font.id);
      _status = i18n('delete_success');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final activeId = _activeId;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 出厂默认：one row resets the mode's selection to the bundled font.
          TvSettingsGroupTitle(title: _danmakuMode ? i18n('font_danmaku_group') : i18n('font_family')),
          TvSettingsCard(
            children: [
              TvSettingsRow(
                title: i18n('font_default'),
                subtitle: activeId == 'Default' ? i18n('font_default_subtitle') : '${i18n('font_family')}: ${_fontNameOf(activeId)}',
                icon: Icons.text_fields_rounded,
                trailingBuilder: (context, focused) =>
                    tvSettingsValueLabel(context, focused, activeId == 'Default' ? i18n('font_in_use') : i18n('ui_use')),
                onSelect: () => _resetFont(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 云字体
          TvSettingsGroupTitle(title: i18n('cloud_font_group')),
          for (final font in _fonts) ...[
            TvSettingsCard(
              children: [
                if (_downloaded.contains(font.id))
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    child: Text(
                      i18n('font_preview_sample'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: font.id,
                        fontSize: 22.sp,
                        color: theme.primaryTextColor,
                      ),
                    ),
                  ),
                TvSettingsRow(
                  title: font.name,
                  subtitle: font.desc,
                  icon: Icons.font_download_outlined,
                  trailingBuilder: (context, focused) {
                    final String label = _busyFontId == font.id
                        ? i18n('font_downloading')
                        : activeId == font.id
                        ? i18n('font_in_use')
                        : _downloaded.contains(font.id)
                        ? i18n('font_downloaded')
                        : i18n('download');
                    return tvSettingsValueLabel(context, focused, label);
                  },
                  onSelect: _busyFontId.isNotEmpty
                      ? null
                      : () => _downloaded.contains(font.id) ? _activate(font) : _downloadThenActivate(font),
                ),
                if (_downloaded.contains(font.id) && activeId != font.id)
                  TvSettingsRow(
                    title: '${font.name} · ${i18n('delete')}',
                    icon: Icons.delete_outline_rounded,
                    trailingBuilder: (context, focused) => tvSettingsValueLabel(context, focused, i18n('delete')),
                    onSelect: () => _delete(font),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
          if (_status.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 4.h),
              child: Text(_status, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
            ),
        ],
      ),
    );
  }

  String _fontNameOf(String id) {
    for (final font in _fonts) {
      if (font.id == id) return font.name;
    }
    return id == 'Default' ? i18n('font_default') : id;
  }

  /// Download first, then activate — the common path for a cloud font the
  /// user picked from a cold page.
  Future<void> _downloadThenActivate(FontModel font) async {
    await _download(font);
    if (_downloaded.contains(font.id)) await _activate(font);
  }
}
