import 'package:pure_live/exports/exports.dart';

class FavOperateUtil {
  /// Room menu opened by long-pressing a room card: follow state and tags.
  static void showRoomActionDialog(BuildContext context, LiveRoom room) {
    final followed = FavoriteRoomController.to.isFavorite(room);

    TvDialogUtils.showSelect<String>(
      context: context,
      title: room.nick.isEmpty ? room.title : room.nick,
      items: [
        TvSelectItem(
          title: followed ? i18n('unfollow') : i18n('ui_confirm_follow'),
          value: 'follow',
          leading: Icon(followed ? Icons.favorite_border_rounded : Icons.favorite_rounded),
        ),
        TvSelectItem(
          title: i18n('set_room_tags'),
          value: 'tags',
          leading: const Icon(Icons.sell_outlined),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case 'follow':
            if (followed) {
              FavoriteRoomController.to.removeRoom(room);
            } else {
              FavoriteRoomController.to.addRoom(room);
            }
          case 'tags':
            showRoomTagDialog(context, room);
        }
      },
    );
  }

  /// Lets the user pick the tags of [room]; the selection is saved on confirm.
  static Future<void> showRoomTagDialog(BuildContext context, LiveRoom room) async {
    final tags = SettingsService.to.tagState.tags;
    final selected = SettingsService.to.tag.getTagsForRoom(room).toSet();

    final result = await TvDialogUtils.showMultiSelect<String>(
      context: context,
      title: i18n('set_room_tags'),
      items: [for (final tag in tags) TvMultiSelectItem(title: tag.name, value: tag.id, subtitle: tag.description)],
      initialSelection: selected,
      emptyHint: i18n('no_tags_tip'),
    );

    if (result == null) return;
    // Read the controller at the call site instead of holding one across the
    // dialog: the tag store is an auto-disposed provider, so a notifier picked up
    // before the await is already disposed when the user confirms — using it
    // throws "Cannot use the Ref ... after it has been disposed".
    SettingsService.to.tag.setRoomTags(room, result.toList(growable: false));
  }

  static void toggleRoomFollowDialog(BuildContext context, LiveRoom room) {
    final ctrl = FavoriteRoomController.to;
    final bool followed = ctrl.isFavorite(room);

    final title = followed ? i18n('unfollow') : i18n('ui_follow_confirmation');
    final message = i18n(
      followed ? 'unfollow_room_confirm' : 'follow_room_confirm',
      args: {'name': room.nick},
    );
    final confirmText = followed ? i18n('unfollow') : i18n('ui_confirm_follow');

    TvDialogUtils.showConfirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: i18n('cancel'),
      onConfirm: () {
        if (followed) {
          FavoriteRoomController.to.removeRoom(room);
        } else {
          FavoriteRoomController.to.addRoom(room);
        }
      },
    );
  }

  static void toggleAreaFollowDialog(BuildContext context, LiveArea area) {
    final ctrl = FavoriteRoomController.to;
    final bool followed = ctrl.isFavoriteArea(area);

    final title = followed ? i18n('unfollow') : i18n('ui_follow_confirmation');
    final message = i18n(
      followed ? 'unfollow_area_confirm' : 'follow_area_confirm',
      args: {'name': area.areaName},
    );
    final confirmText = followed ? i18n('unfollow') : i18n('ui_confirm_follow');

    TvDialogUtils.showConfirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: i18n('cancel'),
      onConfirm: () {
        if (followed) {
          FavoriteRoomController.to.removeArea(area);
        } else {
          FavoriteRoomController.to.addArea(area);
        }
      },
    );
  }

  static void toggleHistoryDeleteDialog(BuildContext context, LiveRoom room) {
    final ctrl = FavoriteRoomController.to;
    final bool followed = ctrl.isFavorite(room);

    final List<TvSelectItem<String>> menuItems = [
      TvSelectItem(
        title: followed ? i18n('unfollow') : i18n('favorites_title'),
        value: 'follow',
        leading: Icon(followed ? Icons.favorite_border_rounded : Icons.favorite_rounded),
      ),
      TvSelectItem(
        title: i18n('delete_history'),
        value: 'delete',
        leading: const Icon(Icons.delete_outline_rounded),
      ),
    ];

    TvDialogUtils.showSelect<String>(
      context: context,
      title: i18n('history_manage'),
      items: menuItems,
      onSelected: (action) {
        if (action == 'follow') {
          if (followed) {
            FavoriteRoomController.to.removeRoom(room);
          } else {
            FavoriteRoomController.to.addRoom(room);
          }
        } else if (action == 'delete') {
          HistoryController.to.removeHistory(room);
        }
      },
    );
  }
}
