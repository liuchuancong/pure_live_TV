import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/video_player_controller.dart';

class VideoPartsPanel extends ConsumerStatefulWidget {
  const VideoPartsPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<VideoPartsPanel> createState() => VideoPartsPanelState();
}

/// Opens with the keyboard ON the playing row, the music queue's recipe:
/// per-row nodes, one post-frame jump, one requestFocus — opened, the panel
/// used to leave focus nowhere and the remote dead.
class VideoPartsPanelState extends ConsumerState<VideoPartsPanel> {
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

  /// Only the first build steers; rebuilds must not drag focus back.
  void _steerToCurrent(int index) {
    _steered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Row stride: 64.ts(context) height + 8.ts(context) bottom margin.
      final target = (index * 72.0).sp - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      _nodeAt(index).requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoPlayerControllerProvider);
    final controller = ref.read(videoPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (!_steered && state.index >= 0 && state.queue.isNotEmpty) _steerToCurrent(state.index);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.ts(context)),
            child: Row(
              children: [
                Icon(Icons.playlist_play_rounded, size: 28.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    '${i18n('music_tracks_title')}（${state.queue.length}）',
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
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
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 16.sp),
              itemCount: state.queue.length,
              itemBuilder: (context, index) {
                final track = state.queue[index];
                final isCurrent = index == state.index;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.sp),
                  child: TvFocusable(
                    focusNode: _nodeAt(index),
                    onTap: () => controller.jumpTo(index),
                    builder: (context, focused, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: 64.ts(context),
                        padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
                        decoration: BoxDecoration(
                          color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12.ts(context)),
                          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32.ts(context),
                              child: isCurrent
                                  ? Icon(Icons.play_arrow_rounded, size: 26.ts(context), color: accent)
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyles.t16.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 10.ts(context)),
                            Expanded(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t16.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isCurrent ? accent : Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              MusicVideoCard.formatDuration(
                                track.part.duration > 0 ? track.part.duration : track.archive.duration,
                              ),
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
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
