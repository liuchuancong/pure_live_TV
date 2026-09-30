import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/services/music_list_reveal.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_controller.dart';

/// One synced playlist's track table (bmsc's fav detail): an in-list search
/// filter and play all.
class MusicFavDetailPage extends ConsumerStatefulWidget {
  const MusicFavDetailPage({super.key, required this.folder});

  final FavFolder folder;

  @override
  ConsumerState<MusicFavDetailPage> createState() => _MusicFavDetailPageState();
}

class _MusicFavDetailPageState extends ConsumerState<MusicFavDetailPage> {
  final TextEditingController _filter = TextEditingController();
  final MusicListReveal _reveal = MusicListReveal();

  /// land on every selected track (the bilibili-music checkbox table).
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectMode() {
    setState(() {
      _selectedIds.clear();
      _selectMode = !_selectMode;
    });
  }

  void _toggleSelected(String id) {
    setState(() => _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id));
  }

  void _selectAll(List<MusicTrack> tracks) {
    setState(() {
      if (_selectedIds.length >= tracks.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(tracks.map((t) => t.id));
      }
    });
  }

  List<MusicTrack> _selectedTracks(List<MusicTrack> tracks) =>
      tracks.where((t) => _selectedIds.contains(t.id)).toList();

  void _batchLike(List<MusicTrack> selected) {
    final library = ref.read(musicLibraryControllerProvider);
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    var added = 0;
    for (final track in selected) {
      if (!library.isSongLiked(track.id)) {
        libraryController.toggleLikeSong(track);
        added++;
      }
    }
    ToastUtil.show(i18n('music_batch_liked', args: {'count': '$added'}));
  }

  Future<void> _batchAddToPlaylist(List<MusicTrack> selected) async {
    if (selected.isEmpty) {
      ToastUtil.show(i18n('music_batch_none_selected'));
      return;
    }
    final playlistId = await showPlaylistPicker(context, ref);
    if (playlistId == null || !mounted) return;
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    for (final track in selected) {
      libraryController.addTrackToPlaylist(playlistId, track);
    }
    ToastUtil.show(i18n('music_batch_added', args: {'count': '${selected.length}'}));
    setState(() => _selectedIds.clear());
  }

  @override
  void dispose() {
    _reveal.dispose();
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final sync = ref.watch(musicPlaylistSyncControllerProvider);
    final tvTheme = context.tvTheme;
    final keyword = _filter.text.trim().toLowerCase();
    final sources = sync.folderTracks[folder.id] ?? const <MusicArchive>[];
    final tracks = <MusicTrack>[
      for (final archive in sources)
        if (keyword.isEmpty ||
            archive.title.toLowerCase().contains(keyword) ||
            archive.upName.toLowerCase().contains(keyword))
          ...archive.tracks,
    ];

    return TvPageScaffold(
      title: folder.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.ts(context), 12.ts(context), 24.ts(context), 8.ts(context)),
            child: Row(
              children: [
                Text(
                  '${tracks.length} ${i18n('music_tracks_unit')}',
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                ),
                SizedBox(width: 16.ts(context)),
                if (_selectMode) ...[
                  TvButton(
                    title: _selectedIds.length >= tracks.length && tracks.isNotEmpty
                        ? i18n('music_batch_select_none')
                        : i18n('music_batch_select_all'),
                    icon: Icon(
                      _selectedIds.length >= tracks.length && tracks.isNotEmpty
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      size: 24.ts(context),
                    ),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: tracks.isEmpty ? null : () => _selectAll(tracks),
                  ),
                  SizedBox(width: 12.ts(context)),
                  Text(
                    i18n('music_batch_selected_count', args: {'count': '${_selectedIds.length}'}),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.focusColor),
                  ),
                  const Spacer(),
                  TvButton(
                    title: i18n('music_like'),
                    icon: Icon(Icons.favorite_rounded, size: 24.ts(context)),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: _selectedIds.isEmpty ? null : () => _batchLike(_selectedTracks(tracks)),
                  ),
                  SizedBox(width: 12.ts(context)),
                  TvButton(
                    title: i18n('music_add_to_playlist'),
                    icon: Icon(Icons.playlist_add_rounded, size: 24.ts(context)),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: _selectedIds.isEmpty ? null : () => unawaited(_batchAddToPlaylist(_selectedTracks(tracks))),
                  ),
                  SizedBox(width: 12.ts(context)),
                  TvButton(title: i18n('cancel'), size: TvButtonSize.mini, isSecondary: true, onTap: _toggleSelectMode),
                ] else ...[
                  SizedBox(
                    width: 320.ts(context),
                    child: TvInputField(
                      controller: _filter,
                      hint: i18n('music_playlist_filter_hint'),
                      height: 56.ts(context),
                      maxLines: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Spacer(),
                  TvButton(
                    title: i18n('music_batch_select'),
                    icon: Icon(Icons.checklist_rounded, size: 24.ts(context)),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: tracks.isEmpty ? null : _toggleSelectMode,
                  ),
                  SizedBox(width: 12.ts(context)),
                  TvButton(
                    title: i18n('music_play_all'),
                    icon: Icon(Icons.play_circle_fill_rounded, size: 26.ts(context)),
                    size: TvButtonSize.mini,
                    onTap: tracks.isEmpty ? null : () => _playAll(context, ref, tracks),
                  ),
                  SizedBox(width: 12.ts(context)),
                  TvButton(
                    title: i18n('music_sync_this'),
                    icon: Icon(Icons.sync_rounded, size: 24.ts(context)),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: () => ref.read(musicPlaylistSyncControllerProvider.notifier).syncFolder(folder.id),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: tracks.isEmpty
                ? AppStatusView(type: AppStatusType.empty, title: i18n('music_sync_not_yet'), subtitle: '')
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(24.ts(context), 4.ts(context), 24.ts(context), 24.ts(context)),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      _reveal.bindRow(track, context);
                      final trackId = track.id;
                      return _TrackRow(
                        track: track,
                        index: index,
                        focusNode: _reveal.nodeFor(track),
                        selectMode: _selectMode,
                        selected: _selectedIds.contains(trackId),
                        onPlay: () => _selectMode ? _toggleSelected(trackId) : _playFrom(context, ref, tracks, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _playAll(BuildContext context, WidgetRef ref, List<MusicTrack> tracks) async {
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks);
    await const MusicPlayerRoute().push(context);
    if (!mounted) return;
    _reveal.reveal(this.context, tracks, ref.read(musicPlayerControllerProvider).current);
  }

  Future<void> _playFrom(BuildContext context, WidgetRef ref, List<MusicTrack> tracks, int index) async {
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: index);
    await const MusicPlayerRoute().push(context);
    if (!mounted) return;
    _reveal.reveal(this.context, tracks, ref.read(musicPlayerControllerProvider).current);
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.index,
    required this.onPlay,
    this.selectMode = false,
    this.selected = false,
    this.focusNode,
  });

  final MusicTrack track;
  final int index;
  final VoidCallback onPlay;

  /// Batch mode: the leading slot becomes a checkbox and taps toggle
  /// membership instead of playing.
  final bool selectMode;
  final bool selected;

  /// The list's per-row node, for the return-from-player reveal.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    // No fixed height: the row is as tall as its two labels plus scaled
    // padding — the old fixed 72.ts(context) painted the yellow overflow stripe once
    // the enlarged font met the panel lift, exactly what the playlist track
    // rows fixed by sizing to their content.
    final double textScale = TvTextScale.factorOf(context);

    return TvFocusable(
      focusNode: focusNode,
      onTap: onPlay,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.only(bottom: 8.ts(context)),
        padding: EdgeInsets.symmetric(horizontal: 16.ts(context) * textScale, vertical: 12.ts(context) * textScale),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(14.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44.ts(context) * textScale,
              child: selectMode
                  ? Icon(
                      selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 30.ts(context),
                      color: selected ? accent : tvTheme.secondaryTextColor,
                    )
                  : Text(
                      '${index + 1}',
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                    ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                  ),
                  Text(
                    track.archive.upName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
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
