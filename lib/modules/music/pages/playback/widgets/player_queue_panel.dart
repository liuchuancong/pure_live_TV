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
  const _QueueRow({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.selected,
    this.showCheck = false,
    this.checked = false,
  });

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final bool selected;

  /// Multi-select mode: the leading slot becomes a checkbox instead of the
  /// row number.
  final bool showCheck;
  final bool checked;

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
            child: showCheck
                ? Icon(
                    checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 30.ts(context),
                    color: checked ? accent : Colors.white38,
                  )
                : isCurrent
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

  /// Multi-select mode (the lx MultipleModeBar): OK ticks rows instead of
  /// jumping, and the header swaps to the batch actions.
  bool _multi = false;

  /// Checked rows, keyed by track id so a queue edit cannot strand a stale
  /// index.
  final Set<String> _checked = <String>{};

  /// The move-target step of the batch "move here" action: arrow keys aim the
  /// insertion marker, OK drops the checked block there.
  bool _moving = false;

  void _exitMulti() {
    setState(() {
      _multi = false;
      _moving = false;
      _checked.clear();
    });
  }

  /// The checked tracks still sitting in the queue, in queue order.
  List<MusicTrack> _checkedTracks(List<MusicTrack> queue) {
    return [for (final track in queue) if (_checked.contains(track.id)) track];
  }

  void _toggleAllChecked(List<MusicTrack> queue) {
    setState(() {
      if (_checked.length >= queue.length) {
        _checked.clear();
      } else {
        _checked
          ..clear()
          ..addAll(queue.map((t) => t.id));
      }
    });
  }

  void _applyMove() {
    final ids = Set<String>.from(_checked);
    setState(() {
      _moving = false;
      _checked.clear();
    });
    ref.read(musicPlayerControllerProvider.notifier).moveIds(ids, _selected);
  }

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

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selected = (_selected + (key == LogicalKeyboardKey.arrowDown ? 1 : -1) + count) % count;
      });
      _scrollToSelection();
      return KeyEventResult.handled;
    }

    if (_isConfirm(key)) {
      if (_moving) {
        _applyMove();
        return KeyEventResult.handled;
      }
      if (_multi) {
        setState(() {
          final id = queue[_selected].id;
          if (!_checked.remove(id)) _checked.add(id);
        });
        return KeyEventResult.handled;
      }
      ref.read(musicPlayerControllerProvider.notifier).jumpTo(_selected);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) {
      // The remote walks one layer per press: move target → multi-select →
      // panel.
      if (_moving) {
        setState(() => _moving = false);
        return KeyEventResult.handled;
      }
      if (_multi) {
        _exitMulti();
        return KeyEventResult.handled;
      }
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
                    _multi
                        ? '${i18n('music_queue_multi_title')}（${_checked.length}/${queue.length}）'
                        : '${i18n('music_tab_queue')}（${queue.length}）',
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                if (!_multi) ...[
                  TvIconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: queue.isEmpty
                        ? null
                        : () => setState(() {
                              _multi = true;
                              _checked.clear();
                            }),
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: const Icon(Icons.playlist_remove_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: queue.isEmpty ? null : _confirmClear,
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: Icon(switch (state.mode) {
                      MusicPlayMode.sequence => Icons.repeat_rounded,
                      MusicPlayMode.loopOne => Icons.repeat_one_rounded,
                      MusicPlayMode.random => Icons.shuffle_rounded,
                      MusicPlayMode.orderStop => Icons.playlist_play_rounded,
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
                ] else ...[
                  TvIconButton(
                    icon: Icon(_moving ? Icons.done_all_rounded : Icons.select_all_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    selected: _moving,
                    onTap: _moving
                        ? _applyMove
                        : (_checked.isEmpty ? null : () => setState(() => _moving = true)),
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: const Icon(Icons.watch_later_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: _checked.isEmpty
                        ? null
                        : () {
                            controller.playLater(_checkedTracks(queue));
                            setState(_checked.clear);
                          },
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: _checked.isEmpty ? null : () => controller.removeIds(Set<String>.from(_checked)),
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: Icon(_checked.length >= queue.length && queue.isNotEmpty
                        ? Icons.deselect_rounded
                        : Icons.playlist_add_check_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: queue.isEmpty ? null : () => _toggleAllChecked(queue),
                  ),
                  SizedBox(width: 6.ts(context)),
                  TvIconButton(
                    icon: const Icon(Icons.close_rounded),
                    size: TvIconButtonSize.small,
                    isSecondary: true,
                    onTap: _exitMulti,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              // The Focus stays mounted across the empty transition: clearing
              // the queue (or removing its last row) otherwise unmounts the
              // node that owns every key, killing focus *and* the count==0
              // Left/escape-to-close handler with it.
              child: queue.isEmpty
                  ? Center(
                      child: Text(
                        i18n('music_queue_empty'),
                        style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
                      ),
                    )
                  : ListView.builder(
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
                          // Multi-select owns OK/long-press: a row menu popup
                          // mid-checking would drop the mode.
                          onLongPress: _multi ? null : () => _showRowMenu(index),
                          child: _QueueRow(
                            track: track,
                            index: index,
                            isCurrent: index == state.index,
                            selected: index == selected,
                            showCheck: _multi,
                            checked: _checked.contains(track.id),
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
                _moving
                    ? i18nOr('ui_queue_keys_move', '↑↓ 目标位置 · OK 移动 · ← 取消')
                    : _multi
                    ? i18nOr('ui_queue_keys_multi', '↑↓ 选择 · OK 勾选 · ← 退出多选')
                    : i18nOr('ui_panel_keys', '↑↓ 选择 · OK 播放 · ← 返回'),
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
