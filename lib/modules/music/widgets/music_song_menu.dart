import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';

/// How the calling list removes this song — every list deletes differently
/// (最近播放 drops the record, 喜欢 unhooks the heart, a playlist unplugs the
/// entry), while everything else in the menu is shared.
enum MusicSongMenuRemove {
  recent,
  liked,
  playlist,
  none,
}

/// The unified song long-press menu, the QQ-music set: 下一首播放, 喜欢,
/// 加入歌单, plus the caller's own rows (置顶 / 清除默认歌词 / 删除).
///
/// 下一首播放 (the play-order adjustment — queue the song behind the playing
/// one) only makes sense for a song that is NOT the one playing now, so it
/// hides for the current track. [onDelete] adds a plain 删除 row for callers
/// whose list owns its own removal (the playing queue drops the entry).
Future<void> showMusicSongMenu(
  BuildContext context,
  WidgetRef ref, {
  required MusicTrack track,
  MusicSongMenuRemove remove = MusicSongMenuRemove.none,
  String? playlistId,
  int? playlistIndex,
  Future<void> Function()? onPin,
  String? removeLabelKey,
  Future<void> Function()? onDelete,
}) async {
  final controller = ref.read(musicPlayerControllerProvider.notifier);
  final libraryController = ref.read(musicLibraryControllerProvider.notifier);
  final isLiked = ref.read(musicLibraryControllerProvider).isSongLiked(track.id);
  final hasDefaultLyric = MusicLyricService.instance.manualLyric(track.title) != null;
  final isCurrent = ref.read(musicPlayerControllerProvider).current?.id == track.id;

  await TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: track.title,
      cancelText: i18n('cancel'),
      width: 560.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isCurrent)
            _menuTile(
              context,
              Icons.low_priority_rounded,
              i18n('music_play_next'),
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(controller.playNext(track));
              },
            ),
          _menuTile(
            context,
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            i18n(isLiked ? 'music_song_unliked_menu' : 'music_song_like_menu'),
            autofocus: isCurrent,
            onTap: () {
              Navigator.of(context).pop();
              libraryController.toggleLikeSong(track);
            },
          ),
          _menuTile(
            context,
            Icons.playlist_add_rounded,
            i18n('music_add_to_playlist'),
            onTap: () {
              // Closes this menu first — the picker opens over the page.
              Navigator.of(context).pop();
              showAddToPlaylistDialog(context, ref, track);
            },
          ),
          if (onPin != null)
            _menuTile(
              context,
              Icons.vertical_align_top_rounded,
              i18n('music_pin'),
              onTap: () {
                Navigator.of(context).pop();
                onPin();
                ToastUtil.show(i18n('music_pinned'));
              },
            ),
          if (hasDefaultLyric)
            _menuTile(
              context,
              Icons.lyrics_outlined,
              i18n('music_clear_default_lyric'),
              onTap: () {
                Navigator.of(context).pop();
                MusicLyricService.instance.clearManualLyric(track.title);
                ToastUtil.show(i18n('music_lyric_cleared'));
              },
            ),
          if (onDelete != null)
            _menuTile(
              context,
              Icons.delete_outline_rounded,
              i18n('music_removed_from_queue'),
              destructive: true,
              onTap: () {
                Navigator.of(context).pop();
                unawaited(onDelete());
              },
            ),
          if (remove != MusicSongMenuRemove.none)
            _menuTile(
              context,
              Icons.delete_outline_rounded,
              i18n(removeLabelKey ?? 'music_remove_from_playlist'),
              destructive: true,
              onTap: () {
                Navigator.of(context).pop();
                switch (remove) {
                  case MusicSongMenuRemove.recent:
                    libraryController.removeRecent(track.archive.bvid);
                    ToastUtil.show(i18n('music_removed_from_recent'));
                  case MusicSongMenuRemove.liked:
                    libraryController.removeLikedSong(track.id);
                    ToastUtil.show(i18n('music_song_unliked'));
                  case MusicSongMenuRemove.playlist:
                    libraryController.removeTrackFromPlaylist(playlistId ?? '', track.id);
                    ToastUtil.show(i18n('music_removed_from_playlist'));
                  case MusicSongMenuRemove.none:
                    break;
                }
              },
            ),
        ],
      ),
    ),
  );
}

Widget _menuTile(
  BuildContext context,
  IconData icon,
  String label, {
  required VoidCallback onTap,
  bool autofocus = false,
  bool destructive = false,
}) {
  final color = destructive ? Colors.redAccent : context.tvTheme.focusColor;
  return TvDialogOptionTile(
    title: label,
    icon: Icon(icon, size: 26.sp, color: color),
    showCheck: false,
    autofocus: autofocus,
    onTap: onTap,
  );
}
