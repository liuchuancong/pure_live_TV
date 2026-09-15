import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_option_steps.dart';
import 'package:pure_live/features/live_play/widgets/panels/live_panel_shell.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Danmaku settings panel shown inside the player.
///
/// Shares one [DanmakuSettingsModel] with the settings page, so edits apply
/// immediately (the danmaku layer watches the same provider) and persist
/// across restarts.
class DanmakuSettingsPanel extends ConsumerWidget {
  const DanmakuSettingsPanel({super.key, this.autofocus = true});

  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(danmakuSettingsControllerProvider);
    final notifier = ref.read(danmakuSettingsControllerProvider.notifier);
    void update(DanmakuSettingsModel Function(DanmakuSettingsModel) change) =>
        notifier.updateSettings(change(settings));

    final enabled = settings.enableDanmakuDisplay && !settings.hideDanmaku;

    /// Master danmaku switch. Left, right and OK all toggle it.
    void toggleDanmaku() {
      final next = !enabled;
      update((s) => s.copyWith(enableDanmakuDisplay: next, hideDanmaku: !next));
    }

    return LivePanelShell(
      title: i18n('danmaku_settings'),
      hint: i18nOr('ui_danmaku_setting_hint', 'Up/Down to switch items, Left/Right to change the value'),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 8.sp),
        children: [
          LiveOptionRow(
            autofocus: autofocus,
            label: i18n('settings_danmaku_open'),
            icon: Icons.subtitles_rounded,
            value: enabled ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
            onSelect: toggleDanmaku,
            onPrev: toggleDanmaku,
            onNext: toggleDanmaku,
          ),
          LiveOptionRow(
            label: i18n('danmaku_font_size'),
            icon: Icons.format_size_rounded,
            value: DanmakuOptionSteps.number(settings.danmakuFontSize),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuFontSize: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.fontSize,
                  s.danmakuFontSize,
                  forward: false,
                ),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuFontSize: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.fontSize,
                  s.danmakuFontSize,
                  forward: true,
                ),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_speed'),
            icon: Icons.speed_rounded,
            value: DanmakuOptionSteps.number(settings.danmakuSpeed),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuSpeed: DanmakuOptionSteps.step(DanmakuOptionSteps.speed, s.danmakuSpeed, forward: false),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuSpeed: DanmakuOptionSteps.step(DanmakuOptionSteps.speed, s.danmakuSpeed, forward: true),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_opacity'),
            icon: Icons.opacity_rounded,
            value: DanmakuOptionSteps.percent(settings.danmakuOpacity),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuOpacity: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuOpacity, forward: false),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuOpacity: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuOpacity, forward: true),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_stroke'),
            icon: Icons.border_color_outlined,
            value: settings.enableDanmakuStroke ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
            onSelect: () => update((s) => s.copyWith(enableDanmakuStroke: !s.enableDanmakuStroke)),
            onPrev: () => update((s) => s.copyWith(enableDanmakuStroke: !s.enableDanmakuStroke)),
            onNext: () => update((s) => s.copyWith(enableDanmakuStroke: !s.enableDanmakuStroke)),
          ),
          LiveOptionRow(
            label: i18n('danmaku_stroke_width'),
            icon: Icons.line_weight_rounded,
            value: DanmakuOptionSteps.strokeLabel(settings.danmakuFontBorder),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuFontBorder: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.stroke,
                  s.danmakuFontBorder,
                  forward: false,
                ),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuFontBorder: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.stroke,
                  s.danmakuFontBorder,
                  forward: true,
                ),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_area'),
            icon: Icons.vertical_align_top_rounded,
            value: DanmakuOptionSteps.percent(settings.danmakuArea),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuArea: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuArea, forward: false),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuArea: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuArea, forward: true),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18nOr('danmaku_area_top', 'Top offset'),
            icon: Icons.vertical_align_center_rounded,
            value: DanmakuOptionSteps.number(settings.danmakuTopArea),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuTopArea: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.distance,
                  s.danmakuTopArea,
                  forward: false,
                ),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuTopArea: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.distance,
                  s.danmakuTopArea,
                  forward: true,
                ),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_area_bottom'),
            icon: Icons.vertical_align_bottom_rounded,
            value: DanmakuOptionSteps.percent(settings.danmakuBottomArea),
            onPrev: () => update(
              (s) => s.copyWith(
                danmakuBottomArea: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.ratio,
                  s.danmakuBottomArea,
                  forward: false,
                ),
              ),
            ),
            onNext: () => update(
              (s) => s.copyWith(
                danmakuBottomArea: DanmakuOptionSteps.step(
                  DanmakuOptionSteps.ratio,
                  s.danmakuBottomArea,
                  forward: true,
                ),
              ),
            ),
          ),
          LiveOptionRow(
            label: i18n('danmaku_no_emoji'),
            icon: Icons.emoji_emotions_outlined,
            value: settings.noEmojiMode ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
            onSelect: () => update((s) => s.copyWith(noEmojiMode: !s.noEmojiMode)),
            onPrev: () => update((s) => s.copyWith(noEmojiMode: !s.noEmojiMode)),
            onNext: () => update((s) => s.copyWith(noEmojiMode: !s.noEmojiMode)),
          ),
        ],
      ),
    );
  }
}
