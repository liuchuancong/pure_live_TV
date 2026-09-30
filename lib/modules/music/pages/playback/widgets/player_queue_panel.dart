import 'dart:async';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/music/widgets/music_song_menu.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/pages/playback/widgets/player_now_playing_view.dart' show stripTrackOrdinal;

/// One queue row, drawn in the live_play playlist's room-card language: the
/// cover thumb, the title with its album (multi-P) or UP beneath, the part
/// badge on the right — richer than a bare title, and the row every other
/// player list already speaks.
class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.track, required this.index, required this.isCurrent, required this.selected});

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final bool selected;

  /// Height of one row, margins included — the host list's `itemExtent` and
  /// its keep-in-view arithmetic read the same constant, so the highlight
  /// cannot drift off the rows it marks.
  static double get extent => 96.0;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final isMulti = track.archive.parts.length > 1;

    final Color foreground = selected ? Colors.white : Colors.white;
    final Color muted = selected ? Colors.white70 : Colors.white54;

    return Container(
      height: 88.0.ts(context),
      margin: EdgeInsets.symmetric(vertical: 4.ts(context)),
      padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
      decoration: BoxDecoration(
        color: selected
            ? accent
            : isCurrent
            ? accent.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.ts(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34.ts(context),
            child: isCurrent
                ? Icon(Icons.play_arrow_rounded, size: 32.ts(context), color: selected ? Colors.white : accent)
                : Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: muted),
                  ),
          ),
          SizedBox(width: 12.ts(context)),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.ts(context)),
            child: Container(
              width: 104.ts(context),
              height: 64.ts(context),
              color: Colors.white.withValues(alpha: 0.08),
              child: CachedNetworkImage(
                imageUrl: track.archive.cover,
                fit: BoxFit.cover,
                memCacheWidth: 240,
                fadeInDuration: Duration.zero,
                errorWidget: (_, _, _) => Icon(Icons.music_note_rounded, size: 26.ts(context), color: Colors.white24),
              ),
            ),
          ),
          SizedBox(width: 14.ts(context)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stripTrackOrdinal(track.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCurrent && !selected ? accent : foreground,
                  ),
                ),
                SizedBox(height: 4.ts(context)),
                Row(
                  children: [
                    Icon(Icons.album_rounded, size: 18.ts(context), color: muted),
                    SizedBox(width: 4.ts(context)),
                    Expanded(
                      child: Text(
                        isMulti ? track.archive.title : track.archive.upName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isMulti) ...[
            SizedBox(width: 8.ts(context)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.ts(context), vertical: 2.ts(context)),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.ts(context)),
              ),
              child: Text(
                'P${track.part.page}/${track.archive.parts.length}',
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: selected ? Colors.white : muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// model: one [Focus] owns every key (no per-row focusables to steal or lose
/// focus), the list walks a selected index with wrap, and opening scrolls to
/// — and selects — the row that is playing right now. OK jumps to the row,
/// Back / Left close the panel, and a row's long press (pointer) offers
class MusicQueuePanel extends ConsumerStatefulWidget {
  const MusicQueuePanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<MusicQueuePanel> createState() => MusicQueuePanelState();
}

class MusicQueuePanelState extends ConsumerState<MusicQueuePanel> {
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'music/queue-panel');

  /// The highlight the remote is walking. It starts on the playing row — the
  /// whole point of opening the list mid-playback.
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(musicPlayerControllerProvider).index.clamp(0, 1 << 30);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _scrollToSelection();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Keeps the highlighted row visible with the live panel's band arithmetic:
  /// the list only moves when the selection would leave view, and then just
  /// far enough to keep one row of context on that side.
  void _scrollToSelection() {
    if (!_scroll.hasClients) return;

    final position = _scroll.position;
    final viewport = position.viewportDimension;
    if (viewport <= 0) return;

    final rowExtent = _QueueRow.extent;
    final topPadding = 4.0.ts(context);
    final margin = rowExtent;
    final rowTop = topPadding + _selected * rowExtent;
    final rowBottom = rowTop + rowExtent;

    double? target;
    if (rowTop < position.pixels + margin) {
      target = rowTop - margin;
    } else if (rowBottom > position.pixels + viewport - margin) {
      target = rowBottom - viewport + margin;
    }
    if (target == null) return;

    _scroll.animateTo(
      target.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmClear() async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_queue_clear'),
        confirmText: i18n('ui_confirm'),
        cancelText: i18n('cancel'),
        onConfirm: () {
          Navigator.of(context).pop();
          unawaited(ref.read(musicPlayerControllerProvider.notifier).stop());
        },
        child: Text(
          i18n('music_queue_clear_confirm'),
          style: AppTextStyles.t20.copyWith(height: 1.5, color: context.tvTheme.primaryTextColor),
        ),
      ),
    );
  }

  /// entry from the queue.
  Future<void> _showRowMenu(int index) async {
    final track = ref.read(musicPlayerControllerProvider).queue[index];
    await showMusicSongMenu(
      context,
      ref,
      track: track,
      onDelete: () async {
        ref.read(musicPlayerControllerProvider.notifier).removeAt(index);
      },
    );
  }

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final queue = ref.read(musicPlayerControllerProvider).queue;
    final count = queue.length;
    final key = event.logicalKey;

    if (count == 0) {
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) widget.onClose();
      return KeyEventResult.handled;
    }

    if (_isConfirm(key)) {
      ref.read(musicPlayerControllerProvider.notifier).jumpTo(_selected);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selected = (_selected + (key == LogicalKeyboardKey.arrowDown ? 1 : -1) + count) % count;
      });
      _scrollToSelection();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final accent = context.tvTheme.focusColor;

    final queue = state.queue;
    final selected = queue.isEmpty ? 0 : _selected.clamp(0, queue.length - 1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.ts(context), 14.ts(context), 12.ts(context), 10.ts(context)),
            child: Row(
              children: [
                SizedBox(width: 6.ts(context)),
                Expanded(
                  child: Text(
                    '${i18n('music_tab_queue')}（${queue.length}）',
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.playlist_remove_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: queue.isEmpty ? null : _confirmClear,
                ),
                SizedBox(width: 6.ts(context)),
                TvIconButton(
                  icon: Icon(switch (state.mode) {
                    MusicPlayMode.sequence => Icons.playlist_play_rounded,
                    MusicPlayMode.loopOne => Icons.repeat_one_rounded,
                    MusicPlayMode.random => Icons.shuffle_rounded,
                  }),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: controller.cycleMode,
                ),
                SizedBox(width: 6.ts(context)),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: queue.isEmpty
                ? Center(
                    child: Text(
                      i18n('music_queue_empty'),
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
                    ),
                  )
                : Focus(
                    focusNode: _focusNode,
                    autofocus: true,
                    onKeyEvent: _onKeyEvent,
                    child: ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.only(left: 12.sp, right: 12.sp, top: 4.sp, bottom: 16.sp),
                      itemCount: queue.length,
                      // Exact row heights: the scroll arithmetic in
                      // [_scrollToSelection] is whole-row exact, so the last
                      // rows of a long queue stay reachable.
                      itemExtent: _QueueRow.extent,
                      itemBuilder: (context, index) {
                        final track = queue[index];
                        return GestureDetector(
                          onLongPress: () => _showRowMenu(index),
                          child: _QueueRow(
                            track: track,
                            index: index,
                            isCurrent: index == state.index,
                            selected: index == selected,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.ts(context), 0, 20.ts(context), 12.ts(context)),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                i18nOr('ui_panel_keys', '↑↓ 选择 · OK 确认 · ← 返回'),
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
