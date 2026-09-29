import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// without it a new playlist is created. The controller refuses empty names.
Future<String?> showPlaylistNameDialog(BuildContext context, WidgetRef ref, {MusicUserPlaylist? playlist}) {
  final editing = playlist != null;
  final controller = TextEditingController(text: editing ? playlist.name : '');
  return TvDialogUtils.show<String>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n(editing ? 'music_edit_playlist' : 'music_create_playlist'),
      confirmText: i18n('ui_confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () {
        final libraryController = ref.read(musicLibraryControllerProvider.notifier);
        if (editing) {
          libraryController.renamePlaylist(playlist.id, controller.text);
          Navigator.of(context).pop(playlist.id);
        } else {
          final id = libraryController.createPlaylist(controller.text);
          Navigator.of(context).pop(id);
        }
      },
      child: TvInputField(controller: controller, hint: i18n('music_playlist_name_hint'), maxLines: 1),
    ),
  );
}

/// the spot. The liked row always exists, so the dialog always opens — with no
/// playlist yet it is the liked row plus creation.
Future<void> showAddToPlaylistDialog(BuildContext context, WidgetRef ref, MusicTrack track) {
  final library = ref.read(musicLibraryControllerProvider);
  final playlists = library.orderedPlaylists;

  final tvTheme = context.tvTheme;
  return TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n('music_add_to_playlist'),
      cancelText: i18n('cancel'),
      width: 640.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The liked playlist, the shelf's fixed head — picking it hearts the
          // song (adding to a playlist never un-hearts one that already is).
          TvFocusable(
            autofocus: true,
            onTap: () {
              Navigator.of(context).pop();
              final controller = ref.read(musicLibraryControllerProvider.notifier);
              if (!library.isSongLiked(track.id)) controller.toggleLikeSong(track);
            },
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              decoration: BoxDecoration(
                color: focused ? tvTheme.cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded, size: 26.sp, color: tvTheme.focusColor),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Text(
                      i18n('music_liked_playlist'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                    ),
                  ),
                  Text(
                    '${library.likedSongs.length}',
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
          for (final playlist in playlists)
            TvFocusable(
              autofocus: false,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(musicLibraryControllerProvider.notifier).addTrackToPlaylist(playlist.id, track);
              },
              builder: (context, focused, child) => AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                decoration: BoxDecoration(
                  color: focused ? tvTheme.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.sp),
                  border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
                ),
                child: Row(
                  children: [
                    Icon(Icons.queue_music_rounded, size: 26.sp, color: tvTheme.focusColor),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                      ),
                    ),
                    Text(
                      '${playlist.tracks.length}',
                      style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 8.sp),
          TvFocusable(
            onTap: () {
              Navigator.of(context).pop();
              showPlaylistNameDialog(context, ref);
            },
            builder: (context, focused, child) => AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              decoration: BoxDecoration(
                color: focused ? tvTheme.cardColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 26.sp, color: tvTheme.focusColor),
                  SizedBox(width: 12.sp),
                  Text(
                    i18n('music_create_playlist'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.focusColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Picks one local playlist (creating one on the fly counts). Returns the id,
/// or null when cancelled.
Future<String?> showPlaylistPicker(BuildContext context, WidgetRef ref) async {
  final playlists = ref.read(musicLibraryControllerProvider).orderedPlaylists;
  if (playlists.isEmpty) {
    return showPlaylistNameDialog(context, ref);
  }

  String? picked;
  await TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n('music_save_to_playlist'),
      cancelText: i18n('cancel'),
      width: 560.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, playlist) in playlists.indexed)
            TvDialogOptionTile(
              title: playlist.name,
              subtitle: '${playlist.tracks.length}',
              icon: Icon(Icons.queue_music_rounded, size: 26.sp),
              showCheck: false,
              autofocus: index == 0,
              onTap: () => Navigator.of(context).pop(playlist.id),
            ),
          TvDialogOptionTile(
            title: i18n('music_create_playlist'),
            icon: Icon(Icons.add_rounded, size: 26.sp),
            showCheck: false,
            onTap: () async {
              final id = await showPlaylistNameDialog(context, ref);
              if (context.mounted) Navigator.of(context).pop(id);
            },
          ),
        ],
      ),
    ),
  );
  return picked;
}
