import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/music/api/music_provider.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/services/playlist_matcher.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// the netease `playlist?id=` form is detected), then every track triple is
/// searched on bilibili and the best-scoring archive joins the new local
/// playlist. One match per ~1.2s, the reference's rate.
Future<void> showImportPlaylistDialog(BuildContext context, WidgetRef ref) async {
  // ---- step 1: the platform
  final platform = await TvDialogUtils.show<String>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n('music_import_platform'),
      cancelText: i18n('cancel'),
      width: 560.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, option) in _platforms.indexed)
            TvDialogOptionTile(
              title: i18n(option.$2),
              subtitle: option.$3,
              icon: Icon(option.$1, size: 26.sp),
              showCheck: false,
              autofocus: index == 0,
              onTap: () => Navigator.of(context).pop(option.$4),
            ),
        ],
      ),
    ),
  );
  if (platform == null || !context.mounted) return;

  // ---- step 2: playlist name + id (a pasted netease link is auto-detected)
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final confirmed = await TvDialogUtils.show<bool>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n('music_import_playlist'),
      confirmText: i18n('ui_confirm'),
      cancelText: i18n('cancel'),
      onConfirm: () {
        var id = idController.text.trim();
        final link = RegExp(r'playlist\?.*?id=(\d+)').firstMatch(id);
        if (link != null) id = link.group(1)!;
        if (platform == 'netease' && !id.contains(':')) {
          idController.text = 'netease:$id';
        }
        Navigator.of(context).pop(true);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvInputField(controller: nameController, hint: i18n('music_playlist_name_hint'), maxLines: 1),
          SizedBox(height: 12.sp),
          TvInputField(controller: idController, hint: '${i18n('music_import_id_hint')} ($platform:...)', maxLines: 1),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  var playlistId = idController.text.trim();
  if (playlistId.startsWith('$platform:')) {
    playlistId = playlistId.split(':').last.trim();
  }
  if (playlistId.isEmpty) {
    ToastUtil.show(i18n('music_import_id_hint'));
    return;
  }

  // ---- step 3: fetch the triples, then search-match each one
  final triples = await switch (platform) {
    'netease' => MusicProvider.fetchNeteasePlaylistTracks(playlistId),
    'tencent' => MusicProvider.fetchTencentPlaylistTracks(playlistId),
    'kugou' => MusicProvider.fetchKuGouPlaylistTracks(playlistId),
    _ => Future<List<Map<String, dynamic>>?>.value(null),
  };
  if (!context.mounted) return;
  if (triples == null) {
    ToastUtil.show(i18n('music_import_failed'));
    return;
  }
  if (triples.isEmpty) {
    ToastUtil.show(i18n('music_import_not_found'));
    return;
  }

  final matched = <MusicArchive>[];
  var processed = 0;
  var pausedLabel = '';

  await TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: i18n('music_import_playlist'),
      width: 640.sp,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          // The loop runs once per dialog; the builder only paints progress.
          if (processed < triples.length) {
            Future(() async {
              for (; processed < triples.length; processed++) {
                final triple = triples[processed];
                final archive = await PlaylistMatcher.match(
                  triple['name']?.toString() ?? '',
                  triple['artist']?.toString() ?? '',
                  int.tryParse(triple['duration']?.toString() ?? '') ?? 0,
                );
                if (archive != null) matched.add(archive);
                if (!context.mounted) return;
                await Future.delayed(const Duration(milliseconds: 1200));
                setDialogState(() {});
              }
              setDialogState(() {});
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                pausedLabel.isNotEmpty
                    ? pausedLabel
                    : '${i18n('music_import_matching')} ${processed + 1 > triples.length ? triples.length : processed + 1}/${triples.length}',
                style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: context.tvTheme.primaryTextColor),
              ),
              SizedBox(height: 16.sp),
              LinearProgressIndicator(
                value: triples.isEmpty ? 0 : processed / triples.length,
                minHeight: 8.sp,
                color: context.tvTheme.focusColor,
              ),
              SizedBox(height: 16.sp),
              Text(
                '${i18n('music_import_matched')} ${matched.length}',
                style: AppTextStyles.t16.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.tvTheme.secondaryTextColor,
                ),
              ),
              SizedBox(height: 24.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TvButton(
                    title: processed >= triples.length ? i18n('ui_confirm') : i18n('music_import_stop'),
                    size: TvButtonSize.mini,
                    isSecondary: processed < triples.length,
                    onTap: () {
                      processed = triples.length;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
  if (!context.mounted) return;
  if (matched.isEmpty) {
    ToastUtil.show(i18n('music_import_no_result'));
    return;
  }

  // ---- step 4: the new local playlist carries every match's tracks
  final libraryController = ref.read(musicLibraryControllerProvider.notifier);
  final id = libraryController.createPlaylist(
    nameController.text.trim().isEmpty ? i18n('music_import_playlist') : nameController.text.trim(),
  );
  if (id == null) return;
  for (final archive in matched) {
    for (final track in archive.tracks) {
      libraryController.addTrackToPlaylist(id, track);
    }
  }
  ToastUtil.show(i18n('music_import_done'));
}

const List<(IconData, String, String, String)> _platforms = [
  (Icons.music_note_rounded, 'music_platform_netease', 'music_platform_netease_hint', 'netease'),
  (Icons.subscriptions_rounded, 'music_platform_tencent', 'music_platform_tencent_hint', 'tencent'),
  (Icons.headphones_rounded, 'music_platform_kugou', 'music_platform_kugou_hint', 'kugou'),
];
