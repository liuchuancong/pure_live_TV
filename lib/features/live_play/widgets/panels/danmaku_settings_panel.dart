import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_option_steps.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_index_panel.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// danmaku settings, as an index panel like the reference player's settings panel:
/// Up/Down pick a row, Left/Right change its value, OK toggles a switch row.
///
/// Shares one [DanmakuSettingsModel] with the settings page, so edits apply
/// immediately (the danmaku layer watches the same provider) and persist across
/// restarts.
class DanmakuSettingsPanel extends ConsumerStatefulWidget {
  const DanmakuSettingsPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<DanmakuSettingsPanel> createState() => _DanmakuSettingsPanelState();
}

class _DanmakuSettingsPanelState extends ConsumerState<DanmakuSettingsPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(danmakuSettingsControllerProvider);
    final notifier = ref.read(danmakuSettingsControllerProvider.notifier);
    void update(DanmakuSettingsModel Function(DanmakuSettingsModel) change) =>
        notifier.updateSettings(change(settings));

    final bool enabled = settings.enableDanmakuDisplay && !settings.hideDanmaku;
    void toggleDanmaku() => update((s) => s.copyWith(enableDanmakuDisplay: !enabled, hideDanmaku: enabled));
    void toggleStroke() => update((s) => s.copyWith(enableDanmakuStroke: !s.enableDanmakuStroke));
    void toggleEmoji() => update((s) => s.copyWith(noEmojiMode: !s.noEmojiMode));

    // label / icon / value / Left / Right / OK — the reference's
    // SettingsItemWidget list, expressed as data so one index drives it.
    final rows = <({String label, IconData icon, String value, VoidCallback prev, VoidCallback next, VoidCallback? select})>[
      (
        label: i18n('settings_danmaku_open'),
        icon: Icons.subtitles_rounded,
        value: enabled ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        prev: toggleDanmaku,
        next: toggleDanmaku,
        select: toggleDanmaku,
      ),
      (
        label: i18n('danmaku_font_size'),
        icon: Icons.format_size_rounded,
        value: DanmakuOptionSteps.number(settings.danmakuFontSize),
        prev: () => update(
          (s) => s.copyWith(
            danmakuFontSize: DanmakuOptionSteps.step(DanmakuOptionSteps.fontSize, s.danmakuFontSize, forward: false),
          ),
        ),
        next: () => update(
          (s) => s.copyWith(
            danmakuFontSize: DanmakuOptionSteps.step(DanmakuOptionSteps.fontSize, s.danmakuFontSize, forward: true),
          ),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_speed'),
        icon: Icons.speed_rounded,
        value: DanmakuOptionSteps.speedLabel(settings.danmakuSpeed),
        prev: () => update(
          (s) => s.copyWith(danmakuSpeed: DanmakuOptionSteps.step(DanmakuOptionSteps.speed, s.danmakuSpeed, forward: false)),
        ),
        next: () => update(
          (s) => s.copyWith(danmakuSpeed: DanmakuOptionSteps.step(DanmakuOptionSteps.speed, s.danmakuSpeed, forward: true)),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_opacity'),
        icon: Icons.opacity_rounded,
        value: DanmakuOptionSteps.percent(settings.danmakuOpacity),
        prev: () => update(
          (s) => s.copyWith(
            danmakuOpacity: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuOpacity, forward: false),
          ),
        ),
        next: () => update(
          (s) => s.copyWith(
            danmakuOpacity: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuOpacity, forward: true),
          ),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_stroke'),
        icon: Icons.border_color_outlined,
        value: settings.enableDanmakuStroke ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        prev: toggleStroke,
        next: toggleStroke,
        select: toggleStroke,
      ),
      (
        label: i18n('danmaku_stroke_width'),
        icon: Icons.line_weight_rounded,
        value: DanmakuOptionSteps.pixelLabel(settings.danmakuFontBorder),
        prev: () => update(
          (s) => s.copyWith(
            danmakuFontBorder: DanmakuOptionSteps.step(DanmakuOptionSteps.stroke, s.danmakuFontBorder, forward: false),
          ),
        ),
        next: () => update(
          (s) => s.copyWith(
            danmakuFontBorder: DanmakuOptionSteps.step(DanmakuOptionSteps.stroke, s.danmakuFontBorder, forward: true),
          ),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_area'),
        icon: Icons.vertical_align_top_rounded,
        value: DanmakuOptionSteps.percent(settings.danmakuArea),
        prev: () => update(
          (s) => s.copyWith(danmakuArea: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuArea, forward: false)),
        ),
        next: () => update(
          (s) => s.copyWith(danmakuArea: DanmakuOptionSteps.step(DanmakuOptionSteps.ratio, s.danmakuArea, forward: true)),
        ),
        select: null,
      ),
      (
        label: i18nOr('danmaku_area_top', 'Top offset'),
        icon: Icons.vertical_align_center_rounded,
        value: DanmakuOptionSteps.pixelLabel(settings.danmakuTopArea),
        prev: () => update(
          (s) => s.copyWith(
            danmakuTopArea: DanmakuOptionSteps.step(DanmakuOptionSteps.distance, s.danmakuTopArea, forward: false),
          ),
        ),
        next: () => update(
          (s) => s.copyWith(
            danmakuTopArea: DanmakuOptionSteps.step(DanmakuOptionSteps.distance, s.danmakuTopArea, forward: true),
          ),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_area_bottom'),
        icon: Icons.vertical_align_bottom_rounded,
        value: DanmakuOptionSteps.pixelLabel(settings.danmakuBottomArea),
        prev: () => update(
          (s) => s.copyWith(
            danmakuBottomArea: DanmakuOptionSteps.step(
              DanmakuOptionSteps.distance,
              s.danmakuBottomArea,
              forward: false,
            ),
          ),
        ),
        next: () => update(
          (s) => s.copyWith(
            danmakuBottomArea: DanmakuOptionSteps.step(DanmakuOptionSteps.distance, s.danmakuBottomArea, forward: true),
          ),
        ),
        select: null,
      ),
      (
        label: i18n('danmaku_no_emoji'),
        icon: Icons.emoji_emotions_outlined,
        value: settings.noEmojiMode ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        prev: toggleEmoji,
        next: toggleEmoji,
        select: toggleEmoji,
      ),
      (
        label: i18nOr('ui_panel_side', '面板位置'),
        icon: Icons.swap_horiz_rounded,
        value: PlayerPanelLayout.isLeft ? i18nOr('ui_left', '左') : i18nOr('ui_right', '右'),
        prev: () => setState(PlayerPanelLayout.toggleSide),
        next: () => setState(PlayerPanelLayout.toggleSide),
        select: () => setState(PlayerPanelLayout.toggleSide),
      ),
      (
        label: i18nOr('ui_panel_distance', '左右距离'),
        icon: Icons.settings_overscan_rounded,
        value: '${PlayerPanelLayout.offset}',
        prev: () => setState(() => PlayerPanelLayout.stepOffset(forward: false)),
        next: () => setState(() => PlayerPanelLayout.stepOffset(forward: true)),
        select: null,
      ),
      (
        label: i18nOr('ui_panel_font_size', '面板字号'),
        icon: Icons.format_size_rounded,
        value: PlayerPanelLayout.fontSizeLabel,
        prev: () => setState(() => PlayerPanelLayout.stepFontSize(forward: false)),
        next: () => setState(() => PlayerPanelLayout.stepFontSize(forward: true)),
        select: null,
      ),
    ];

    return PlayerIndexPanel(
      title: i18n('danmaku_settings'),
      rows: <PlayerPanelRow>[
        for (final row in rows) PlayerPanelRow(label: row.label, value: row.value, icon: row.icon),
      ],
      selectedIndex: _index.clamp(0, rows.length - 1),
      onSelectionChanged: (i) => setState(() => _index = i),
      // A switch row toggles on OK; a stepper row has nothing to "open", so OK
      // nudges it forward once rather than doing nothing.
      onSelect: (i) => (rows[i].select ?? rows[i].next)(),
      onAdjustLeft: (i) => rows[i].prev(),
      onAdjustRight: (i) => rows[i].next(),
      onClose: widget.onClose ?? () {},
    );
  }
}
