import 'package:pure_live/exports/exports.dart';

class FavOperateUtil {
  static void toggleRoomFollowDialog(BuildContext context, LiveRoom room) {
    final ctrl = FavoriteRoomController.to;
    final bool followed = ctrl.isFavorite(room);

    final title = followed ? i18n('unfollow') : i18n('ui_follow_confirmation');
    final message = followed ? '确定要取消关注主播“${room.nick}”吗？' : '确定要关注主播“${room.nick}”吗？';
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
    final message = followed ? '确定要取消关注“${area.areaName}”分区吗？' : '确定要关注“${area.areaName}”分区吗？';
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
      const TvSelectItem(title: '删除历史', value: 'delete', leading: Icon(Icons.delete_outline_rounded)),
    ];

    TvDialogUtils.showSelect<String>(
      context: context,
      title: '历史管理',
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
