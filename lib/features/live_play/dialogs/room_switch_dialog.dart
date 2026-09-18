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

class _RoomSwitchDialogState extends ConsumerState<RoomSwitchDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Followed rooms that are live now; a replay is not "is live".
  List<LiveRoom> _liveRooms() {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isLiveNow && room.effectiveLiveStatus != LiveStatus.replay && !room.hasSameIdentity(widget.current))
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
      cancelText: i18n('close'),
      onCancel: () => Navigator.of(context).pop(),
      child: SizedBox(
        height: 520.sp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TvTabBar, not the Material one: its tabs are d-pad focusable and
            // answer focus with the shared scale/ring/glow language, while a
            // Material TabBar only tints the *selected* label, so a focused
            // tab looked no different from an idle one on the remote.
            TvTabBar(
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
              onTabChange: (index) => setState(() => _tabController.animateTo(index)),
            ),
            SizedBox(height: 12.sp),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RoomList(rooms: live, emptyHint: i18n('no_followed_room_live')),
                  _RoomList(rooms: replay, emptyHint: i18n('no_followed_room_live')),
                  _RoomList(rooms: history, emptyHint: i18n('history_empty')),
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
  const _RoomList({required this.rooms, required this.emptyHint});

  final List<LiveRoom> rooms;
  final String emptyHint;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    if (rooms.isEmpty) {
      return Center(
        child: Text(emptyHint, style: AppTextStyles.t22W500.copyWith(color: tvTheme.secondaryTextColor)),
      );
    }

    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return DpadFocusable(
          autofocus: index == 0,
          onSelect: () => Navigator.of(context).pop(room),
          builder: (context, state, child) => PlayerRoomRow(room: room, selected: state.focused),
          child: const SizedBox.shrink(),
        );
      },
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
