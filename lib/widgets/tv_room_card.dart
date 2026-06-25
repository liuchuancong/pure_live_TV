import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/utils/text_util.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/widgets/tv_marqueer.dart';
import 'package:pure_live/widgets/app_status_view.dart';
import 'package:pure_live/widgets/tv_common_avatar.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvRoomCard extends StatelessWidget {
  const TvRoomCard({super.key, required this.room, required this.onLongPress, required this.onTap});

  final LiveRoom room;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.01,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.75),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = isFocused ? tvTheme.focusedCardColor : tvTheme.cardColor;
        final titleColor = isFocused ? tvTheme.backgroundColor : tvTheme.primaryTextColor;
        final subtitleColor = isFocused ? tvTheme.secondaryTextColor : tvTheme.secondaryTextColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.sp), color: tvTheme.cardColor),
                      child: Image.network(
                        room.cover,
                        fit: BoxFit.cover,
                        gaplessPlayback: false,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: tvTheme.cardColor,
                            child: AppStatusView(type: AppStatusType.loading, title: "", subtitle: "", isMini: true),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return AppStatusView(type: AppStatusType.error, title: "", subtitle: "", isMini: true);
                        },
                      ),
                    ),
                  ),
                  if (room.isRecord == true)
                    Positioned(
                      right: 12.sp,
                      top: 12.sp,
                      child: TvButton(
                        title: '重播',
                        excludeFocus: true,
                        size: TvButtonSize.mini,
                        icon: Icon(Icons.videocam_rounded, size: 20.sp),
                      ),
                    ),
                  if (room.isRecord == false && room.liveStatus == LiveStatus.live)
                    Positioned(
                      right: 12.sp,
                      bottom: 12.sp,
                      child: TvButton(
                        excludeFocus: true,
                        title: readableCount(room.watching),
                        size: TvButtonSize.mini,
                        icon: Icon(Icons.whatshot_rounded, size: 20.sp),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                child: Row(
                  children: [
                    TvCommonAvatar(avatarUrl: room.avatar, fallbackName: room.nick),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TvMarqueerText(
                            text: room.title,
                            isFocused: isFocused,
                            style: AppTextStyles.t22W700.copyWith(color: titleColor),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            room.nick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t18W500.copyWith(color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    TvButton(excludeFocus: true, title: room.platform.toUpperCase(), size: TvButtonSize.mini),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: false,
      effects: effects,
      onSelect: onTap,
      onLongSelect: onLongPress,
      onFocusChange: (focused) {
        if (!focused) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      },
      child: const SizedBox(),
    );
  }
}
