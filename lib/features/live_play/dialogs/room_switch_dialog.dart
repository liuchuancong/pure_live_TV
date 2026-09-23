import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_room_row.dart';
import 'package:pure_live/services/settings/settings.dart';

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
  ///
  /// [includeCurrent] keeps the room being watched in the list, which is what the
  /// new session needs as its playlist: the room is hidden from the *offer* (you
  /// cannot switch to what is already playing) but it still belongs to the list
  /// the viewer picked from.
  List<LiveRoom> _liveRooms({bool includeCurrent = false}) {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isLiveNow &&
            room.effectiveLiveStatus != LiveStatus.replay &&
            (includeCurrent || !room.hasSameIdentity(widget.current)))
          room,
    ];
  }

  /// Followed rooms that are replaying or recorded, matching the mobile page's
  /// replay tab (`effectiveLiveStatus == LiveStatus.replay`).
  List<LiveRoom> _replayRooms({bool includeCurrent = false}) {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isRecord || room.effectiveLiveStatus == LiveStatus.replay)
          if (includeCurrent || !room.hasSameIdentity(widget.current)) room,
    ];
  }

  List<LiveRoom> _historyRooms({bool includeCurrent = false}) {
    final rooms = SettingsService.to.historyState.historyRooms;
    return [
      for (final room in rooms)
        if (includeCurrent || !room.hasSameIdentity(widget.current)) room,
    ];
  }

  List<List<LiveRoom>> get _tabs => <List<LiveRoom>>[_liveRooms(), _replayRooms(), _historyRooms()];

  /// [tabIndex] as the viewer sees it, but with the room being watched kept in,
  /// in its original position. This is the playlist the new session gets.
  List<LiveRoom> _playlistOf(int tabIndex) {
    return switch (tabIndex) {
      0 => _liveRooms(includeCurrent: true),
      1 => _replayRooms(includeCurrent: true),
      _ => _historyRooms(includeCurrent: true),
    };
  }

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
  /// The whole tab travels with the room: the player takes it as the playlist, so
  /// a room picked from the followed list switches within the followed list rather
  /// than falling back to watch history.
  void _pick(int rowIndex) {
    final List<LiveRoom> visible = _tabs[_tabIndex];
    Navigator.of(context).pop(
      RoomSwitchSelection(room: visible[rowIndex], rooms: _playlistOf(_tabIndex)),
    );
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
    final double rowExtent = (66 * PlayerPanelLayout.fontSize).sp;
    final double target = (index * rowExtent) - 120;
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
      width: 1080.sp,
      cancelText: i18n('close'),
      onCancel: _close,
      // The dialog's only focusable node is the key handler below, so it opens
      // with the remote already on the tab strip.
      initialFocusNode: _focusNode,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: SizedBox(
          height: 640.sp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTabs(tabs),
              SizedBox(height: 16.sp),
              Expanded(child: _buildRooms(rooms, rowIndex)),
            ],
          ),
        ),
      ),
    );
  }

  /// The three category tabs, drawn as the app's own tab pills and highlighted
  /// from [_tabIndex].
  ///
  /// They are deliberately not focusable — a [GestureDetector] keeps them
  /// clickable with a mouse, while the remote reaches them through the index.
  Widget _buildTabs(List<List<LiveRoom>> tabs) {
    final List<String> titles = <String>[
      '${i18n('online_room_title')} (${tabs[0].length})',
      '${i18n('recording_room_title')} (${tabs[1].length})',
      '${i18n('watch_history')} (${tabs[2].length})',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < _tabCount; i++) ...<Widget>[
          if (i > 0) SizedBox(width: 12.sp),
          GestureDetector(
            onTap: () => _selectTab(i),
            child: TvButton(
              title: titles[i],
              size: TvButtonSize.medium,
              excludeFocus: true,
              // The accent marks the tab whose list is on screen; whether the
              // keyboard is on the strip or in the list is shown by the row
              // highlight below.
              selected: i == _tabIndex,
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
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
      itemCount: rooms.length,
      itemBuilder: (context, index) => PlayerRoomRow(
        room: rooms[index],
        selected: _zone == _Zone.rows && index == rowIndex,
      ),
    );
  }
}

/// A room picked in [showRoomSwitchDialog] together with the list it was picked
/// from, so the new session keeps that list as its playlist.
class RoomSwitchSelection {
  const RoomSwitchSelection({required this.room, required this.rooms});

  /// The room to play.
  final LiveRoom room;

  /// The tab the room was picked from, current room included.
  final List<LiveRoom> rooms;
}

/// Opens the room switch dialog and returns the chosen room with its list, if any.
Future<RoomSwitchSelection?> showRoomSwitchDialog(
  BuildContext context, {
  required LiveRoom current,
}) {
  return TvDialogUtils.show<RoomSwitchSelection>(
    context: context,
    builder: (dialogContext) => RoomSwitchDialog(current: current),
  );
}
