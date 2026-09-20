import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
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
/// panel uses, so both lists read alike. They are wrapped in [DpadFocusable]
/// because a modal dialog is steered with the remote's focus traversal, unlike
/// the player's own key-driven panels.
class RoomSwitchDialog extends ConsumerStatefulWidget {
  const RoomSwitchDialog({super.key, required this.current});

  /// Room being played; it is removed from every list.
  final LiveRoom current;

  @override
  ConsumerState<RoomSwitchDialog> createState() => _RoomSwitchDialogState();
}

class _RoomSwitchDialogState extends ConsumerState<RoomSwitchDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// First-row focus nodes, one per tab, so a tab change can hand the keyboard
  /// straight into the newly shown list.
  final List<FocusNode?> _firstRowNodes = List<FocusNode?>.filled(3, null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _firstRowNodes[0] = FocusNode(debugLabel: 'room-switch/tab0-first');
  }

  @override
  void dispose() {
    for (final node in _firstRowNodes) {
      node?.dispose();
    }
    _tabController.dispose();
    super.dispose();
  }

  /// Switches the shown list; the keyboard stays where it is.
  void _switchTab(int index) {
    // Focus inside the old page dies with the page's ExcludeFocus below —
    // claim the new list's first row so the keyboard never falls out of the
    // dialog for the d-pad layer to "restore" geometrically.
    final bool focusInsidePage =
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<_RoomList>() !=
        null;
    setState(() => _tabController.animateTo(index));
    if (focusInsidePage) _claimFirstRow(index);
  }

  /// Puts the keyboard on a tab's first row once its page has built —
  /// TabBarView materialises the destination page during the transition, so
  /// the claim retries across a few frames.
  void _claimFirstRow(int index) {
    if (_firstRowNodes[index] == null) {
      _firstRowNodes[index] = FocusNode(
        debugLabel: 'room-switch/tab$index-first',
      );
    }
    void claim(int attempts) {
      if (!mounted) return;
      final node = _firstRowNodes[index];
      final BuildContext? nodeContext = node?.context;
      if (node == null || nodeContext == null || !nodeContext.mounted) {
        if (attempts < 8) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => claim(attempts + 1),
          );
        }
        return;
      }
      DpadRegion.ofNode(node)?.noteFocus(node);
      node.requestFocus();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => claim(0));
  }

  /// OK on a tab: switch, then move the keyboard onto the new tab's first row.
  void _onTabChange(int index) {
    _switchTab(index);
    _claimFirstRow(index);
  }

  /// Only the shown page may hold or receive focus. TabBarView keeps the
  /// neighbouring pages mounted next to the viewport, and their rows otherwise
  /// stay in the focus tree: a Left off the tab bar let the d-pad's geometric
  /// search land on a row of an invisible page — the list showed one tab while
  /// the highlight sat on another.
  Widget _page(int index, Widget child) {
    return ExcludeFocus(excluding: _tabController.index != index, child: child);
  }

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

  @override
  Widget build(BuildContext context) {
    final live = _liveRooms();
    final replay = _replayRooms();
    final history = _historyRooms();

    return TvDialog(
      title: i18n('switch_live_room'),
      // Wide enough that the room rows read as full-width list entries instead
      // of a squeezed column.
      width: 1080.sp,
      cancelText: i18n('close'),
      onCancel: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 640.sp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TvTabBar, not the Material one: its tabs are d-pad focusable and
            // answer focus with the shared scale/ring/glow language, while a
            // Material TabBar only tints the *selected* label, so a focused
            // tab looked no different from an idle one on the remote.
            TvTabBar(
              // Content follows the focused tab: a focus move on the remote is
              // the intent here, so highlight and list can never disagree.
              switchOnFocus: true,
              // A focus move only switches the content; the keyboard stays on
              // the tabs so left/right keeps walking them (down enters the list).
              onTabFocused: _switchTab,
              tabs: [
                TvTabItemData(
                  id: 'live',
                  title: '${i18n('online_room_title')} (${live.length})',
                ),
                TvTabItemData(
                  id: 'replay',
                  title: '${i18n('recording_room_title')} (${replay.length})',
                ),
                TvTabItemData(
                  id: 'history',
                  title: '${i18n('watch_history')} (${history.length})',
                ),
              ],
              currentIndex: _tabController.index,
              onTabChange: _onTabChange,
            ),
            SizedBox(height: 12.sp),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _page(
                    0,
                    _RoomList(
                      rooms: live,
                      emptyHint: i18n('no_followed_room_live'),
                      autofocusFirst: true,
                      firstRowNode: _firstRowNodes[0],
                    ),
                  ),
                  _page(
                    1,
                    _RoomList(
                      rooms: replay,
                      emptyHint: i18n('no_followed_room_live'),
                      firstRowNode: _firstRowNodes[1],
                    ),
                  ),
                  _page(
                    2,
                    _RoomList(
                      rooms: history,
                      emptyHint: i18n('history_empty'),
                      firstRowNode: _firstRowNodes[2],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({
    required this.rooms,
    required this.emptyHint,
    this.autofocusFirst = false,
    this.firstRowNode,
  });

  final List<LiveRoom> rooms;
  final String emptyHint;

  /// Whether this list's first row should claim the dialog's opening focus —
  /// true only for the tab the dialog is actually showing.
  final bool autofocusFirst;

  /// Focus node of the first row, shared with the dialog so a tab change can
  /// focus it. May be null for a tab that has not been opened yet.
  final FocusNode? firstRowNode;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
        child: SizedBox(
          height: 360.sp,
          child: AppStatusView(
            type: AppStatusType.empty,
            title: '',
            subtitle: emptyHint,
            isMini: true,
            icon: Remix.tv_2_line,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return DpadFocusable(
          autofocus: autofocusFirst && index == 0,
          focusNode: index == 0 ? firstRowNode : null,
          onSelect: () => Navigator.of(context).pop(room),
          builder: (context, state, child) =>
              PlayerRoomRow(room: room, selected: state.focused),
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Opens the room switch dialog and returns the chosen room, if any.
Future<LiveRoom?> showRoomSwitchDialog(
  BuildContext context, {
  required LiveRoom current,
}) {
  return TvDialogUtils.show<LiveRoom>(
    context: context,
    builder: (dialogContext) => RoomSwitchDialog(current: current),
  );
}
