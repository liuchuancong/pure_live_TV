import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/services/cache/cache_controller.dart';
import 'package:pure_live/shared/utils/dpad_long_press_gate.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

class TvRoomCard extends ConsumerStatefulWidget {
  const TvRoomCard({
    super.key,
    required this.room,
    this.onLongPress,
    this.onTap,
    this.showFollowedMark = true,
    this.playlist = const <LiveRoom>[],
    this.index,
    this.fit = BoxFit.cover,
  });

  final LiveRoom room;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final BoxFit fit;

  /// Whether the followed badge is shown.
  final bool showFollowedMark;

  /// The room list this card came from. Without an [onTap] it travels with the
  /// player and becomes the channel list.
  final List<LiveRoom> playlist;

  /// The card's position in that list, which an IPTV card shows as its channel
  /// number. Null keeps the platform avatar.
  final int? index;

  @override
  ConsumerState<TvRoomCard> createState() => _TvRoomCardState();
}

class _TvRoomCardState extends ConsumerState<TvRoomCard> {
  late bool _followed;

  /// Keeps a long press from also being reported as a select — see
  /// [DpadLongPressGate].
  final DpadLongPressGate _longPressGate = DpadLongPressGate();

  @override
  void initState() {
    super.initState();
    _followed = SettingsService.to.fav.isFavorite(widget.room);
  }

  /// Cover cache key for the current cache epoch.
  ///
  /// refresh live thumbnails clears the encoded-image cache and bumps the epoch; folding
  /// it into the key makes the visible covers reload instead of keeping
  /// the bitmaps they already decoded.
  String get coverCacheKey {
    final int epoch = ref.watch(cacheControllerProvider.select((m) => m.imageCacheEpoch));
    return epoch == 0 ? widget.room.cover : '${widget.room.cover}#$epoch';
  }

  /// Audience text for the card: the concurrent online count when the user
  /// prefers it and this platform really publishes it, otherwise the platform's
  /// native heat, cumulative or legacy value.
  String get _audienceText {
    // Narrow selects: watching the whole models rebuilt every mounted card
    // whenever any unrelated setting (cache scan, any toggle) changed.
    final preferRealOnline = ref.watch(appSettingsControllerProvider.select((s) => s.preferRealOnlineCounts));
    ref.watch(appSettingsControllerProvider.select((s) => s.realOnlinePlatforms));
    final value = widget.room.audienceValue(
      preferRealOnline: preferRealOnline,
      platformEnabled: ref.read(appSettingsControllerProvider.notifier).isRealOnlineEnabledFor(widget.room.platform),
    );
    return readableCount(value);
  }

  /// Without an [onTap] the card opens the live player and passes the list along
  /// as the channel list.
  void _openLivePlay() {
    if (!mounted) return;
    LivePlayRoute(LivePlayArgs.fromRoom(widget.room, playlist: widget.playlist)).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);
    // Evaluated once per build, outside the effects closure, so the effect
    // never watches settings while a descendant is building.
    final String audience = _audienceText;

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.01,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      // Light palette: the 18px glow is a grey smear on white; crisp ring.
      tvTheme.isLight
          ? DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 2.sp, blurRadius: 0)
          : DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.75, blurRadius: 18.sp, spreadRadius: 1.5.sp),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = isFocused ? tvTheme.focusedCardColor : tvTheme.cardColor;
        // Contrast with the card that is actually behind the text. The previous
        // rule (`focused ? backgroundColor : primaryTextColor`) worked only while
        // every focused card was white; on a light palette `backgroundColor` is
        // near-white, so a focused card showed near-white text on white.
        final titleColor = isFocused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor;
        final subtitleColor = isFocused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Dense layouts hand the card a much narrower cell; below this
              // width the info row runs in its compact form so it still fits
              // the height the grid allots.
              final bool compact = constraints.maxWidth < 190.sp;
              // A playlist ships no per-channel avatar, so an IPTV card numbers
              // its channel instead: a position is what a TV viewer reads as the
              // channel identity, while the shared placeholder would repeat one
              // dead grey circle across every card of the list.
              final int? channelNumber = widget.room.platform == Sites.iptvSite && widget.index != null
                  ? widget.index! + 1
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.sp),
                            color: tvTheme.cardColor,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.room.cover,
                            cacheManager: CustomImageCacheManager.instance,
                            // Rolling the cache epoch (cache & data → refresh live thumbnails)
                            // re-keys the covers, so the refresh is visible instead of
                            // only freeing disk space.
                            cacheKey: coverCacheKey,
                            fit: widget.room.platform == Sites.iptvSite ? BoxFit.contain : widget.fit,
                            // Decode covers at grid size and reuse the shared disk
                            // cache so scrolling back does not download again.
                            memCacheWidth: 640,
                            placeholder: (context, url) => Container(
                              color: tvTheme.cardColor,
                              child: AppStatusView(type: AppStatusType.loading, title: "", subtitle: "", isMini: true),
                            ),
                            errorWidget: (context, url, error) {
                              debugPrint(error.toString());
                              return AppStatusView(type: AppStatusType.error, title: "", subtitle: "", isMini: true);
                            },
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
                      if (widget.room.isRecord == false &&
                          widget.room.liveStatus == LiveStatus.live &&
                          audience.isNotEmpty)
                        Positioned(
                          right: 12.sp,
                          bottom: 12.sp,
                          child: TvButton(
                            excludeFocus: true,
                            title: audience,
                            size: TvButtonSize.mini,
                            icon: Icon(Icons.whatshot_rounded, size: 20.sp),
                          ),
                        ),
                    ],
                  ),
                  // The info row takes whatever height the cover leaves: it can
                  // never overflow the cell, and the dense aspect ratios keep this
                  // area tall enough for its contents.
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 10.sp,
                        top: compact ? 6.sp : 16.sp,
                        right: compact ? 10.sp : 16.sp,
                      ),
                      child: Row(
                        children: [
                          // The leading keeps the avatar's footprint either way,
                          // so titles stay aligned in a grid that mixes platforms.
                          SizedBox(
                            width: compact ? 20.sp : 56.sp,
                            child: Center(
                              child: channelNumber == null
                                  ? TvCommonAvatar(
                                      avatarUrl: widget.room.avatar,
                                      fallbackName: widget.room.nick,
                                      radius: compact ? 10.sp : null,
                                    )
                                  : NumberLeading(channelNumber, size: (compact ? 20 : 34).sp, color: titleColor),
                            ),
                          ),
                          SizedBox(width: compact ? 8.sp : 16.sp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dense cells are short, so compact runs one
                                // step smaller on both lines. The title keeps
                                // its natural height (its focused marquee needs
                                // it) and the nick is the flexible one: when
                                // the cell cannot fit both lines the nick
                                // compresses first instead of overflowing.
                                TvMarqueeText(
                                  text: widget.room.title,
                                  isFocused: isFocused,
                                  style: (compact ? AppTextStyles.t14W700 : AppTextStyles.t22W700).copyWith(
                                    color: titleColor,
                                  ),
                                ),
                                SizedBox(height: compact ? 2.sp : 4.sp),
                                Flexible(
                                  child: Text(
                                    widget.room.nick,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: (compact ? AppTextStyles.t14W500 : AppTextStyles.t18W500).copyWith(
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // The platform chip is the first casualty of a narrow
                          // card: the title keeps its space instead.
                          if (!compact) ...[
                            SizedBox(width: 12.sp),
                            TvButton(
                              excludeFocus: true,
                              title: widget.room.platform.toUpperCase(),
                              size: TvButtonSize.mini,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: false,
      effects: effects,
      // `DpadFocusable` already reveals the focused card through
      // `DpadScroll.ensureVisible` (padded, and it walks every scrollable
      // ancestor). The extra `Scrollable.ensureVisible` here animated to a
      // second, different offset and made the grid jitter while moving.
      onSelect: () {
        final isLocked = SettingsService.to.container?.read(tvDialogLockProvider) ?? false;
        if (isLocked) return;
        // The long press owns this press; its release must not open the room.
        if (_longPressGate.swallowSelect()) return;
        final onTap = widget.onTap;
        if (onTap != null) {
          onTap();
          return;
        }
        _openLivePlay();
      },
      // Without a long-press action the hook stays null on purpose: with one, the
      // d-pad layer holds select back until the key is released (and drops it
      // entirely once the hold passes the threshold), so a card that has nothing to
      // show on a hold would swallow the press instead of opening the room.
      onLongSelect: widget.onLongPress == null
          ? null
          : () {
              final isLocked = SettingsService.to.container?.read(tvDialogLockProvider) ?? false;
              if (isLocked) return;
              _longPressGate.markLongPress();
              widget.onLongPress!.call();
            },
      child: const SizedBox(),
    );
  }
}
