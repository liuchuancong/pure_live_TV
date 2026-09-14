import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/settings/settings.dart';

class TvRoomCard extends ConsumerStatefulWidget {
  const TvRoomCard({super.key, required this.room, this.onLongPress, this.onTap, this.showFollowedMark = true});

  final LiveRoom room;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  /// Whether the followed badge is shown.
  final bool showFollowedMark;

  @override
  ConsumerState<TvRoomCard> createState() => _TvRoomCardState();
}

class _TvRoomCardState extends ConsumerState<TvRoomCard> {
  late bool _followed;

  @override
  void initState() {
    super.initState();
    _followed = SettingsService.to.fav.isFavorite(widget.room);
  }

  /// Audience text for the card: the concurrent online count when the user
  /// prefers it and this platform really publishes it, otherwise the platform's
  /// native heat, cumulative or legacy value.
  String get _audienceText {
    final settings = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final value = widget.room.audienceValue(
      preferRealOnline: settings.preferRealOnlineCounts,
      platformEnabled: app.isRealOnlineEnabledFor(widget.room.platform),
    );
    return readableCount(value);
  }

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
      DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.75, blurRadius: 18.sp, spreadRadius: 1.5.sp),
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
                      child: CachedNetworkImage(
                        imageUrl: widget.room.cover,
                        cacheManager: CustomImageCacheManager.instance,
                        fit: BoxFit.cover,
                        // Decode covers at grid size and reuse the shared disk
                        // cache so scrolling back does not download again.
                        memCacheWidth: 640,
                        maxWidthDiskCache: 1280,
                        placeholder: (context, url) => Container(
                          color: tvTheme.cardColor,
                          child: AppStatusView(type: AppStatusType.loading, title: "", subtitle: "", isMini: true),
                        ),
                        errorWidget: (context, url, error) =>
                            AppStatusView(type: AppStatusType.error, title: "", subtitle: "", isMini: true),
                      ),
                    ),
                  ),

                  if (widget.showFollowedMark && _followed)
                    Positioned(
                      left: 12.sp,
                      top: 12.sp,
                      child: TvButton(
                        excludeFocus: true,
                        title: i18n('followed'),
                        size: TvButtonSize.mini,
                        icon: Icon(Icons.favorite, size: 18.sp),
                      ),
                    ),

                  if (widget.room.isRecord == true)
                    Positioned(
                      right: 12.sp,
                      top: 12.sp,
                      child: TvButton(
                        title: i18n('ui_replay'),
                        excludeFocus: true,
                        size: TvButtonSize.mini,
                        icon: Icon(Icons.videocam_rounded, size: 20.sp),
                      ),
                    ),
                  if (widget.room.isRecord == false && widget.room.liveStatus == LiveStatus.live)
                    Positioned(
                      right: 12.sp,
                      bottom: 12.sp,
                      child: TvButton(
                        excludeFocus: true,
                        title: _audienceText,
                        size: TvButtonSize.mini,
                        icon: Icon(Icons.whatshot_rounded, size: 20.sp),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(left: 10.sp, top: 16.sp, right: 16.sp),
                child: Row(
                  children: [
                    TvCommonAvatar(avatarUrl: widget.room.avatar, fallbackName: widget.room.nick),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TvMarqueeText(
                            text: widget.room.title,
                            isFocused: isFocused,
                            style: AppTextStyles.t22W700.copyWith(color: titleColor),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            widget.room.nick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t18W500.copyWith(color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    TvButton(excludeFocus: true, title: widget.room.platform.toUpperCase(), size: TvButtonSize.mini),
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
      onFocusChange: (focused) {
        if (!focused) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      },
      onSelect: () {
        final isLocked = SettingsService.to.container?.read(tvDialogLockProvider) ?? false;
        if (isLocked) return;
        widget.onTap?.call();
      },
      onLongSelect: () {
        final isLocked = SettingsService.to.container?.read(tvDialogLockProvider) ?? false;
        if (isLocked) return;
        widget.onLongPress?.call();
      },
      child: const SizedBox(),
    );
  }
}
