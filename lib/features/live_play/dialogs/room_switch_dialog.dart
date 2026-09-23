import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_room_row.dart';

/// Dialog that switches the current playback to another room.
///
/// Only rooms the device already knows are offered: the followed rooms that are
/// live now (or are replaying), and the recent watch history. Nothing is fetched
/// here, so the dialog opens instantly even on a slow connection.
///
/// The entries are the mobile app's small-screen room cards — avatar, title,
/// streamer, platform badge and audience — the same rows the player's playlist
/// panel uses, so both lists read alike.
///
/// Steering is by **selected index**, like the player's own control bar and side
/// panels: one [Focus] owns every key and moves a tab index or a row index, and
/// the widgets below only draw the state. Focus traversal is deliberately not
/// used — a tab change used to hand the keyboard to a row of the page that was
/// still on its way out, so the highlight and the list disagreed.
class RoomSwitchDialog extends StatefulWidget {
  const RoomSwitchDialog({super.key, required this.current});

  /// Room being played; it is removed from every list.
  final LiveRoom current;

  @override
  State<RoomSwitchDialog> createState() => _RoomSwitchDialogState();
}

/// Which side of the dialog the remote is steering.
enum _Zone { tabs, rows }

class _RoomSwitchDialogState extends State<RoomSwitchDialog> {
  static const int _tabCount = 3;

  /// Scale applied to the room rows: title, streamer, platform badge and
  /// audience all grow together so the list reads from a couch distance.
  ///
  /// If the avatar inside [PlayerRoomRow] does not follow this, its radius is
  /// hard-coded — pass a size in from there, or derive it from
  /// `MediaQuery.textScalerOf(context).scale(...)`.
  static const double _listTextScale = 1.35;

  /// Estimated row height used by [_revealRow]; roughly the pre-scale value
  /// (66) multiplied by the scale above, so the auto-scroll target matches
  /// the taller rows on screen.
  static const double _rowExtentBase = 90;

  final FocusNode _focusNode = FocusNode(debugLabel: 'room-switch');
  final ScrollController _scrollController = ScrollController();

  int _tabIndex = 0;
  int _rowIndex = 0;
  _Zone _zone = _Zone.tabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // =========================
  // data
  // =========================

  /// Followed rooms that are live now; a replay is not "is live".
  List<LiveRoom> _liveRooms() {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isLiveNow &&
            room.effectiveLiveStatus != LiveStatus.replay &&
            !room.hasSameIdentity(widget.current))
          room,
    ];
  }

  /// Followed rooms that are replaying or recorded, matching the mobile page's
  /// replay tab (`effectiveLiveStatus == LiveStatus.replay`).
  List<LiveRoom> _replayRooms() {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isRecord || room.effectiveLiveStatus == LiveStatus.replay)
          if (!room.hasSameIdentity(widget.current)) room,
    ];
  }

  List<LiveRoom> _historyRooms() {
    final rooms = SettingsService.to.historyState.historyRooms;
    return [
      for (final room in rooms)
        if (!room.hasSameIdentity(widget.current)) room,
    ];
  }

  List<List<LiveRoom>> get _tabs => <List<LiveRoom>>[_liveRooms(), _replayRooms(), _historyRooms()];

  // =========================
  // key handling
  // =========================

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }

    final int count = _tabs[_tabIndex].length;
    // A tab with nothing in it has no rows to steer: the keyboard belongs to the
    // strip whatever zone it was in a moment ago.
    final bool inRows = _zone == _Zone.rows && count > 0;

    if (_isConfirm(key)) {
      if (inRows) {
        _pick(_rowIndex.clamp(0, count - 1));
      } else if (count > 0) {
        setState(() => _zone = _Zone.rows);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      // Up at the first row leaves the list for the tabs; anywhere else it walks
      // the list, which is what the eye expects under a tab strip.
      if (inRows) {
        if (_rowIndex == 0) {
          setState(() => _zone = _Zone.tabs);
        } else {
          _selectRow(_rowIndex - 1);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      if (inRows) {
        _selectRow((_rowIndex + 1) % count);
      } else if (count > 0) {
        setState(() => _zone = _Zone.rows);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (inRows) {
        setState(() => _zone = _Zone.tabs);
      } else {
        _selectTab((_tabIndex - 1 + _tabCount) % _tabCount);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (!inRows) _selectTab((_tabIndex + 1) % _tabCount);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Closes the dialog with the picked row of the visible tab.
  ///
  /// Only the room travels back: switching rooms is not switching context, so the
  /// session keeps the playlist it was opened with.
  void _pick(int rowIndex) {
    Navigator.of(context).pop(_tabs[_tabIndex][rowIndex]);
  }

  /// Switches the shown list. The keyboard stays where it is — on the strip when
  /// the viewer is comparing categories, in the list when they are picking one.
  void _selectTab(int index) {
    setState(() {
      _tabIndex = index;
      _rowIndex = 0;
      // A tab with nothing in it has no row to walk: the keyboard stays on the
      // strip instead of pointing at an empty list.
      if (_tabs[index].isEmpty) _zone = _Zone.tabs;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _selectRow(int index) {
    setState(() => _rowIndex = index);
    _revealRow(index);
  }

  /// Keeps the highlighted row on screen while the user walks the list.
  void _revealRow(int index) {
    if (!_scrollController.hasClients) return;
    final double rowExtent = (_rowExtentBase * PlayerPanelLayout.fontSize).sp;
    final double target = (index * rowExtent) - 160;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _close() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  // =========================
  // build
  // =========================

  @override
  Widget build(BuildContext context) {
    final List<List<LiveRoom>> tabs = _tabs;
    final List<LiveRoom> rooms = tabs[_tabIndex];
    final int rowIndex = rooms.isEmpty ? 0 : _rowIndex.clamp(0, rooms.length - 1);

    return TvDialog(
      title: i18n('switch_live_room'),
      // Wide enough that the room rows read as full-width list entries instead
      // of a squeezed column.
      width: 1280.sp,
      // The dialog's only focusable node is the key handler below, so it opens
      // with the remote already on the tab strip.
      initialFocusNode: _focusNode,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: SizedBox(
          height: 900.sp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabs(tabs),
              SizedBox(height: 16.sp),
              Expanded(
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(_listTextScale)),
                  child: _buildRooms(rooms, rowIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The three category tabs, drawn as compact centered pills.
  ///
  /// They are deliberately not focusable — a [GestureDetector] keeps them
  /// clickable with a mouse, while the remote reaches them through the index.
  /// The selected pill carries the accent color; whether the keyboard is on
  /// the strip or in the list is shown by the row highlight below.
  Widget _buildTabs(List<List<LiveRoom>> tabs) {
    final List<String> titles = <String>[
      '${i18n('online_room_title')} (${tabs[0].length})',
      '${i18n('recording_room_title')} (${tabs[1].length})',
      '${i18n('watch_history')} (${tabs[2].length})',
    ];

    final Color accent = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < _tabCount; i++) ...<Widget>[
          if (i > 0) SizedBox(width: 12.sp),
          // Compact pill: fixed horizontal padding, sized to the label, no
          // Flexible/Expanded so the strip stays centered and narrow.
          GestureDetector(
            onTap: () => _selectTab(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(horizontal: 22.sp, vertical: 8.sp),
              decoration: BoxDecoration(
                color: i == _tabIndex ? accent.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(20.sp),
                border: Border.all(color: i == _tabIndex ? accent : Colors.white24, width: 1.5.sp),
              ),
              child: Text(
                titles[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.sp,
                  height: 1.2,
                  fontWeight: i == _tabIndex ? FontWeight.w600 : FontWeight.w400,
                  color: i == _tabIndex ? accent : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRooms(List<LiveRoom> rooms, int rowIndex) {
    if (rooms.isEmpty) {
      return Center(
        child: SizedBox(
          height: 360.sp,
          child: AppStatusView(
            type: AppStatusType.empty,
            title: '',
            subtitle: switch (_tabIndex) {
              0 || 1 => i18n('no_followed_room_live'),
              _ => i18n('history_empty'),
            },
            isMini: true,
            icon: Remix.tv_2_line,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 8.sp),
      itemCount: rooms.length,
      itemBuilder: (context, index) =>
          PlayerRoomRow(room: rooms[index], selected: _zone == _Zone.rows && index == rowIndex),
    );
  }
}

/// Opens the room switch dialog and returns the chosen room, if any.
Future<LiveRoom?> showRoomSwitchDialog(BuildContext context, {required LiveRoom current}) {
  return TvDialogUtils.show<LiveRoom>(
    context: context,
    builder: (dialogContext) => RoomSwitchDialog(current: current),
  );
}
