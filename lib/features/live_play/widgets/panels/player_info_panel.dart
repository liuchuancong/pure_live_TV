import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_index_panel.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// 房间信息 — the room's read-only details plus the controls for the panel
/// itself: which edge it sits on, how far from that edge, and its text size.
///
/// The panel toggles it like every other panel; these three rows are adjusted
/// with Left/Right, in the same stepper style the danmaku settings use.
class PlayerInfoPanel extends StatefulWidget {
  const PlayerInfoPanel({super.key, required this.state, required this.args, this.onClose});

  final LivePlayState state;
  final LivePlayArgs args;
  final VoidCallback? onClose;

  @override
  State<PlayerInfoPanel> createState() => _PlayerInfoPanelState();
}

class _PlayerInfoPanelState extends State<PlayerInfoPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final room = widget.state.room;
    final List<({String label, String value, IconData icon, VoidCallback prev, VoidCallback next})> settings = [
      (
        label: i18nOr('ui_panel_side', '面板位置'),
        value: PlayerPanelLayout.isLeft ? i18nOr('ui_left', '左') : i18nOr('ui_right', '右'),
        icon: Icons.swap_horiz_rounded,
        prev: () => setState(PlayerPanelLayout.toggleSide),
        next: () => setState(PlayerPanelLayout.toggleSide),
      ),
      (
        label: i18nOr('ui_panel_distance', '左右距离'),
        value: '${PlayerPanelLayout.offset}',
        icon: Icons.settings_overscan_rounded,
        prev: () => setState(() => PlayerPanelLayout.stepOffset(forward: false)),
        next: () => setState(() => PlayerPanelLayout.stepOffset(forward: true)),
      ),
      (
        label: i18nOr('ui_panel_font_size', '面板字号'),
        value: PlayerPanelLayout.fontSizeLabel,
        icon: Icons.format_size_rounded,
        prev: () => setState(() => PlayerPanelLayout.stepFontSize(forward: false)),
        next: () => setState(() => PlayerPanelLayout.stepFontSize(forward: true)),
      ),
    ];

    final List<PlayerPanelRow> infoRows = <PlayerPanelRow>[
      for (final setting in settings)
        PlayerPanelRow(label: setting.label, value: setting.value, icon: setting.icon),
      PlayerPanelRow(label: i18nOr('ui_room', 'Room'), value: room?.title ?? '', icon: Icons.live_tv_rounded),
      PlayerPanelRow(label: i18nOr('ui_streamer', 'Streamer'), value: room?.nick ?? '', icon: Icons.person_outline_rounded),
      PlayerPanelRow(label: i18n('platform_display'), value: room?.platform ?? '', icon: Icons.apps_rounded),
      PlayerPanelRow(
        label: i18n('recorder_stage_quality'),
        value: widget.state.qualities.isEmpty
            ? '-'
            : widget.state.qualities[widget.state.qualityIndex.clamp(0, widget.state.qualities.length - 1)].quality,
        icon: Icons.high_quality_rounded,
      ),
      PlayerPanelRow(
        label: i18n('multiview_line_selector'),
        value: '${widget.state.lineIndex + 1}',
        icon: Icons.density_small_rounded,
      ),
    ];

    return PlayerIndexPanel(
      title: i18n('ui_room_info'),
      rows: infoRows,
      selectedIndex: _index.clamp(0, infoRows.length - 1),
      onSelectionChanged: (i) => setState(() => _index = i),
      onAdjustLeft: (i) {
        if (i < settings.length) settings[i].prev();
      },
      onAdjustRight: (i) {
        if (i < settings.length) settings[i].next();
      },
      // The read-only rows have nothing to run; only the settings rows react.
      onSelect: (i) {
        if (i < settings.length) settings[i].next();
      },
      onClose: widget.onClose ?? () {},
    );
  }
}
