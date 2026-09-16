import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/font_model/font_model.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';

/// Font family manager: download a font from the manifest, activate it or
/// remove it from the device.
class FontFamilyManagerSectionPage extends ConsumerStatefulWidget {
  const FontFamilyManagerSectionPage({super.key});

  @override
  ConsumerState<FontFamilyManagerSectionPage> createState() => FontFamilyManagerSectionPageState();
}

class FontFamilyManagerSectionPageState extends ConsumerState<FontFamilyManagerSectionPage> {
  final Set<String> _downloaded = {};
  String _status = '';
  String _busyFontId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDownloaded());
  }

  List<FontModel> get _fonts => ref.read(fontSettingsControllerProvider.notifier).fontList;

  Future<void> _refreshDownloaded() async {
    final manager = FontDownloadManager.instance;
    final downloaded = <String>{};
    for (final font in _fonts) {
      if (font.id.isEmpty) continue;
      if (await manager.checkFontDownloaded(font.id)) downloaded.add(font.id);
    }
    if (!mounted) return;
    setState(() {
      _downloaded
        ..clear()
        ..addAll(downloaded);
    });
  }

  Future<void> _activate(FontModel font) async {
    await ref.read(fontSettingsControllerProvider.notifier).activateFontFamily(font);
    if (mounted) setState(() => _status = '${i18n('font_family')}: ${font.name}');
  }

  Future<void> _resetFont() async {
    final controller = ref.read(fontSettingsControllerProvider.notifier);
    final current = ref.read(fontSettingsControllerProvider).value;
    if (current == null) return;
    await controller.updateSettings(current.copyWith(fontFamilyName: 'Default'));
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
    await FontDownloadManager.instance.deleteFontFamily(font, (_) {});
    if (!mounted) return;
    setState(() {
      _downloaded.remove(font.id);
      _status = i18n('delete_success');
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(fontSettingsControllerProvider);
    final activeId = asyncState.value?.fontFamilyName ?? 'Default';
    final theme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 出厂默认
          TvSettingsGroupTitle(title: i18n('factory_default_group')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('font_default'),
                subtitle: activeId == 'Default' ? i18n('logined') : null,
                icon: Icons.text_fields_rounded,
                options: [i18n('ui_use')],
                index: 0,
                onChanged: (_) => _resetFont(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // 云字体
          TvSettingsGroupTitle(title: i18n('cloud_font_group')),
          for (final font in _fonts) ...[
            TvSettingsCard(
              children: [
                TvSettingsOptionTile(
                  title: font.name,
                  subtitle: font.desc,
                  icon: Icons.font_download_outlined,
                  options: [i18n('ui_use')],
                  index: 0,
                  onChanged: (_) => _activate(font),
                ),
                if (!_downloaded.contains(font.id))
                  TvSettingsOptionTile(
                    title: '${font.name} · ${i18n('download')}',
                    icon: Icons.download_rounded,
                    options: [i18n('download')],
                    index: 0,
                    onChanged: _busyFontId.isEmpty ? (_) => _download(font) : null,
                  )
                else ...[
                  TvSettingsOptionTile(
                    title: '${font.name} · ${i18n('font_downloaded')}',
                    icon: Icons.check_circle_outline_rounded,
                    options: [i18n('font_downloaded')],
                    index: 0,
                    onChanged: (_) => _activate(font),
                  ),
                  TvSettingsOptionTile(
                    title: '${font.name} · ${i18n('delete')}',
                    icon: Icons.delete_outline_rounded,
                    options: [i18n('delete')],
                    index: 0,
                    onChanged: (_) => _delete(font),
                  ),
                ],
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
}
