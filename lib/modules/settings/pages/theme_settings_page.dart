import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/tv_dialog/tv_dialog.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_menu_dialog.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pure_live/common/style/app_text_styles.dart';
import 'package:pure_live/common/widgets/app_status_view.dart';
import 'package:pure_live/modules/settings/pages/page_settings.dart';
import 'package:pure_live/modules/settings/pages/font_settings_page.dart';
import 'package:pure_live/modules/settings/pages/font_family_manager_page.dart';
import 'package:pure_live/modules/settings/pages/loading_style_settings_page.dart';

class ThemeSettingsPage extends GetView<SettingsService> {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, String> themeModeMap = {
      for (var name in AppConsts.themeModes.keys) name: i18n(AppConsts.themeModeI18n[name]!),
    };

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("theme_customization"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/theme_customization',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("theme_customization")),
                  context.buildModernCard([
                    Obx(
                      () => context.buildMenuTile<String>(
                        icon: Remix.moon_clear_line,
                        title: i18n("change_theme_mode"),
                        subtitle: i18n("change_theme_mode_subtitle"),
                        value: SettingsService.to.theme.themeModeName.v,
                        valueMap: themeModeMap,
                        onChanged: (String newValue) {
                          SettingsService.to.theme.changeThemeMode(newValue);
                        },
                        onTap: () async => showThemeModeSelectorDialog(themeModeMap),
                      ),
                    ),
                    context.buildTile(
                      icon: Remix.palette_line,
                      title: i18n("change_theme_color"),
                      subtitle: i18n("change_theme_color_subtitle"),
                      onTap: colorPickerDialog,
                      trailing: Obx(
                        () => ColorIndicator(
                          width: 28,
                          height: 28,
                          borderRadius: 6,
                          color: HexColor(SettingsService.to.theme.themeColorSwitch.v),
                          onSelectFocus: false,
                        ),
                      ),
                    ),
                    context.buildSwitchTile(
                      title: i18n("enable_dynamic_color"),
                      subtitle: i18n("enable_dynamic_color_subtitle"),
                      value: SettingsService.to.theme.enableDynamicTheme,
                      icon: Remix.magic_line,
                    ),
                    Obx(
                      () => context.buildTile(
                        iconWidget: SizedBox(
                          key: ValueKey(SettingsService.to.theme.loadingStyle.v),
                          width: 24,
                          child: AppStatusView(
                            type: AppStatusType.loading,
                            title: i18n('refresh_loading'),
                            subtitle: '',
                            isMini: true,
                          ),
                        ),
                        title: i18n("change_loading_style"),
                        subtitle: i18n("change_loading_style_subtitle"),
                        onTap: () async => Get.to(() => const LoadingStyleSettingsPage()),
                        trailing: Obx(() {
                          final String currentKey = SettingsService.to.theme.loadingStyle.v;
                          final bool isZh = Get.locale?.languageCode == 'zh';
                          final Map<String, String> currentItem = AppConsts.allStyles.firstWhere(
                            (item) => item['key'] == currentKey,
                            orElse: () => {'key': 'default', 'nameEn': 'Default Ring', 'nameZh': '默认圆环'},
                          );
                          final String displayName = isZh ? currentItem['nameZh']! : currentItem['nameEn']!;

                          return Text(displayName, style: AppTextStyles.t13.copyWith(color: theme.colorScheme.outline));
                        }),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("grid_spacing_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.arrow_left_right_line,
                      title: i18n("cross_axis_spacing"),
                      subtitle: i18n("cross_axis_spacing_subtitle"),
                      onTap: showCrossAxisSpacingDialog,
                    ),
                    context.buildTile(
                      icon: Remix.arrow_up_down_line,
                      title: i18n("main_axis_spacing"),
                      subtitle: i18n("main_axis_spacing_subtitle"),
                      onTap: showMainAxisSpacingDialog,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("page_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.pages_line,
                      title: i18n('page_settings'),
                      subtitle: i18n('page_settings_subtitle'),
                      onTap: () async => Get.to(() => const PageSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("localization_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.global_line,
                      title: i18n("change_language"),
                      subtitle: i18n("change_language_subtitle"),
                      onTap: showLanguageSelecterDialog,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("font_family_settings")),
                  context.buildModernCard([
                    Obx(
                      () => context.buildTile(
                        icon: Remix.font_color,
                        title: i18n("change_font_family"),
                        subtitle: "${i18n("current_font_prefix")}: ${SettingsService.to.font.fontFamilyName.v}",
                        onTap: () async => Get.to(() => const FontFamilyManagerPage()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("text_size_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.font_size,
                      title: i18n("font_settings_title"),
                      subtitle: i18n("font_settings_desc"),
                      onTap: () async => Get.to(() => const FontSettingsPage()),
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => context.buildSliderTile(
                        context,
                        icon: Remix.text_spacing,
                        title: i18n("text_size_title"),
                        value: SettingsService.to.font.textScaleFactor.v,
                        min: 0.5,
                        max: 2.0,
                        displayValue: SettingsService.to.font.textScaleFactor.v.toStringAsFixed(2),
                        onChanged: (val) {
                          SettingsService.to.font.textScaleFactor.v = val;
                        },
                        step: 0.05,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(i18n("text_size_preview"), style: TextStyle(color: theme.colorScheme.outline)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showThemeModeSelectorDialog(Map<String, String> themeModeMap) async {
    final List<TvMenuItem<String>> menuItems = themeModeMap.entries.map((e) {
      return TvMenuItem<String>(title: e.value, value: e.key);
    }).toList();

    final selected = await Get.dialog<String>(
      TvMenuDialog<String>(
        title: i18n('change_theme_mode'),
        items: menuItems,
        selectedValue: SettingsService.to.theme.themeModeName.v,
      ),
    );

    if (selected != null) {
      SettingsService.to.theme.changeThemeMode(selected);
    }
  }

  Future<bool> colorPickerDialog() async {
    final Map<String, String> colorOptions = {};
    AppConsts.colorsNameMap.forEach((key, value) {
      if (value is Color) {
        colorOptions[key] = value.hex;
      }
    });

    final List<TvMenuItem<String>> menuItems = AppConsts.colorsNameMap.entries.map((e) {
      final Color color = e.value is Color ? e.value : Colors.transparent;
      return TvMenuItem<String>(
        title: e.key,
        value: color.hex,
        leading: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
      );
    }).toList();

    final selectedHex = await Get.dialog<String>(
      TvMenuDialog<String>(
        title: i18n("theme_color"),
        items: menuItems,
        selectedValue: SettingsService.to.theme.themeColorSwitch.v,
      ),
    );

    if (selectedHex != null) {
      SettingsService.to.theme.themeColorSwitch.v = selectedHex;
      final themeColor = HexColor(selectedHex);
      final lightTheme = MyTheme(primaryColor: themeColor).lightThemeData;
      final darkTheme = MyTheme(primaryColor: themeColor).darkThemeData;
      Get.changeTheme(lightTheme);
      Get.changeTheme(darkTheme);
      return true;
    }
    return false;
  }

  void showLanguageSelecterDialog() async {
    final List<TvMenuItem<String>> menuItems = AppConsts.languages.keys.map((name) {
      return TvMenuItem<String>(title: name, value: name);
    }).toList();

    final selected = await Get.dialog<String>(
      TvMenuDialog<String>(
        title: i18n("change_language"),
        items: menuItems,
        selectedValue: SettingsService.to.theme.languageName.v,
      ),
    );

    if (selected != null) {
      SettingsService.to.theme.changeLanguage(selected);
    }
  }

  void showCrossAxisSpacingDialog() {
    showCustomSpacingDialog(
      title: i18n("cross_axis_spacing"),
      hintText: i18n("cross_axis_spacing_subtitle"),
      currentValue: SettingsService.to.theme.crossAxisSpacing.v,
      onSelected: (value) => SettingsService.to.theme.crossAxisSpacing.v = value,
    );
  }

  void showMainAxisSpacingDialog() {
    showCustomSpacingDialog(
      title: i18n("main_axis_spacing"),
      hintText: i18n("main_axis_spacing_subtitle"),
      currentValue: SettingsService.to.theme.mainAxisSpacing.v,
      onSelected: (value) => SettingsService.to.theme.mainAxisSpacing.v = value,
    );
  }

  void showCustomSpacingDialog({
    required String title,
    required String hintText,
    required double currentValue,
    required ValueChanged<double> onSelected,
  }) {
    final List<double> quickOptions = [0.0, 4.0, 6.0, 8.0, 12.0, 16.0];
    final textController = TextEditingController(text: currentValue.toStringAsFixed(0));
    double selectedValue = currentValue;

    Get.dialog(
      TvDialog(
        title: title,
        child: SizedBox(
          width: 500,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final theme = Theme.of(context);

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DpadRegion(
                    horizontalEdge: DpadEdgeBehavior.stop,
                    verticalEdge: DpadEdgeBehavior.stop,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickOptions.map((value) {
                        final isSelected = value == selectedValue;
                        return DpadFocusable(
                          effects: [
                            DpadScaleEffect(scale: 1.05),
                            DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ],
                          onSelect: () {
                            setDialogState(() {
                              selectedValue = value;
                              textController.text = value.toStringAsFixed(0);
                            });
                          },
                          builder: (c, s, ch) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: s.focused
                                  ? theme.colorScheme.primary.withOpacity(0.12)
                                  : (isSelected
                                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                                        : theme.colorScheme.surfaceContainerHigh),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: s.focused || isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              "${value.toInt()} px",
                              style: TextStyle(
                                fontWeight: isSelected || s.focused ? FontWeight.bold : FontWeight.normal,
                                color: isSelected || s.focused
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          child: const SizedBox.shrink(),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(hintText, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            setDialogState(() {
                              selectedValue = parsed;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DpadRegion(
                        horizontalEdge: DpadEdgeBehavior.stop,
                        verticalEdge: DpadEdgeBehavior.stop,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DpadFocusable(
                              effects: const [DpadScaleEffect(scale: 1.1)],
                              onSelect: () {
                                setDialogState(() {
                                  selectedValue = (double.tryParse(textController.text) ?? 0.0) + 1.0;
                                  textController.text = selectedValue.toStringAsFixed(0);
                                });
                              },
                              builder: (c, s, ch) => Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: s.focused
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Icon(
                                  Icons.arrow_drop_up,
                                  color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 2),
                            DpadFocusable(
                              effects: const [DpadScaleEffect(scale: 1.1)],
                              onSelect: () {
                                setDialogState(() {
                                  double current = double.tryParse(textController.text) ?? 0.0;
                                  selectedValue = current > 0.0 ? current - 1.0 : 0.0;
                                  textController.text = selectedValue.toStringAsFixed(0);
                                });
                              },
                              builder: (c, s, ch) => Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: s.focused
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                                ),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  DpadRegion(
                    horizontalEdge: DpadEdgeBehavior.stop,
                    verticalEdge: DpadEdgeBehavior.stop,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DpadFocusable(
                          effects: const [DpadScaleEffect(scale: 1.05)],
                          onSelect: () => Navigator.of(context).pop(),
                          builder: (c, s, ch) => TextButton(
                            onPressed: null,
                            child: Text(
                              i18n("cancel"),
                              style: TextStyle(
                                color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 16),
                        DpadFocusable(
                          effects: const [DpadScaleEffect(scale: 1.05)],
                          onSelect: () {
                            onSelected(selectedValue);
                            Navigator.of(context).pop();
                          },
                          builder: (c, s, ch) => ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: s.focused
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primaryContainer,
                              foregroundColor: s.focused
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onPrimaryContainer,
                            ),
                            onPressed: null,
                            child: Text(i18n("confirm")),
                          ),
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
