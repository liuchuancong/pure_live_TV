import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';


/// The 播放列表 over the player, bmsc's playlist sheet: a header with the
/// count, the clear button and the play-mode cycle, then one tall row per
/// track — the playing glyph or index, the title in accent while playing, the
/// album (multi-P) or artist beneath. Opens scrolled to the playing row; a
/// row's long press offers 屏蔽该分P and removal.
class MusicQueuePanel extends ConsumerStatefulWidget {
  const MusicQueuePanel({super.key,required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<MusicQueuePanel> createState() => MusicQueuePanelState();
}

class MusicQueuePanelState extends ConsumerState<MusicQueuePanel> {
  final ScrollController _scroll = ScrollController();
  final Map<int, FocusNode> _rowNodes = <int, FocusNode>{};
  bool _steered = false;

  FocusNode _nodeAt(int index) => _rowNodes.putIfAbsent(index, FocusNode.new);

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _rowNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Only the first build steers: rebuilds (progress ticks aside) must not
  /// drag the user back to the playing row.
  void _steerToCurrent(int index) {
    _steered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = (index * 106.0).sp - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      // The keyboard lands ON the playing row: this was the whole complaint —
      // opened, the panel used to leave focus nowhere and the remote dead.
      _nodeAt(index).requestFocus();
    });
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

  /// Long press on a row: 屏蔽该分P (the archive remembers the skip) or plain
  /// removal from the queue.
  Future<void> _showRowMenu(int index) async {
    final state = ref.read(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    final track = state.queue[index];
    final isMulti = track.archive.parts.length > 1;

    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: track.title,
        cancelText: i18n('cancel'),
        width: 560.sp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMulti)
              TvDialogOptionTile(
                title: i18n('music_queue_exclude'),
                subtitle: i18n('music_queue_exclude_hint'),
                icon: Icon(Icons.not_interested, size: 26.sp),
                showCheck: false,
                autofocus: true,
                onTap: () {
                  Navigator.of(context).pop();
                  libraryController.toggleExcludedPart(track.archive.bvid, track.part.cid);
                  controller.removeAt(index);
                  ToastUtil.show(i18n('music_part_excluded'));
                },
              ),
            TvDialogOptionTile(
              title: i18n('music_queue_remove'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.sp),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                controller.removeAt(index);
                ToastUtil.show(i18n('music_removed_from_queue'));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    final queue = state.queue;
    final playing = state.index;
    if (!_steered && playing >= 0 && queue.isNotEmpty) _steerToCurrent(playing);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.sp, 14.sp, 12.sp, 10.sp),
            child: Row(
              children: [
                SizedBox(width: 6.sp),
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
                SizedBox(width: 6.sp),
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
                SizedBox(width: 6.sp),
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
                : ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 16.sp),
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final track = queue[index];
                      final isCurrent = index == playing;
                      final isMulti = track.archive.parts.length > 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: 6.sp),
                        child: TvFocusable(
                          onTap: () => controller.jumpTo(index),
                          onLongPress: () => _showRowMenu(index),
                          focusNode: _nodeAt(index),
                          builder: (context, focused, child) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              // Content-sized: the fixed 100.sp overflowed by
                              // a pixel at the largest font setting.
                              padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 16.sp),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? accent.withValues(alpha: 0.22)
                                    : focused
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14.sp),
                                border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36.sp,
                                    child: isCurrent
                                        ? Icon(Icons.play_arrow_rounded, size: 30.sp, color: accent)
                                        : Text(
                                            '${index + 1}',
                                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
                                          ),
                                  ),
                                  SizedBox(width: 12.sp),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                track.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, 
                                                  color: isCurrent ? accent : Colors.white,
                                                ),
                                              ),
                                            ),
                                            if (isMulti)
                                              Padding(
                                                padding: EdgeInsets.only(left: 8.sp),
                                                child: Text(
                                                  'P${track.part.page}',
                                                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white38),
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 4.sp),
                                        Row(
                                          children: [
                                            Icon(Icons.album_rounded, size: 18.sp, color: Colors.white38),
                                            SizedBox(width: 4.sp),
                                            Expanded(
                                              child: Text(
                                                isMulti ? track.archive.title : track.archive.upName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

