import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/danmaku/danmaku_list_view.dart';
import 'package:pure_live/features/live_play/widgets/video_player/tv_video_surface.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/widgets/tv_common_avatar.dart';

/// Landscape live playback page.
///
/// Left: video surface ([TvVideoSurface]); pressing OK on the D-pad opens the
/// control panel. Right: room info, quality/line switching and the danmaku list.
class LivePlayPage extends ConsumerWidget {
  final LivePlayArgs args;

  const LivePlayPage({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livePlayControllerProvider(args));
    final controller = ref.read(livePlayControllerProvider(args).notifier);
    final tvTheme = context.tvTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: DpadRegion(
                memoryKey: 'live_play/video',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TvVideoSurface(args: args),
                    // 面板收起时提供 D-pad 可达的展开入口。
                    if (!state.showSidePanel)
                      Positioned(
                        right: 16.sp,
                        bottom: 16.sp,
                        child: DpadFocusable(
                          effects: [
                            DpadScaleEffect(scale: 1.05),
                            DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                          ],
                          onSelect: controller.toggleSidePanel,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 8.sp),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8.sp),
                              border: Border.all(color: tvTheme.secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '展开面板',
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.showSidePanel)
              Container(
                width: 360.sp,
                color: tvTheme.backgroundColor,
                child: DpadRegion(
                  memoryKey: 'live_play/side-panel',
                  child: _SidePanel(
                    state: state,
                    controller: controller,
                    args: args,
                    onTogglePanel: controller.toggleSidePanel,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidePanel extends ConsumerWidget {
  final LivePlayState state;
  final LivePlayController controller;
  final LivePlayArgs args;
  final VoidCallback onTogglePanel;

  const _SidePanel({
    required this.state,
    required this.controller,
    required this.args,
    required this.onTogglePanel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final room = state.room;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 房间信息头部
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          child: Row(
            children: [
              TvCommonAvatar(avatarUrl: room?.avatar, radius: 24.sp, fallbackName: room?.nick),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room?.nick ?? (state.detailError ?? '加载中...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      _audienceLine(room),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          child: Text(
            room?.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
        SizedBox(height: 12.sp),
        Divider(height: 1, color: tvTheme.secondaryTextColor.withValues(alpha: 0.2)),
        SizedBox(height: 8.sp),
        _SectionLabel(text: '清晰度'),
        _ChipRow(
          labels: state.qualities.map((q) => q.quality).toList(growable: false),
          selectedIndex: state.qualityIndex,
          onSelect: controller.changeQuality,
        ),
        SizedBox(height: 8.sp),
        _SectionLabel(text: '线路'),
        _ChipRow(
          labels: [for (var i = 0; i < state.playUrls.length; i++) '线路${i + 1}'],
          selectedIndex: state.lineIndex,
          onSelect: controller.changeLine,
        ),
        SizedBox(height: 8.sp),
        Divider(height: 1, color: tvTheme.secondaryTextColor.withValues(alpha: 0.2)),
        Expanded(
          child: state.playUrls.isEmpty
              ? const SizedBox.shrink()
              : DanmakuListView(args: args),
        ),
        // 面板折叠按钮，保持 D-pad 有明确的返回视频区路径。
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
          child: DpadFocusable(
            effects: [
              DpadScaleEffect(scale: 1.03),
              DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.4)),
            ],
            onSelect: onTogglePanel,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 8.sp),
              decoration: BoxDecoration(
                color: tvTheme.cardColor,
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Text('收起面板', style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor)),
            ),
          ),
        ),
      ],
    );
  }

  String _audienceLine(LiveRoom? room) {
    if (room == null) return '';
    final watching = room.watching;
    final followers = room.followers;
    final parts = <String>[
      if (watching.isNotEmpty) '人气 $watching',
      if (followers.isNotEmpty) '粉丝 $followers',
    ];
    return parts.join(' · ');
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      child: Text(text, style: AppTextStyles.t14W600.copyWith(color: tvTheme.secondaryTextColor)),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ChipRow({required this.labels, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    if (labels.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
        child: Text('暂无', style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor)),
      );
    }
    return SizedBox(
      height: 48.sp,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        itemCount: labels.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.sp),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return DpadFocusable(
            effects: [
              DpadScaleEffect(scale: 1.05),
              DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
            ],
            onSelect: () => onSelect(index),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 14.sp),
              decoration: BoxDecoration(
                color: selected ? tvTheme.focusColor.withValues(alpha: 0.25) : tvTheme.cardColor,
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(
                  color: selected ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14W500.copyWith(color: selected ? tvTheme.focusColor : tvTheme.primaryTextColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
