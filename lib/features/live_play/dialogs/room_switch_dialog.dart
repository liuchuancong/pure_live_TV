import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Dialog that switches the current playback to another room.
///
/// Only rooms the device already knows are offered: the followed rooms that are
/// currently live and the recent watch history. Nothing is fetched here, so the
/// dialog opens instantly even on a slow connection.
class RoomSwitchDialog extends ConsumerStatefulWidget {
  const RoomSwitchDialog({super.key, required this.current});

  /// Room being played; it is removed from both lists.
  final LiveRoom current;

  @override
  ConsumerState<RoomSwitchDialog> createState() => _RoomSwitchDialogState();
}

class _RoomSwitchDialogState extends ConsumerState<RoomSwitchDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<LiveRoom> _followedRooms() {
    final rooms = SettingsService.to.favState.favoriteRooms;
    return [
      for (final room in rooms)
        if (room.isLiveNow && !room.hasSameIdentity(widget.current)) room,
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
    final tvTheme = context.tvTheme;
    final followed = _followedRooms();
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
            TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: tvTheme.focusColor,
              unselectedLabelColor: tvTheme.secondaryTextColor,
              tabs: [
                Tab(text: '${i18n('online_room_title')} (${followed.length})'),
                Tab(text: '${i18n('watch_history')} (${history.length})'),
              ],
            ),
            SizedBox(height: 12.sp),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RoomList(rooms: followed, emptyHint: i18n('no_followed_room_live')),
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
        child: Text(emptyHint, style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 22.sp)),
      );
    }

    return ListView.separated(
      itemCount: rooms.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.sp),
      itemBuilder: (_, index) {
        final room = rooms[index];
        final title = room.title.trim().isNotEmpty ? room.title : i18n('untitled_room');
        final anchor = room.nick.trim();
        return TvButton(
          autofocus: index == 0,
          isSecondary: true,
          title: anchor.isEmpty ? title : '$title · $anchor',
          icon: Icon(room.isLiveNow ? Icons.sensors_rounded : Icons.history_rounded),
          iconPosition: TvIconPosition.left,
          onTap: () => Navigator.of(context).pop(room),
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
