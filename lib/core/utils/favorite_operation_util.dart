import 'package:flutter/material.dart';
import 'package:pure_live/dialog/tv_dialog_utils.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/services/favorite_settings/favorite_room_controller.dart';

class FavOperateUtil {
  static void toggleRoomFollowDialog(BuildContext context, LiveRoom room) {
    final ctrl = FavoriteRoomController.to;
    final bool followed = ctrl.isFavorite(room);

    final title = followed ? '取消关注' : '关注提示';
    final message = followed ? '确定要取消关注主播“${room.nick}”吗？' : '确定要关注主播“${room.nick}”吗？';
    final confirmText = followed ? '取消关注' : '确定关注';

    TvDialogUtils.showConfirm(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: '取消',
      onConfirm: () {
        if (followed) {
          FavoriteRoomController.to.removeRoom(room);
        } else {
          FavoriteRoomController.to.addRoom(room);
        }
      },
    );
  }
}
